# Diccionario de Datos — Olist E-Commerce

**Proyecto:** Desarrollo de un Proyecto de Análisis de Datos y Modelo Predictivo para una Aplicación de Negocio
**Caso:** Brazilian E-Commerce Public Dataset by Olist (2017-2018)
**Autores:** Carlos Alberto Moreno David · Juan Esteban García Ocampo · Emiliano Vélez Suárez · Sebastián Ciro Medellín
**Versión:** Mayo de 2026

---

## Contenido

1. Esquema estrella (modelo de datos)
2. Tablas de dimensiones (`dim_*`)
3. Tablas de hechos (`fact_*`)
4. Tabla analítica denormalizada (`mart_orders`)
5. Reglas de negocio (RB1-RB10)
6. KPIs del negocio (K1-K8)
7. Tipos y convenciones

---

## 1. Esquema estrella (modelo de datos)

```
                       +------------------+
                       |     dim_date     |
                       +--------+---------+
                                |
+--------------+   +------------+-----------+   +----------------+
|dim_customers +-->+   fact_order_items     +<--+   dim_sellers  |
+--------------+   |  (1 fila por ítem)     |   +----------------+
                   |                        |
+--------------+   |                        |   +----------------+
| dim_products +-->+                        +<--+ dim_geography  |
+--------------+   +------------+-----------+   +----------------+
                                |
                       +--------+---------+
                       |  fact_payments   |
                       +------------------+
                       (1 fila por pago)
                                |
                       +--------+---------+
                       |  dim_reviews     |
                       |  (1 fila / orden)|
                       +------------------+
```

### Resumen de tablas

| Tabla | Tipo | Granularidad | PK | Filas |
|---|---|---|---|---|
| `dim_customers`     | Dimensión | 1 fila por customer_id      | `customer_id`        | 99 441 |
| `dim_sellers`       | Dimensión | 1 fila por seller_id        | `seller_id`          | 3 095  |
| `dim_products`      | Dimensión | 1 fila por product_id       | `product_id`         | 32 951 |
| `dim_geography`     | Dimensión | 1 fila por zip_code_prefix  | `geolocation_zip_code_prefix` | 19 015 |
| `dim_date`          | Dimensión | 1 fila por día calendario   | `date`               | 774    |
| `dim_reviews`       | Dimensión | 1 fila por orden con reseña | `review_id`          | 98 673 |
| `fact_order_items`  | Hecho     | 1 fila por (order_id, order_item_id) | (`order_id`, `order_item_id`) | 112 650 |
| `fact_payments`     | Hecho     | 1 fila por (order_id, payment_sequential) | (`order_id`, `payment_sequential`) | 103 886 |
| `mart_orders`       | Mart denormalizado | 1 fila por order_id | `order_id` | 98 666 |

### Relaciones del esquema estrella

| Origen (muchos) | Destino (uno) | Cardinalidad |
|---|---|---|
| `fact_order_items.customer_id` | `dim_customers.customer_id` | N:1 |
| `fact_order_items.seller_id`   | `dim_sellers.seller_id`     | N:1 |
| `fact_order_items.product_id`  | `dim_products.product_id`   | N:1 |
| `fact_order_items.order_purchase_timestamp` (truncada al día) | `dim_date.date` | N:1 |
| `fact_order_items.order_id`    | `dim_reviews.order_id`      | N:1 |
| `fact_payments.order_id`       | `dim_reviews.order_id`      | N:1 |
| `dim_customers.customer_zip_code_prefix` | `dim_geography.geolocation_zip_code_prefix` | N:1 |

---

## 2. Tablas de dimensiones

### 2.1 `dim_customers.csv` (99 441 filas · 5 columnas)

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `customer_id`               | string | Identificador único del cliente *por orden* (cambia entre órdenes del mismo cliente real). PK. | `olist_customers_dataset.csv` |
| `customer_unique_id`        | string | Identificador único y persistente del cliente real. **Usar este para contar clientes únicos (RB4)**. | `olist_customers_dataset.csv` |
| `customer_zip_code_prefix`  | string | Primeros 5 dígitos del código postal brasileño. FK a `dim_geography`. | `olist_customers_dataset.csv` |
| `customer_city`             | string | Ciudad del cliente, normalizada (minúsculas, sin tildes). | `olist_customers_dataset.csv` |
| `customer_state`            | string | Estado brasileño (código ISO de 2 letras, ej. SP, RJ, MG). | `olist_customers_dataset.csv` |

