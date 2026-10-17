class Categoria {
  final int? id;
  final String nombre;
  final String? icono;

  const Categoria({
    this.id,
    required this.nombre,
    this.icono,
  });

  int? get idCategoria => id;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: (map['id'] ?? map['id_categoria']) as int?,
      nombre: map['nombre'] as String? ?? '',
      icono: map['icono'] as String?,
    );
  }
}
