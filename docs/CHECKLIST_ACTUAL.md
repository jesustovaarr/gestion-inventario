# Checklist después de integrar main

Fecha: 18 de octubre de 2026. Base integrada: `d06be1f` de `origin/main`.

Este checklist refleja el código y las pruebas del proyecto; no sustituye una rúbrica oficial, que no se encontró en el repositorio.
Una casilla marcada indica implementación revisada, no certificación en un teléfono real.

## Integración y cambios conservados

- [x] Incorporar los commits nuevos de main sobre `7446f2b`.
- [x] Conservar el stock mínimo capturado por presentación y su conversión para calcular alertas.
- [x] Conservar la prioridad del lote caducado en Inicio.
- [x] Mostrar el lote que vence pronto al seleccionar «Por caducar», aunque el producto tenga otro lote vencido.
- [x] Conservar la eliminación de filtros y etiquetas «Caducado», «Por caducar» y «Por agotarse» de la vista del día del calendario.
- [x] Resolver los conflictos del formulario y de la vista del día conservando cámara, escáner y configuración de alarmas.
- [x] Mantener un respaldo de los ocho archivos locales previos en el stash `6a4d309b275604be56ce8e709c0bac3994259a05` y un parche adicional en `/tmp/inventario-local-before-main-20261018.patch`.

## Funciones implementadas

- [x] Crear, editar y eliminar productos; distinguir cada tamaño y presentación.
- [x] Guardar productos, lotes, tiendas, carrito e historial en SQLite.
- [x] Buscar productos y filtrar sus estados en Inicio.
- [x] Registrar consumo con FEFO y desechar lotes caducados.
- [x] Gestionar el carrito, registrar compras y actualizar existencias.
- [x] Consultar historial de compras y movimientos.
- [x] Crear y editar tiendas.
- [x] Consultar lotes por fecha y editar su caducidad en el calendario.
- [x] Incorporar selección de fotografías desde cámara o galería, guardado local y eliminación de la foto asociada.
- [x] Incorporar escaneo de códigos con cámara e ingreso manual.
- [x] Consultar datos por código en Open Food Facts y autocompletar campos cuando haya información.
- [x] Mostrar códigos de barras EAN-13 y Code 128.
- [x] Sugerir precios desde el catálogo local o por categoría; son referencias, no cotizaciones actuales.
- [x] Incorporar servicio de notificaciones locales y configuración de fecha, hora y activación por lote.
- [x] Validar que una alarma no se active para una fecha u hora pasada.
- [x] Incorporar apertura de la fecha del calendario desde una notificación.

## Pendientes y límites encontrados

- [ ] Completar la sincronización de alarmas con todos los movimientos del inventario. Consumir, desechar o eliminar no llama a la cancelación del servicio; registrar compras tampoco programa automáticamente sus lotes. Revisar `lib/database/daos/`, `lib/presentation/acciones_inventario.dart` y `lib/services/servicio_notificaciones.dart`.
- [ ] Reprogramar la alarma al cambiar la caducidad desde el editor de fecha del calendario: ese flujo actualiza SQLite, pero no llama al servicio de notificaciones. El diálogo específico de configuración de alarma sí contempla programación/cancelación.
- [ ] Validar la recuperación completa de borradores al volver de la cámara. En edición, la carga desde SQLite puede sobrescribir campos del borrador; no se certificó recuperación completa de cambios sin guardar.
- [ ] Completar la configuración de cámara y galería para iOS si se entregará en esa plataforma: `ios/Runner/Info.plist` no contiene las descripciones de uso de cámara y fototeca.
- [ ] Implementar sugerencias de tiendas por cercanía si son parte de los requisitos: no hay integración de geolocalización.
- [ ] Probar en teléfono real cámara, galería, lectura de códigos, permisos, entrega de alarmas y apertura desde la notificación con la app cerrada.
- [ ] Contrastar las funciones con la rúbrica oficial para afirmar cumplimiento total.

## Verificación realizada

- [x] `flutter pub get`: dependencias resueltas.
- [x] `flutter analyze --no-pub`: sin problemas.
- [x] `flutter test --no-pub`: 119 pruebas aprobadas, incluyendo los cambios locales conservados.
- [x] `git diff --check`: sin errores de espacios ni marcadores de conflicto.
- [ ] Compilación e instalación nativa: no realizadas en esta revisión.

Las pruebas de notificaciones usan una ruta en memoria y las consultas externas emplean respuestas simuladas en los casos correspondientes. Su aprobación no demuestra entrega real de notificaciones ni lectura física mediante cámara.