### 2.2 `dim_sellers.csv` (3 095 filas · 4 columnas)

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `seller_id`               | string | Identificador único del vendedor. PK. | `olist_sellers_dataset.csv` |
| `seller_zip_code_prefix`  | string | Prefijo del código postal del vendedor. FK a `dim_geography`. | `olist_sellers_dataset.csv` |
| `seller_city`             | string | Ciudad del vendedor, normalizada. | `olist_sellers_dataset.csv` |
| `seller_state`            | string | Estado brasileño del vendedor. | `olist_sellers_dataset.csv` |

### 2.3 `dim_products.csv` (32 951 filas · 10 columnas)

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `product_id`                       | string | Identificador único del producto. PK. | `olist_products_dataset.csv` |
| `product_category_name`            | string | Categoría en portugués (texto original). | `olist_products_dataset.csv` |
| `product_name_lenght`              | int    | Longitud del nombre del producto (caracteres). | `olist_products_dataset.csv` |
| `product_description_lenght`       | int    | Longitud de la descripción (caracteres). | `olist_products_dataset.csv` |
| `product_photos_qty`               | int    | Cantidad de fotos del producto. | `olist_products_dataset.csv` |
| `product_weight_g`                 | float  | Peso en gramos. Nulos imputados con mediana de la categoría. | `olist_products_dataset.csv` + ETL |
| `product_length_cm`                | float  | Largo en cm. Imputado igual que el peso. | `olist_products_dataset.csv` + ETL |
| `product_height_cm`                | float  | Alto en cm. Imputado igual que el peso. | `olist_products_dataset.csv` + ETL |
| `product_width_cm`                 | float  | Ancho en cm. Imputado igual que el peso. | `olist_products_dataset.csv` + ETL |
| `product_category_name_english`    | string | Categoría traducida al inglés. Nulos → `"unknown"`. | Join con `product_category_name_translation.csv` |

### 2.4 `dim_geography.csv` (19 015 filas · 5 columnas)

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `geolocation_zip_code_prefix` | string | Prefijo del código postal (~zip+4 truncado a 5 dígitos). PK. | `olist_geolocation_dataset.csv` (colapsado por prefix en ETL) |
| `geolocation_lat`             | float  | Latitud (mediana del grupo de coordenadas por zip). | ETL — agregación |
| `geolocation_lng`             | float  | Longitud (mediana del grupo). | ETL — agregación |
| `geolocation_city`            | string | Ciudad más frecuente para ese zip, normalizada. | ETL — moda |
| `geolocation_state`           | string | Estado más frecuente para ese zip. | ETL — moda |

> El archivo crudo tenía 1 000 163 registros con muchas coordenadas por zip; el ETL los colapsa a 19 015 (uno por zip), tomando la mediana de lat/lng y la moda de city/state.

### 2.5 `dim_date.csv` (774 filas · 9 columnas)

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `date`         | date    | Fecha calendario. PK. Cubre desde la primera hasta la última compra observada. | Generada en ETL con `pd.date_range` |
| `year`         | int     | Año. | Derivada |
| `quarter`      | int     | Trimestre 1-4. | Derivada |
| `month`        | int     | Mes 1-12. | Derivada |
| `month_name`   | string  | Nombre del mes en inglés (January, February…). | Derivada |
| `week`         | int     | Número de semana ISO. | Derivada |
| `day`          | int     | Día del mes 1-31. | Derivada |
| `day_of_week`  | int     | Día de la semana 0=Lunes, 6=Domingo. | Derivada |
| `is_weekend`   | int     | 1 si sábado o domingo, 0 si no. | Derivada (RB7) |

### 2.6 `dim_reviews.csv` (98 673 filas · 8 columnas)

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `review_id`                | string  | Identificador único de la reseña. PK. | `olist_order_reviews_dataset.csv` |
| `order_id`                 | string  | FK a la orden reseñada. Único por orden (en caso de duplicado, se conserva la última por `review_creation_date`). | ETL — dedup |
| `review_score`             | int     | Puntaje de 1 a 5 estrellas. | `olist_order_reviews_dataset.csv` |
| `review_comment_title`     | string  | Título del comentario (en portugués). Frecuentemente nulo. | `olist_order_reviews_dataset.csv` |
| `review_comment_message`   | string  | Cuerpo del comentario (en portugués). Frecuentemente nulo. | `olist_order_reviews_dataset.csv` |
| `review_creation_date`     | datetime| Cuándo se solicitó la reseña al cliente. | `olist_order_reviews_dataset.csv` |
| `review_answer_timestamp`  | datetime| Cuándo el cliente respondió. | `olist_order_reviews_dataset.csv` |
| `is_positive_review`       | int     | 1 si `review_score >= 4`, 0 si no. **Target del modelo predictivo.** (RB1) | ETL — derivada |

