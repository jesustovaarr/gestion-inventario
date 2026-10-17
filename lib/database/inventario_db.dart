import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class InventarioDB {
  static const String nameDB = "alacena_inventario.db";
  static const int versionDB = 1;
  static Database? _database;
  static InventarioDB? _instance;

  InventarioDB._internal();

  factory InventarioDB() {
    _instance ??= InventarioDB._internal();
    return _instance!;
  }

  // Permite inyectar base de datos de prueba
  InventarioDB.conDatabase(Database db) {
    _database = db;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory folder = await getApplicationDocumentsDirectory();
    String pathDB = join(folder.path, nameDB);
    return await openDatabase(
      pathDB,
      version: versionDB,
      onConfigure: _onConfigure,
      onCreate: _createTables,
    );
  }

  // Habilitar llaves foraneas
  static FutureOr<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
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
        imagen TEXT NOT NULL DEFAULT '',
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
        alarma_activa INTEGER NOT NULL DEFAULT 1 CHECK(alarma_activa IN (0, 1)),
        FOREIGN KEY (producto_id) REFERENCES Producto(id) ON DELETE CASCADE
      );
    ''');

    // HISTORIAL DE COMPRAS
    await db.execute('''
      CREATE TABLE Historial_Compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    }
  }
}
