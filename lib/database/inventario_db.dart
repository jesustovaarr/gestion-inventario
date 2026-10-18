import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class InventarioDB {
  static const String nameDB = "alacena_inventario.db";
  static const int versionDB = 11;
  static Database? _database;
  static Future<Database>? _apertura;
  static Future<void>? _esquemaListo;
  static int _versionEsquemaComprobada = 0;
  static InventarioDB? _instance;

  InventarioDB._internal();

  factory InventarioDB() {
    _instance ??= InventarioDB._internal();
    return _instance!;
  }

  // Permite inyectar base de datos de prueba
  InventarioDB.conDatabase(Database db, {bool verificarEsquema = false}) {
    _database = db;
    _apertura = null;
    _esquemaListo = verificarEsquema ? null : Future.value();
    _versionEsquemaComprobada = verificarEsquema ? 0 : versionDB;
  }

  Future<Database> get database async {
    if (_database == null || !_database!.isOpen) {
      _apertura ??= _initDatabase();
      try {
        _database = await _apertura!;
      } catch (_) {
        _apertura = null;
        rethrow;
      }
    }
    final db = _database!;
    // También revalida la conexión conservada si cambia el esquema en un hot reload.
    if (_versionEsquemaComprobada != versionDB) {
      _esquemaListo = null;
      _versionEsquemaComprobada = versionDB;
    }
    _esquemaListo ??= db.transaction((txn) => asegurarEsquema(txn));
    try {
      await _esquemaListo;
    } catch (_) {
      _esquemaListo = null;
      rethrow;
    }
    return db;
  }

  /// Repara bases antiguas según sus columnas reales, sin borrar datos.
  static Future<void> asegurarEsquema(DatabaseExecutor db) async {
    final producto = await db.rawQuery('PRAGMA table_info(Producto)');
    final columnas = producto.map((c) => c['name']).toSet();
    if (!columnas.contains('precio')) {
      await db.execute(
        'ALTER TABLE Producto ADD COLUMN precio REAL CHECK(precio >= 0)',
      );
    }
    if (!columnas.contains('zona_almacenamiento')) {
      await db.execute(
        'ALTER TABLE Producto ADD COLUMN zona_almacenamiento TEXT',
      );
    }
    final lote = await db.rawQuery('PRAGMA table_info(Lote)');
    if (!lote.any((c) => c['name'] == 'hora_aviso')) {
      await db.execute(
        "ALTER TABLE Lote ADD COLUMN hora_aviso TEXT NOT NULL DEFAULT '09:00 AM'",
      );
    }
    await _createCompras(db);
    final historial = await db.rawQuery('PRAGMA table_info(Historial_Compras)');
    if (!historial.any((c) => c['name'] == 'compra_id')) {
      await db.execute(
        'ALTER TABLE Historial_Compras ADD COLUMN compra_id INTEGER REFERENCES Compra(id) ON DELETE CASCADE',
      );
    }
    if (!historial.any((c) => c['name'] == 'lote_id')) {
      await db.execute(
        'ALTER TABLE Historial_Compras ADD COLUMN lote_id INTEGER REFERENCES Lote(id) ON DELETE SET NULL',
      );
    }
    await _asegurarPresentaciones(db);
    await _asegurarPresentacionesLotes(db);
    await _createMovimientos(db);
    final movimientos = await db.rawQuery(
      'PRAGMA table_info(Movimiento_Inventario)',
    );
    if (!movimientos.any((c) => c['name'] == 'cantidad_descartada')) {
      await db.execute(
        'ALTER TABLE Movimiento_Inventario RENAME TO Movimiento_Inventario_anterior',
      );
      await _createMovimientos(db);
      // Mantener los importes de desechos anteriores como información del evento,
      // separados de la cantidad editable que solo existe en los consumos.
      await db.execute('''INSERT INTO Movimiento_Inventario
        (id, producto_id, lote_id, tipo, cantidad, cantidad_descartada, fecha)
        SELECT id, producto_id, lote_id, tipo,
          CASE WHEN tipo = 'consumo' THEN cantidad ELSE NULL END,
          CASE WHEN tipo = 'desecho' THEN cantidad ELSE NULL END, fecha
        FROM Movimiento_Inventario_anterior''');
      await db.execute('DROP TABLE Movimiento_Inventario_anterior');
    }
  }

  Future<Database> _initDatabase() async {
    Directory folder = await getApplicationDocumentsDirectory();
    String pathDB = join(folder.path, nameDB);
    return await openDatabase(
      pathDB,
      version: versionDB,
      onConfigure: _onConfigure,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  // Habilitar llaves foraneas
  static FutureOr<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  static Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await asegurarEsquema(db);
    if (oldVersion < 11) {
      await migrarProductosIndependientes(db);
      await _carritoUnProductoPorRenglon(db);
    }
    if (oldVersion < 4) {
      await db.execute('UPDATE Lote SET cantidad = ROUND(cantidad, 3)');
      await db.execute('UPDATE Lote SET alarma_activa = 0 WHERE cantidad = 0');
    }
  }

  static Future<void> _createCompras(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS Compra (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tienda_id INTEGER NOT NULL,
      fecha_compra TEXT NOT NULL,
      total_centavos INTEGER NOT NULL CHECK(total_centavos >= 0),
      FOREIGN KEY (tienda_id) REFERENCES Tienda(id) ON DELETE RESTRICT
    )''');
  }

  static Future<void> _asegurarPresentaciones(DatabaseExecutor db) async {
    const presentacion = "TEXT NOT NULL DEFAULT 'granel'";
    const contenido = 'REAL NOT NULL DEFAULT 1 CHECK(contenido_envase > 0)';
    const numero = 'INTEGER NOT NULL DEFAULT 1 CHECK(numero_envases > 0)';
    const precio = 'INTEGER CHECK(precio_envase_centavos >= 0)';
    final cambios = {
      'Producto': {
        'codigo': 'TEXT',
        'presentacion': presentacion,
        'contenido_envase': contenido,
      },
      'Carrito': {
        'presentacion': presentacion,
        'contenido_envase': contenido,
        'numero_envases': numero,
        'precio_envase_centavos': precio,
        'fecha_caducidad': 'TEXT',
      },
      'Historial_Compras': {
        'presentacion': presentacion,
        'contenido_envase': contenido,
        'numero_envases': numero,
        'precio_envase_centavos': precio,
      },
    };
    for (final tabla in cambios.entries) {
      final columnas = (await db.rawQuery('PRAGMA table_info(${tabla.key})'))
          .map((r) => r['name'])
          .toSet();
      for (final columna in tabla.value.entries) {
        if (!columnas.contains(columna.key)) {
          await db.execute(
            'ALTER TABLE ${tabla.key} ADD COLUMN ${columna.key} ${columna.value}',
          );
        }
      }
    }
    await db.execute(
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_producto_codigo ON Producto(codigo) WHERE codigo IS NOT NULL AND codigo <> ''",
    );
  }

  static Future<void> _createMovimientos(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS Movimiento_Inventario (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      producto_id INTEGER NOT NULL,
      lote_id INTEGER NOT NULL,
      tipo TEXT NOT NULL CHECK(tipo IN ('consumo', 'desecho')),
      cantidad REAL,
      cantidad_descartada REAL CHECK(cantidad_descartada IS NULL OR cantidad_descartada > 0),
      fecha TEXT NOT NULL,
      CHECK((tipo = 'consumo' AND cantidad IS NOT NULL AND cantidad > 0)
        OR (tipo = 'desecho' AND cantidad IS NULL)),
      FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE,
      FOREIGN KEY (lote_id) REFERENCES Lote(id) ON DELETE CASCADE
    )''');
  }

  static Future<void> _asegurarPresentacionesLotes(DatabaseExecutor db) async {
    final columnas = (await db.rawQuery('PRAGMA table_info(Lote)'))
        .map((r) => r['name'])
        .toSet();
    final migrar = !columnas.contains('presentacion');
    if (migrar) {
      await db.execute(
        "ALTER TABLE Lote ADD COLUMN presentacion TEXT NOT NULL DEFAULT 'granel'",
      );
    }
    if (!columnas.contains('contenido_envase')) {
      await db.execute(
        'ALTER TABLE Lote ADD COLUMN contenido_envase REAL NOT NULL DEFAULT 1 CHECK(contenido_envase > 0)',
      );
    }
    if (migrar) {
      // Recuperar solo presentaciones documentadas en una compra de ese lote;
      // la presentación más reciente del catálogo puede ser de otro tamaño.
      await db.execute(
        '''UPDATE Lote SET
        presentacion = (SELECT h.presentacion FROM Historial_Compras h WHERE h.lote_id = Lote.id ORDER BY h.id DESC LIMIT 1),
        contenido_envase = (SELECT h.contenido_envase FROM Historial_Compras h WHERE h.lote_id = Lote.id ORDER BY h.id DESC LIMIT 1)
        WHERE EXISTS (SELECT 1 FROM Historial_Compras h WHERE h.lote_id = Lote.id AND h.presentacion <> 'granel')''',
      );
    }
  }

  /// Una sola vez al actualizar: cada tamaño anterior recibe un producto independiente.
  static Future<void> migrarProductosIndependientes(DatabaseExecutor db) async {
    String formato(Map<String, Object?> row) =>
        '${row['presentacion'] ?? 'granel'}:${((row['contenido_envase'] as num?) ?? 1).toStringAsFixed(3)}';
    for (final producto in await db.query('Producto')) {
      final id = producto['id'] as int;
      final lotes = await db.query(
        'Lote',
        where: 'producto_id = ?',
        whereArgs: [id],
      );
      final historial = await db.query(
        'Historial_Compras',
        where: 'producto_id = ?',
        whereArgs: [id],
        orderBy: 'fecha_compra DESC, id DESC',
      );
      final carrito = await db.query(
        'Carrito',
        where: 'producto_id = ?',
        whereArgs: [id],
      );
      final formatos = {formato(producto): producto};
      for (final row in [...lotes, ...historial, ...carrito]) {
        formatos.putIfAbsent(formato(row), () => row);
      }
      final ids = {formato(producto): id};
      for (final entry in formatos.entries) {
        if (ids.containsKey(entry.key)) continue;
        final compras = historial
            .where((h) => formato(h) == entry.key)
            .toList();
        final datos = Map<String, Object?>.from(producto)..remove('id');
        datos.addAll({
          'codigo': null,
          'presentacion': entry.value['presentacion'] ?? 'granel',
          'contenido_envase': entry.value['contenido_envase'] ?? 1,
          if (compras.isNotEmpty) 'precio': compras.first['precio_unitario'],
          if (compras.isNotEmpty)
            'ultima_tienda_id': compras.first['tienda_id'],
        });
        ids[entry.key] = await db.insert('Producto', datos);
      }
      for (final lote in lotes) {
        final destino = ids[formato(lote)]!;
        await db.update(
          'Lote',
          {'producto_id': destino},
          where: 'id = ?',
          whereArgs: [lote['id']],
        );
        await db.update(
          'Movimiento_Inventario',
          {'producto_id': destino},
          where: 'lote_id = ?',
          whereArgs: [lote['id']],
        );
      }
      for (final tabla in ['Historial_Compras', 'Carrito']) {
        for (final row in tabla == 'Carrito' ? carrito : historial) {
          await db.update(
            tabla,
            {'producto_id': ids[formato(row)]!},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }
    }
  }

  static Future<void> _carritoUnProductoPorRenglon(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE Carrito_simple (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      producto_id INTEGER NOT NULL UNIQUE REFERENCES Producto(id) ON DELETE CASCADE,
      cantidad_a_comprar REAL NOT NULL DEFAULT 1 CHECK(cantidad_a_comprar > 0),
      presentacion TEXT NOT NULL DEFAULT 'granel',
      numero_envases INTEGER NOT NULL DEFAULT 1 CHECK(numero_envases > 0),
      contenido_envase REAL NOT NULL DEFAULT 1 CHECK(contenido_envase > 0),
      precio_envase_centavos INTEGER CHECK(precio_envase_centavos >= 0),
      fecha_caducidad TEXT
    )''');
    await db.execute(
      '''INSERT INTO Carrito_simple
      (id, producto_id, cantidad_a_comprar, presentacion, numero_envases, contenido_envase, precio_envase_centavos, fecha_caducidad)
      SELECT id, producto_id, cantidad_a_comprar, presentacion, numero_envases, contenido_envase, precio_envase_centavos, fecha_caducidad FROM Carrito''',
    );
    await db.execute('DROP TABLE Carrito');
    await db.execute('ALTER TABLE Carrito_simple RENAME TO Carrito');
  }

  // Tablas
  static FutureOr<void> _createTables(Database db, int version) async {
    // CATEGORIA
    await db.execute('''
      CREATE TABLE Categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      );
    ''');

    // TIPO DE TIENDA
    await db.execute('''
      CREATE TABLE Tipo_Tienda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      );
    ''');

    // TIENDA
    await db.execute('''
      CREATE TABLE Tienda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        ubicacion TEXT,
        tipo_tienda_id INTEGER NOT NULL,
        FOREIGN KEY (tipo_tienda_id) REFERENCES Tipo_Tienda(id) ON DELETE RESTRICT
      );
    ''');

    // PRODUCTO
    await db.execute('''
      CREATE TABLE Producto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        precio REAL CHECK(precio >= 0),
        imagen TEXT NOT NULL DEFAULT '',
        zona_almacenamiento TEXT,
        unidad_medida TEXT NOT NULL DEFAULT 'pza' CHECK(unidad_medida IN ('pza', 'kg', 'lt', 'g', 'ml')),
        stock_minimo REAL NOT NULL CHECK(stock_minimo > 0),
        categoria_id INTEGER NOT NULL,
        ultima_tienda_id INTEGER, 
        FOREIGN KEY (categoria_id) REFERENCES Categoria(id) ON DELETE RESTRICT,
        FOREIGN KEY (ultima_tienda_id) REFERENCES Tienda(id) ON DELETE SET NULL
      );
    ''');

    // LOTE
    await db.execute('''
      CREATE TABLE Lote (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        cantidad REAL NOT NULL CHECK(cantidad >= 0),
        fecha_caducidad TEXT NOT NULL CHECK(length(fecha_caducidad) == 10 AND fecha_caducidad GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
        alarma_id INTEGER,
        hora_aviso TEXT NOT NULL DEFAULT '09:00 AM',
        alarma_activa INTEGER NOT NULL DEFAULT 1 CHECK(alarma_activa IN (0, 1)),
        FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE
      );
    ''');

    await _createCompras(db);

    // HISTORIAL DE COMPRAS
    await db.execute('''
      CREATE TABLE Historial_Compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compra_id INTEGER REFERENCES Compra(id) ON DELETE CASCADE,
        lote_id INTEGER REFERENCES Lote(id) ON DELETE SET NULL,
        producto_id INTEGER NOT NULL,
        tienda_id INTEGER NOT NULL,
        fecha_compra TEXT NOT NULL CHECK(length(fecha_compra) == 10 AND fecha_compra GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
        cantidad REAL NOT NULL CHECK(cantidad > 0),
        precio_unitario REAL CHECK(precio_unitario >= 0),
        FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE,
        FOREIGN KEY (tienda_id) REFERENCES Tienda(id) ON DELETE RESTRICT
      );
    ''');

    // CARRITO
    await db.execute('''
      CREATE TABLE Carrito (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL UNIQUE,
        cantidad_a_comprar REAL NOT NULL DEFAULT 1 CHECK(cantidad_a_comprar > 0),
        FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE
      );
    ''');

    await _createMovimientos(db);
    await _asegurarPresentaciones(db);
    await _asegurarPresentacionesLotes(db);
    await _insertInitialData(db);
  }

  // Datos de prueba
  static Future<void> _insertInitialData(Database db) async {
    final categorias = [
      'Lácteos',
      'Abarrotes',
      'Frutas y Verduras',
      'Carnes y Pescados',
      'Bebidas',
      'Limpieza e Higiene',
    ];
    for (var cat in categorias) {
      await db.insert('Categoria', {'nombre': cat});
    }

    final tiposTiendas = [
      'Supermercado',
      'Mercado local',
      'Tiendita de la esquina',
      'Club de precios',
    ];
    for (var tipo in tiposTiendas) {
      await db.insert('Tipo_Tienda', {'nombre': tipo});
    }
  }

  // Cierra la conexion
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _apertura = null;
      _esquemaListo = null;
      _versionEsquemaComprobada = 0;
    }
  }
}