---

## 3. Tablas de hechos

### 3.1 `fact_order_items.csv` (112 650 filas · 15 columnas)

Granularidad: **1 fila por cada ítem dentro de una orden**. PK compuesta: (`order_id`, `order_item_id`).

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `order_id`                        | string  | Identificador de la orden. PK1. | `olist_order_items_dataset.csv` |
| `order_item_id`                   | int     | Número de ítem dentro de la orden (1, 2, 3…). PK2. | `olist_order_items_dataset.csv` |
| `product_id`                      | string  | FK a `dim_products`. | `olist_order_items_dataset.csv` |
| `seller_id`                       | string  | FK a `dim_sellers`. | `olist_order_items_dataset.csv` |
| `shipping_limit_date`             | datetime| Fecha límite para que el vendedor entregue al carrier. | `olist_order_items_dataset.csv` |
| `price`                           | float   | Precio del ítem (R$). | `olist_order_items_dataset.csv` |
| `freight_value`                   | float   | Costo de flete del ítem (R$). | `olist_order_items_dataset.csv` |
| `total_item_value`                | float   | `price + freight_value`. Métrica derivada. | ETL |
| `customer_id`                     | string  | FK a `dim_customers`. | Join con `olist_orders_dataset.csv` |
| `order_status`                    | string  | Estado de la orden (delivered, canceled, shipped, processing…). | `olist_orders_dataset.csv` |
| `order_purchase_timestamp`        | datetime| Momento en que el cliente realizó la compra. | `olist_orders_dataset.csv` |
| `order_delivered_customer_date`   | datetime| Momento en que el cliente recibió la orden (null si no fue entregada). | `olist_orders_dataset.csv` |
| `delivery_days_real`              | float   | Días entre compra y entrega real. Null si no entregada. | ETL — derivada |
| `delivery_delay_days`             | float   | `delivery_days_real − delivery_days_estimated`. Negativo = anticipada. | ETL — derivada |
| `is_late`                         | int     | 1 si `delivery_delay_days > 0` y `order_status = "delivered"`. (RB2) | ETL — derivada |

### 3.2 `fact_payments.csv` (103 886 filas · 5 columnas)

Granularidad: **1 fila por cada pago de una orden**. Una orden puede tener pagos fraccionados. PK compuesta: (`order_id`, `payment_sequential`).

| Columna | Tipo | Descripción | Origen |
|---|---|---|---|
| `order_id`              | string | Identificador de la orden. PK1. FK a `fact_order_items` y `dim_reviews`. | `olist_order_payments_dataset.csv` |
| `payment_sequential`    | int    | Secuencia del pago dentro de la orden (1, 2, 3…). PK2. | `olist_order_payments_dataset.csv` |
| `payment_type`          | string | Método: `credit_card`, `boleto`, `voucher`, `debit_card`, `not_defined`. | `olist_order_payments_dataset.csv` |
| `payment_installments`  | int    | Número de cuotas elegidas por el cliente para este pago. | `olist_order_payments_dataset.csv` |
| `payment_value`         | float  | Monto pagado en este movimiento (R$). | `olist_order_payments_dataset.csv` |

---

## 4. Tabla analítica denormalizada `mart_orders.csv`

**Granularidad: 1 fila por `order_id`** (98 666 órdenes × 31 columnas). Es el insumo directo del EDA, del dashboard de BI y del modelo predictivo. Construida en `Fase1_ETL.ipynb` sección 8.

### 4.1 Identificadores y status de la orden

| Columna | Tipo | Descripción |
|---|---|---|
| `order_id`                       | string  | PK. |
| `customer_id`                    | string  | FK a `dim_customers`. |
| `order_status`                   | string  | `delivered` / `canceled` / `shipped` / `processing` / etc. |
| `order_purchase_timestamp`       | datetime| Momento de la compra. |
| `order_delivered_customer_date`  | datetime| Momento de la entrega (null si no entregada). |

