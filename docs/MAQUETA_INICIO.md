# Maquetas visuales de alacena

Ejecutar desde `gestion-inventario/`:

El proyecto requiere Dart 3.13.1 o superior, menor que 4.0.0.

```bash
flutter pub get
flutter run
```

La entrada independiente conserva la eliminación previa de `lib/main.dart`.
La carpeta `../lib/` con el código para reciclar permanece intacta.

- `lib/screens/pantalla_inicio.dart`: estructura con Slivers, encabezado, filtros,
  secciones, botón flotante y navegación visual Inicio / Calendario / Tiendas /
  Carrito.
- `lib/widgets/tarjeta_producto.dart`: tarjeta y etiqueta de estado reutilizables.
- `lib/screens/pantalla_detalle_producto.dart`: portada, resumen de existencias,
  compra, consumo exprés, lotes y pestañas de historial y tiendas con datos fijos.
- `lib/screens/pantalla_carrito.dart`: una sola lista de compras;
  selección de productos del catálogo y cantidades a comprar.
  Se abre desde el contador de Inicio o desde Carrito en la barra inferior.
- `lib/presentation/controlador_carrito.dart`: estado compartido sincronizado con SQLite
  para conservar la lista de compras entre pantallas.
- `lib/screens/pantalla_registrar_compra.dart`: formulario de compra con
  producto, tienda, cantidades, precio, fechas, ubicación y resumen de stock.
  Se abre desde Anotar compra en el detalle o desde Agregar, debajo de los
  productos del carrito, como indica la flecha de la imagen. Ese campo permite
  elegir un producto del catálogo para registrar la compra. Completar una lista
  no abre el formulario.
- `lib/screens/pantalla_tiendas.dart`: catálogo visual con cuatro tiendas,
  buscador, filtros, direcciones, compras de ejemplo y botón Nueva tienda.
  Se abre desde Tiendas en la barra inferior de Inicio. El menú permite abrir
  Editar tienda y Nueva tienda abren el mismo formulario. Historial de compras,
  Desactivar, filtros y búsqueda
  todavía no ejecutan operaciones.
- `lib/screens/formulario_tienda.dart`: formulario compartido para crear y
  editar tiendas. Crear inicia los campos vacíos y no muestra gestión de
  registros existentes. Editar precarga nombre, dirección y compras vinculadas.
- `lib/screens/pantalla_editar_tienda.dart`: entrada compatible al formulario común con nombre,
  establecimiento, dirección, tienda habitual, notas y gestión del catálogo.
  Recibe el nombre, la dirección y el número de compras de la tarjeta elegida.
  El tipo y el interruptor cambian visualmente; guardar, mapa y desactivación
  no ejecutan operaciones. Eliminar se muestra bloqueado para estas tiendas con
  compras. Las preferencias y notas son ejemplos sin persistencia.
- `lib/screens/formulario_producto.dart`: formulario compartido para crear y
  editar productos. Editar precarga nombre, categoría, unidad y stock mínimo;
  no registra un primer lote nuevo ni modifica los existentes. Se abre desde
  la acción Editar al deslizar un producto o desde el icono del detalle.
- `lib/screens/pantalla_nuevo_articulo.dart`: entrada compatible al formulario común de alta con fotografía opcional,
  nombre, categorías, unidades, stock mínimo, primer lote, recordatorio y zona
  de almacenamiento. Se abre con el botón + de Inicio o Nuevo producto en
  Registrar compra. Selecciones y contadores solo cambian en memoria; guardar,
  fecha, cámara, galería y escáner todavía no ejecutan operaciones. El
  interruptor no solicita permisos ni programa notificaciones locales.
- `lib/screens/pantalla_calendario.dart`: calendario con `table_calendar`, leyenda
  de cuatro estados, puntos por alerta, navegación mensual y resumen del día.
  Se abre desde Calendario en Inicio. Al tocar una fecha muestra un modal de
  pantalla completa con los productos, cantidades, ubicaciones y estados de
  ese día. Cerrar el modal permite consultar el resumen actualizado debajo del
  calendario. Incluye el estado de día sin alertas.
- `lib/presentation/modelos_vista_calendario.dart`: modelos de vista para alertas
  y formateo de fechas del calendario.
- `lib/screens/pantalla_alertas_dia.dart`: modal diario con filtros por estado,
  lotes, cantidades, tarjetas con miniatura y botones de acción. El 31 de mayo
  contiene cinco productos para ver todos los estados de la maqueta. Día
  despejado y los filtros cambian el contenido visual. Desechar, Consumir,
  Anotar, Reordenar, Agregar al carrito y Gestionar lote no alteran los datos.
