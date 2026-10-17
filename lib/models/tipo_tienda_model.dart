class TipoTienda {
  final int? id;
  final String nombre;

  const TipoTienda({
    this.id,
    required this.nombre,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory TipoTienda.fromMap(Map<String, dynamic> map) {
    return TipoTienda(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? '',
    );
  }
}
