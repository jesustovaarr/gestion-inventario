# Productos, cantidades y compras

La regla es simple: **cada tamaño es un producto independiente**, con su propio ID.
Puedes registrar dos artículos llamados «Papas Sabritas», uno de 500 g y otro de
1000 g. En Inicio y Carrito se muestra su presentación para distinguirlos.
Editar o borrar el de 500 g no cambia el de 1000 g.

## Ejemplo de compra

1. En Inicio, crea «Papas Sabritas»: elige presentación Bolsa, unidad g y contenido 500.
2. Para el tamaño de 1000 g, crea otro producto con ese contenido.
3. Añádelos al carrito. Cada producto ocupa un renglón; el botón + suma una bolsa.
4. Toca un renglón para indicar cuántas bolsas, precio por bolsa y caducidad.
5. Elige tienda y fecha de compra. Al guardar, se registra el total y aumenta el inventario.

Diez bolsas de 500 g son 5000 g. Tres bolsas de 1000 g son 3000 g.
El precio de la compra se introduce por bolsa, no por gramo.
Para registrar otro tamaño, crea el producto desde **Inicio** y después
selecciónalo en **Agregar productos** dentro del carrito.

Un **lote** representa una entrada de existencias de ese producto con una fecha de
caducidad. Dos compras del mismo tamaño pueden crear dos lotes con fechas distintas.
Al consumir, se usa primero el que caduca antes. Los lotes vacíos se conservan en
la base de datos para el historial, pero se ocultan al editar las existencias.
La X de un lote permite retirarlo: se quitan sus existencias al pulsar
**Guardar cambios**. Las compras y los consumos ya registrados se conservan.

## Dónde modificar cada cosa

| Función | Archivo y método |
| --- | --- |
| Crear, editar o borrar un producto | `lib/database/daos/producto_dao.dart` |
| Sumar un producto al carrito | `lib/presentation/controlador_carrito.dart`: `addProduct` |
| Cantidad, precio y fecha de una compra | `lib/widgets/editor_articulo_compra.dart` |
| Guardar compra, lotes e historial | `lib/database/daos/compra_dao.dart`: `registrarCompraCompleta` |
| Descontar del lote que caduca antes | `lib/database/daos/lote_dao.dart`: `descontarStockFEFO` |