### 4.2 Variables logísticas (derivadas)

| Columna | Tipo | Descripción | Regla |
|---|---|---|---|
| `delivery_days_real`   | float | Días reales de entrega. Null si no entregada. | — |
| `delivery_delay_days`  | float | Días respecto al estimado (negativo = anticipada). | — |
| `is_late`              | int   | 1 si la entrega llegó después del estimado. | **RB2** |

### 4.3 Variables agregadas por orden (desde `fact_order_items`)

| Columna | Tipo | Descripción |
|---|---|---|
| `n_items`               | int   | Número total de ítems en la orden. |
| `n_distinct_products`   | int   | Número de productos distintos. |
| `n_distinct_sellers`    | int   | Número de vendedores distintos. |
| `total_price`           | float | Suma de `price` de los ítems (R$). |
| `total_freight`         | float | Suma de `freight_value` de los ítems (R$). |
| `total_value`           | float | `total_price + total_freight` (R$). **Ticket de la orden**. |
| `avg_item_price`        | float | Precio medio por ítem (R$). |
| `first_seller_id`       | string| Vendedor del primer ítem (representativo si la orden tiene varios). |
| `first_product_id`      | string| Producto del primer ítem. |

### 4.4 Variables agregadas por orden (desde `fact_payments`)

| Columna | Tipo | Descripción |
|---|---|---|
| `n_payments`                | int    | Número de pagos asociados a la orden (típicamente 1). |
| `payment_total`             | float  | Suma de `payment_value` (R$). Suele coincidir con `total_value`. |
| `payment_installments_max`  | int    | Mayor número de cuotas de los pagos de la orden. |
| `main_payment_type`         | string | Tipo de pago dominante (modo) de la orden. |

### 4.5 Variables de cliente, vendedor y producto (joins con dimensiones)

| Columna | Tipo | Descripción |
|---|---|---|
| `customer_state`           | string | Estado del cliente. |
| `customer_city`            | string | Ciudad del cliente, normalizada. |
| `first_seller_state`       | string | Estado del primer vendedor. |
| `first_product_category`   | string | Categoría (en inglés) del primer producto. |

### 4.6 Variables temporales (derivadas)

| Columna | Tipo | Descripción |
|---|---|---|
| `purchase_year`    | int    | Año de la compra. |
| `purchase_month`   | string | Período en formato `YYYY-MM`. |
| `purchase_dow`     | int    | Día de la semana 0=Lunes, 6=Domingo. |
| `is_weekend`       | int    | 1 si sábado o domingo. **RB7** |

### 4.7 Variables de reseña (join con `dim_reviews`)

| Columna | Tipo | Descripción | Regla |
|---|---|---|---|
| `review_score`        | float | Puntaje 1-5. Null si la orden no tiene reseña. | — |
| `is_positive_review`  | float | 1 si score ≥ 4, 0 si no. **Target del modelo predictivo.** | **RB1** |

---

## 5. Reglas de negocio (RB1-RB10)

Las reglas de negocio son las **definiciones operacionales** del proyecto. Cualquier cálculo en Python, DAX o SQL debe respetarlas para garantizar coherencia entre fases.

| # | Regla | Definición operacional | Dónde se aplica |
|---|---|---|---|
| **RB1** | Reseña positiva | `review_score >= 4` | Columna `is_positive_review` en `dim_reviews` y `mart_orders`; medida DAX `CSAT_%`. |
| **RB2** | Entrega tardía | `delivery_delay_days > 0` **AND** `order_status = "delivered"` | Columna `is_late` en `fact_order_items` y `mart_orders`; medida DAX `Late_Orders_%`. |
| **RB3** | Orden entregada | `order_status = "delivered"` | Filtro base para todos los análisis logísticos. |
| **RB4** | Cliente único | `customer_unique_id` (NO `customer_id`, que cambia por orden) | Medida DAX `N_Customers_Unique`. |
| **RB5** | OTIF (On-Time In-Full) | Proporción de órdenes entregadas que **no** son `is_late` | Medida DAX `OTIF_%`. |
| **RB6** | CSAT | Proporción de reseñas con `is_positive_review = 1` sobre el total de órdenes con reseña | Medida DAX `CSAT_%`. |
| **RB7** | Fin de semana | `day_of_week ∈ {5, 6}` (sábado, domingo) | Columna `is_weekend` en `dim_date` y `mart_orders`. |
| **RB8** | Cancelación | `order_status = "canceled"` | Medida DAX `Cancel_Rate_%`. |
| **RB9** | Top-3 estados | Los tres estados con mayor número de órdenes en el período filtrado | Medida DAX `Top3_States_Share_%`. |
| **RB10** | Vendedor en riesgo | Vendedor con ≥ 50 órdenes y CSAT por debajo del CSAT global menos 5 p.p. | Dashboard página 3 — drill desde "categorías con menor CSAT". |

