import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_inventario/database/inventario_db.dart';
import 'package:gestion_inventario/models/categoria_model.dart';
import 'package:gestion_inventario/models/tipo_tienda_model.dart';
import 'package:gestion_inventario/models/tienda_model.dart';
import 'package:gestion_inventario/models/producto_model.dart';
import 'package:gestion_inventario/models/lote_model.dart';
import 'package:gestion_inventario/models/historial_compra_model.dart';
import 'package:gestion_inventario/models/carrito_model.dart';
import 'package:gestion_inventario/database/daos/categoria_dao.dart';
import 'package:gestion_inventario/database/daos/tipo_tienda_dao.dart';
import 'package:gestion_inventario/database/daos/tienda_dao.dart';
import 'package:gestion_inventario/database/daos/producto_dao.dart';
import 'package:gestion_inventario/database/daos/lote_dao.dart';
import 'package:gestion_inventario/database/daos/compra_dao.dart';
import 'package:gestion_inventario/database/daos/carrito_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Modelos y Lógica del Plan de Inventario', () {
    test('InventarioDB define nombre y versión correctos', () {
      expect(InventarioDB.nameDB, 'alacena_inventario.db');
      expect(InventarioDB.versionDB, 11);
    });

    test('Carrito lee cantidades numéricas de la base de datos', () {
      expect(
        CarritoItem.fromMap({'producto_id': 1, 'cantidad_a_comprar': 2.5})
            .cantidadAComprar,
        2.5,
      );
      expect(
        CarritoItem.fromMap({'producto_id': 1, 'cantidad_comprar': 2})
            .cantidadAComprar,
        2.0,
      );
    });

    test('Precio admite enteros, decimales y productos sin precio', () {
      for (final valor in <num>[25, 25.50, 0]) {
        final producto = Producto.fromMap({
          'nombre': 'Leche',
          'stock_minimo': 2,
          'categoria_id': 1,
          'precio': valor,
        });
        expect(producto.precio, valor.toDouble());
        expect(Producto.fromMap(producto.toMap()).precio, valor.toDouble());
        expect(
          producto.copyWith(nombre: 'Leche editada').precio,
          valor.toDouble(),
        );
      }
      final sinPrecio = Producto.fromMap({'nombre': 'Anterior'});
      expect(sinPrecio.precio, isNull);
      expect(sinPrecio.toMap()['precio'], isNull);
    });

    test('Categoria serializa y deserializa correctamente', () {
      const cat = Categoria(id: 1, nombre: 'Lácteos');
      final map = cat.toMap();
      expect(map['nombre'], 'Lácteos');
      expect(map['id'], 1);

      final desdeMap = Categoria.fromMap(map);
      expect(desdeMap.id, 1);
      expect(desdeMap.nombre, 'Lácteos');
    });

    test('TipoTienda serializa y deserializa correctamente', () {
      final tipo = const TipoTienda(id: 1, nombre: 'Supermercado');
      final map = tipo.toMap();
      expect(map['nombre'], 'Supermercado');
      expect(map['id'], 1);

      final desdeMap = TipoTienda.fromMap(map);
      expect(desdeMap.id, 1);
      expect(desdeMap.nombre, 'Supermercado');
    });

    test('Tienda contiene tipo_tienda_id y totalCompras', () {
      final tienda = const Tienda(
        id: 2,
        nombre: 'Soriana',
        ubicacion: 'Plaza Las Américas',
        tipoTiendaId: 1,
        tipoTiendaNombre: 'Supermercado',
        totalCompras: 5,
      );
      final map = tienda.toMap();
      expect(map['tipo_tienda_id'], 1);
      expect(map['ubicacion'], 'Plaza Las Américas');

      final desdeMap = Tienda.fromMap(map);
      expect(desdeMap.id, 2);
      expect(desdeMap.tipoTiendaId, 1);
    });

    test('Producto calcula los 5 estados según reglas estrictas', () {
      // Caducado
      final pCaducado = Producto.fromMap({
        'id': 1,
        'nombre': 'Yogur',
        'stock_minimo': 2.0,
        'stock_actual': 3.0,
        'tiene_caducado': 1,
        'tiene_por_caducar': 0,
      });
      expect(pCaducado.estado, EstadoProducto.caducado);

      // Agotado
      final pAgotado = Producto.fromMap({
        'id': 2,
        'nombre': 'Arroz',
        'stock_minimo': 2.0,
        'stock_actual': 0.0,
        'tiene_caducado': 0,
        'tiene_por_caducar': 0,
      });
      expect(pAgotado.estado, EstadoProducto.agotado);

      // Por Caducar
      final pPorCaducar = Producto.fromMap({
        'id': 3,
        'nombre': 'Leche',
        'stock_minimo': 1.0,
        'stock_actual': 2.0,
        'tiene_caducado': 0,
        'tiene_por_caducar': 1,
      });
      expect(pPorCaducar.estado, EstadoProducto.porCaducar);

      // Por Agotarse
      final pPorAgotarse = Producto.fromMap({
        'id': 4,
        'nombre': 'Aceite',
        'stock_minimo': 2.0,
        'stock_actual': 1.0,
        'tiene_caducado': 0,
        'tiene_por_caducar': 0,
      });
      expect(pPorAgotarse.estado, EstadoProducto.porAgotarse);

      // En Orden
      final pEnOrden = Producto.fromMap({
        'id': 5,
        'nombre': 'Azúcar',
        'stock_minimo': 1.0,
        'stock_actual': 4.0,
        'tiene_caducado': 0,
        'tiene_por_caducar': 0,
      });
      expect(pEnOrden.estado, EstadoProducto.enOrden);
    });

    test('Lote calcula días de caducidad y banderas temporales', () {
      final hoy = DateTime.now();
      String formato(DateTime d) =>
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      final loteVencido = Lote(
        productoId: 1,
        cantidad: 2.0,
        fechaCaducidad: formato(hoy.subtract(const Duration(days: 2))),
      );
      expect(loteVencido.estaCaducado, isTrue);

      final loteHoy = Lote(
        productoId: 1,
        cantidad: 1.0,
        fechaCaducidad: formato(hoy),
      );
      expect(loteHoy.caducaHoy, isTrue);

      final lotePorCaducar = Lote(
        productoId: 1,
        cantidad: 3.0,
        fechaCaducidad: formato(hoy.add(const Duration(days: 2))),
      );
      expect(lotePorCaducar.porCaducar, isTrue);
    });

    test('HistorialCompra y CarritoItem serializan correctamente', () {
      const hc = HistorialCompra(
        productoId: 1,
        tiendaId: 2,
        cantidad: 3.0,
        precioUnitario: 28.5,
        fechaCompra: '2026-10-15',
      );
      expect(hc.totalGasto, 85.5);

      const item = CarritoItem(productoId: 1, cantidadAComprar: 2.0);
      final mapItem = item.toMap();
      expect(mapItem['cantidad_a_comprar'], 2.0);
      expect(mapItem['producto_id'], 1);
    });

    test('DAOs se pueden instanciar correctamente con su configuración por defecto', () {
      expect(CategoriaDao(), isNotNull);
      expect(TipoTiendaDao(), isNotNull);
      expect(TiendaDao(), isNotNull);
      expect(ProductoDao(), isNotNull);
      expect(LoteDao(), isNotNull);
      expect(CompraDao(), isNotNull);
      expect(CarritoDao(), isNotNull);
    });
  });
}
