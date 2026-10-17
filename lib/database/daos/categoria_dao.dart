import 'package:sqflite/sqflite.dart';
import '../../models/categoria_model.dart';
import '../inventario_db.dart';

class CategoriaDao {
  final Database? _database;

  CategoriaDao([this._database]);

  Future<Database> get _db async => _database ?? await InventarioDB().database;

  Future<List<Categoria>> obtenerTodas() async {
    final db = await _db;
    final res = await db.query('Categoria', orderBy: 'nombre ASC');
    return res.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<Categoria?> obtenerPorId(int id) async {
    final db = await _db;
    final res = await db.query('Categoria', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return Categoria.fromMap(res.first);
  }

  Future<int> insertar(String nombre) async {
    final db = await _db;
    return await db.insert('Categoria', {'nombre': nombre});
  }
}