- `lib/widgets/miniatura_producto.dart`: ilustraciones locales de ejemplo;
  acepta `imagePath` para sustituirlas por fotografías al conectar los datos.
- `lib/widgets/acciones_deslizables_catalogo.dart`: componente compartido con
  `flutter_slidable`. Deslizar hacia la izquierda muestra Editar y Borrar sobre
  fondo azul marino en productos y tiendas. Editar abre el formulario común;
  Borrar muestra un diálogo. Las tiendas con compras conservan el bloqueo y los
  productos muestran la propuesta de baja lógica; no hay escrituras ni bajas
  reales todavía.
- `lib/widgets/barra_navegacion_inferior.dart`: barra inferior común en Inicio,
  Calendario, lista del día, Tiendas, Carrito, detalle y todos los formularios.
  Usa rutas nombradas y conserva la raíz de Inicio al cambiar de sección. El
  botón Completar lista del carrito permanece encima de ella.
- `lib/widgets/encabezado_seccion.dart`: encabezado compartido con el recuadro
  verde, marca ALACENA y nombre de la sección. Cada sección tiene un símbolo
  propio: refrigerador en Inicio, calendario, tienda, carrito, inventario para
  el detalle, recibo para compras y variantes de alta/edición en formularios.
  La vista diaria usa una hoja de calendario. Mantiene los botones de volver y
  las acciones existentes y adapta el tamaño del logo a pantallas estrechas.
- `lib/components/tema_alacena.dart`: colores y tema.
- `lib/presentation/modelos_vista_alacena.dart`: modelos de vista y agrupación
  por estado conectados a SQLite para la pantalla principal.

Tocar una tarjeta abre el detalle del producto y la flecha permite regresar.
Las pestañas del detalle cambian el contenido visual. Los demás botones y
filtros son visuales: no modifican inventario ni ejecutan búsquedas.
El carrito permite agregar y quitar productos, ajustar cantidades y vaciar
la lista al completarla. No hay listas pendientes ni historial de listas. No escribe a
SQLite, no registra compras y no actualiza la alacena. Se quitó el selector de
estado vacío, la tienda preferida y la actualización automática de existencias.
Guardar compra y escanear ticket son
controles visuales: no guardan datos ni abren la cámara. Los totales del
formulario son ejemplos fijos y no se recalculan al escribir un precio.
Los callbacks públicos de `HomeScreen` y
`ProductCard` permiten conectar esas acciones después. Los conteos y las fechas
son ejemplos fijos. El contador del carrito de Inicio usa `badges.Badge` del
paquete `badges`, con el alias `badges` para evitar confusión con el widget de
Flutter. El calendario usa `TableCalendar` del paquete `table_calendar`; ambos
paquetes ya estaban declarados. El contador refleja los productos distintos de
la lista actual. El nuevo flujo se documenta en [FLUJO_LISTAS_DE_COMPRA.md](FLUJO_LISTAS_DE_COMPRA.md).

Se añadió `flutter_slidable` para las acciones de tarjetas. No se añadió
Firebase, persistencia ni Hero. El test original
del contador se conserva: corresponde al `main.dart` anterior, no a esta vista.

## Verificación

Se añadió `test/home_design_test.dart` para verificar la distribución a 320,
390 y 600 píxeles de ancho y el desplazamiento hasta el último producto.

```bash
flutter test test/home_design_test.dart
flutter test test/product_detail_design_test.dart
flutter test test/cart_design_test.dart
flutter test test/register_purchase_design_test.dart
flutter test test/stores_design_test.dart
flutter test test/edit_store_design_test.dart
flutter test test/new_article_design_test.dart
flutter test test/calendar_design_test.dart
flutter test test/day_alerts_design_test.dart
flutter test test/forms_and_navigation_test.dart
```

En este entorno se verificó una copia aislada de los mismos archivos con las
dependencias de Flutter disponibles: el SDK instalado tiene Dart 3.13.1 y
algunas dependencias preexistentes del proyecto no están en la caché local.
Posteriormente se ajustó la versión mínima de Dart en `pubspec.yaml` a 3.13.1
para admitir el SDK instalado. No se modificó el SDK instalado.

Vista previa: [maqueta_inicio.png](maqueta_inicio.png).
