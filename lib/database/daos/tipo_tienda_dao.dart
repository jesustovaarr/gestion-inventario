import 'package:sqflite/sqflite.dart';
import '../../models/tipo_tienda_model.dart';
import '../inventario_db.dart';

class TipoTiendaDao {
  final Database? _database;

  TipoTiendaDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  Future<List<TipoTienda>> obtenerTodos() async {
    final db = await _db;
    final res = await db.query('Tipo_Tienda', orderBy: 'id ASC');
    return res.map((m) => TipoTienda.fromMap(m)).toList();
  }

  Future<TipoTienda?> obtenerPorId(int id) async {
    final db = await _db;
    final res = await db.query('Tipo_Tienda', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return TipoTienda.fromMap(res.first);
  }

  Future<int> insertar(String nombre) async {
    final db = await _db;
    return await db.insert('Tipo_Tienda', {'nombre': nombre});
  }
}