---

## 6. KPIs del negocio (K1-K8)

| # | KPI | Fórmula | Valor actual | Meta |
|---|---|---|---|---|
| **K1** | **CSAT** — % reseñas positivas | `mean(is_positive_review) × 100` | 77.6 % | ≥ 80 % |
| **K2** | Puntaje promedio de reseña | `mean(review_score)` | 4.10 / 5 | ≥ 4.20 |
| **K3** | **OTIF** — % entregas a tiempo | `mean(is_late == 0) × 100` (sobre entregadas) | 91.9 % | ≥ 95 % |
| **K4** | Tiempo medio de entrega (días) | `mean(delivery_days_real)` (sobre entregadas) | 12.6 | ≤ 10 |
| **K5** | Ticket promedio (R$) | `mean(total_value)` | R$ 161 | — |
| **K6** | Tasa de cancelación | `mean(order_status == "canceled") × 100` | 0.47 % | ≤ 1 % |
| **K7** | Crecimiento MoM promedio | media de `(N_orders_t / N_orders_{t−1} − 1) × 100` | positivo | sostenido |
| **K8** | Concentración top-3 estados | `sum(% top-3 estados)` | 66.6 % | ≤ 50 % |

---

## 7. Tipos y convenciones

### Convenciones de nombres

- **Tablas**: `dim_*` para dimensiones, `fact_*` para hechos, `mart_*` para marts denormalizados.
- **Columnas**: snake_case, en inglés (la mayoría heredadas del dataset original).
- **Fechas**: ISO 8601 (`YYYY-MM-DD HH:MM:SS`).
- **Códigos geográficos**: estado en código ISO de 2 letras mayúsculas (SP, RJ…); zip como string para preservar ceros a la izquierda.
- **Booleanos**: representados como `int` (0/1) para compatibilidad con BI y ML.

### Tipos canónicos

| Concepto | Tipo en CSV | Notas |
|---|---|---|
| Identificadores (`*_id`) | string | Hash alfanumérico de Olist. |
| Códigos postales (`*_zip_code_prefix`) | string | Cinco dígitos; conservados como string para evitar pérdida de ceros iniciales. |
| Fechas y timestamps | string ISO 8601 | Pandas las parsea con `parse_dates` al cargar. |
| Estados (`*_state`) | string | Código ISO BR de 2 letras (SP, RJ, MG…). |
| Métricas monetarias | float | Reales brasileños (BRL). |
| Conteos | int | Pueden ser `Int64` (entero con nulos) en `dim_products`. |
| Flags binarios (`is_*`) | int | 0/1 (no booleano nativo, para compatibilidad universal). |

### Codificación

- Todos los CSV están en **UTF-8**.
- El archivo `product_category_name_translation.csv` contiene BOM al inicio (manejado con `encoding="utf-8-sig"`).

### Reproducibilidad

Cada archivo se puede regenerar ejecutando `Notebooks/Fase1_ETL.ipynb` de principio a fin. El proceso es determinístico (mismas entradas → mismas salidas).

---

## Referencias cruzadas

- **Fase 1 (ETL)**: `Notebooks/Fase1_ETL.ipynb` construye todas las tablas listadas en este diccionario.
- **Fase 2 (EDA)**: `Notebooks/Fase2_EDA.ipynb` consume principalmente `mart_orders.csv`.
- **Fase 3 (BI)**: `BI_Dashboard/DAX_Measures.dax` implementa todas las medidas según las reglas RB1-RB10; `BI_Dashboard/PowerQuery_Loaders.m` carga las 8 tablas dimensionales.
- **Fase 4 (Modelo)**: `Notebooks/Fase4_Modelado.ipynb` usa `mart_orders.csv` con `is_positive_review` como target.
