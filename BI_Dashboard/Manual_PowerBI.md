# Manual de construcción del dashboard en Power BI Desktop

**Proyecto:** Olist E-Commerce — Análisis del marketplace brasileño
**Insumos:** carpeta `Data/processed/` (modelo estrella ya generado por la Fase 1.2 ETL)
**Salida esperada:** archivo `Olist_Dashboard.pbix` con 3 páginas funcionales
**Tiempo estimado de armado:** ~30-40 minutos

Este manual te permite **reproducir paso a paso** en Power BI Desktop el
dashboard cuyo *espejo* HTML está en `BI_Dashboard/Olist_Dashboard.html`.
Cada sección incluye el qué, el cómo y la justificación de la decisión de
diseño.

---

## 0. Requisitos

| Requisito | Detalle |
|---|---|
| Power BI Desktop | Versión 2.130 o superior (mayo 2024+). Descarga gratuita en Microsoft Store. |
| Datos | Los CSVs ya están en `Data/processed/`. No requieren transformación adicional. |
| RAM | 4 GB suficientes para el modelo (~95k filas en la tabla de hechos). |
| Sistema operativo | Power BI Desktop solo corre en Windows. En macOS/Linux: usar la versión web o una máquina virtual. |

---

## 1. Importar las tablas del modelo estrella

> **Importante:** importamos **una tabla por archivo**, conservando los
> nombres dimensionales (`dim_*`, `fact_*`). El archivo `mart_orders.csv`
> NO se usa como tabla en el modelo estrella — su rol es servir de
> *atajo* en el notebook de Fase 4 (modelado predictivo).

1. Abre **Power BI Desktop** → *Inicio* → *Obtener datos* → **Texto/CSV**.
2. Importa estos 8 archivos uno por uno (ruta: `…/Data/processed/`):

| Archivo CSV | Nombre de tabla en PBI | Rol |
|---|---|---|
| `dim_customers.csv`     | `Customers`   | Dimensión cliente |
| `dim_sellers.csv`       | `Sellers`     | Dimensión vendedor |
| `dim_products.csv`      | `Products`    | Dimensión producto |
| `dim_geography.csv`     | `Geography`   | Dimensión geográfica |
| `dim_date.csv`          | `Date`        | Dimensión calendario |
| `dim_reviews.csv`       | `Reviews`     | Dimensión reseñas |
| `fact_order_items.csv`  | `OrderItems`  | Hecho — ítems por orden |
| `fact_payments.csv`     | `Payments`    | Hecho — pagos por orden |

3. En el panel *Vista previa*, **revisa los tipos** detectados. Power BI
   debería marcar `Int64.Type` para los enteros y `DateTime.Type` para las
   columnas que terminan en `_timestamp` / `_date`.
4. Pulsa **Cargar** (no transformar — la limpieza ya se hizo en el ETL).

---

## 2. Marcar la tabla de fechas

1. En el panel *Datos*, clic derecho sobre `Date` → **Marcar como tabla
   de fechas** → elige `date` como columna clave.
2. Esto habilita las funciones DAX de inteligencia de tiempo
   (`SAMEPERIODLASTYEAR`, `DATESYTD`, etc.).

---

## 3. Crear las relaciones del modelo estrella

Ve a la vista **Modelo** (icono del diagrama en la barra lateral
izquierda) y crea las siguientes relaciones arrastrando columnas:

| Origen (cardinalidad muchos) | Destino (cardinalidad uno) | Dirección |
|---|---|---|
| `OrderItems[customer_id]`      | `Customers[customer_id]`   | Una dirección |
| `OrderItems[seller_id]`        | `Sellers[seller_id]`       | Una dirección |
| `OrderItems[product_id]`       | `Products[product_id]`     | Una dirección |
| `OrderItems[order_purchase_timestamp].[Date]` | `Date[date]` | Una dirección |
| `OrderItems[order_id]`         | `Reviews[order_id]`        | Una dirección *(activa)* |
| `Payments[order_id]`           | `Reviews[order_id]`        | Una dirección *(inactiva — opcional)* |
| `Customers[customer_zip_code_prefix]` | `Geography[geolocation_zip_code_prefix]` | Una dirección |

> **Por qué unidireccional:** evita ambigüedades en el cálculo de medidas
> y mejora el rendimiento.

**Validación:** desde la vista *Datos*, ejecuta `EVALUATE
SUMMARIZE(OrderItems, Date[year])` en una consulta DAX rápida. Debes ver
las dos años (2017, 2018).

---

## 4. Paleta de colores y formato global

Tema personalizado (archivo JSON opcional, o configúralo manualmente):

| Token | Color | Uso |
|---|---|---|
| `primary`  | `#1F3A68` | Azul corporativo — títulos, ejes |
| `accent`   | `#FDB813` | Amarillo Olist — destacar KPI |
| `good`     | `#2E7D32` | Verde — métricas en meta |
| `bad`      | `#C62828` | Rojo — métricas en riesgo |
| `warn`     | `#EF6C00` | Naranja — métricas cercanas al umbral |
| `neutral`  | `#90A4AE` | Gris — fondos secundarios |
| `bg`       | `#F4F6F9` | Fondo de página |

**Tipografía:** Segoe UI (incluida por defecto en Windows). Tamaños:
22 pt títulos · 14 pt encabezados de tarjeta · 11 pt texto.

> Cargar tema: *Vista* → *Temas* → *Buscar temas* → opcionalmente
> crear `theme.json` con los hex anteriores.

---

## 5. Medidas DAX — el corazón del dashboard

Crea una **tabla calculada vacía** llamada `_Measures` para agrupar
todas las medidas (clic derecho en *Datos* → *Nueva tabla* →
`_Measures = ROW("dummy", 0)`). Luego ocultar la columna `dummy`.

Copia y pega cada medida (clic derecho sobre `_Measures` → *Nueva medida*).

### 5.1 Volumen y crecimiento

```DAX
N_Orders =
DISTINCTCOUNT( OrderItems[order_id] )

N_Items =
COUNTROWS( OrderItems )

N_Customers_Unique =
DISTINCTCOUNT( Customers[customer_unique_id] )

GMV_Total =
SUM( OrderItems[price] ) + SUM( OrderItems[freight_value] )

Ticket_Promedio =
DIVIDE( [GMV_Total], [N_Orders] )
```

### 5.2 Crecimiento mes a mes

```DAX
N_Orders_PrevMonth =
CALCULATE( [N_Orders], DATEADD( 'Date'[date], -1, MONTH ) )

MoM_Growth_% =
DIVIDE( [N_Orders] - [N_Orders_PrevMonth], [N_Orders_PrevMonth] )
```

### 5.3 Satisfacción (CSAT)

```DAX
N_Reviews =
COUNTROWS( FILTER( Reviews, NOT ISBLANK( Reviews[review_score] ) ) )

CSAT_% =
DIVIDE(
    CALCULATE( COUNTROWS( Reviews ), Reviews[is_positive_review] = 1 ),
    [N_Reviews]
)

Avg_Review_Score =
AVERAGE( Reviews[review_score] )

CSAT_PrevMonth =
CALCULATE( [CSAT_%], DATEADD( 'Date'[date], -1, MONTH ) )

CSAT_Delta_pp =
([CSAT_%] - [CSAT_PrevMonth]) * 100
```

### 5.4 Logística

```DAX
N_Delivered =
CALCULATE( [N_Orders],
           FILTER( OrderItems, OrderItems[order_status] = "delivered" ) )

OTIF_% =
DIVIDE(
    CALCULATE( [N_Delivered],
               FILTER( OrderItems, OrderItems[is_late] = 0 ) ),
    [N_Delivered]
)

Avg_Delivery_Days =
CALCULATE(
    AVERAGE( OrderItems[delivery_days_real] ),
    FILTER( OrderItems, OrderItems[order_status] = "delivered" )
)

Late_Orders_% =
1 - [OTIF_%]
```

### 5.5 Concentración geográfica

```DAX
Top3_States_Share =
VAR TopStates =
    TOPN( 3,
          SUMMARIZE( Customers, Customers[customer_state],
                     "n", [N_Orders] ),
          [n], DESC )
RETURN
    DIVIDE(
        SUMX( TopStates, [n] ),
        [N_Orders]
    )
```

### 5.6 Tasa de cancelación

```DAX
Cancel_Rate_% =
DIVIDE(
    CALCULATE( [N_Orders],
               FILTER( OrderItems, OrderItems[order_status] = "canceled" ) ),
    [N_Orders]
)
```

### 5.7 Formato sugerido

Todas las medidas terminadas en `_%` → formato `Porcentaje` con 1 decimal.
Las monetarias → formato `Moneda (R$)` con 0 decimales.
Las de tiempo → `Número` con 1 decimal y sufijo " d".

---

## 6. Diseño de las 3 páginas

> **Convención de coordenadas:** Power BI usa lienzo de 1280×720 px por
> defecto. Las coordenadas (x, y, w, h) están en píxeles.

### 6.1 Página 1 — **Resumen ejecutivo**

```
┌────────────────────────────────────────────────────────────┐
│  [Logo + Título]   "Olist Marketplace · Resumen ejecutivo" │
├────────┬────────┬────────┬────────┬────────┬────────┬──────┤
│ Órdenes│  GMV   │ Ticket │ CSAT % │ OTIF % │ Días   │ Top3 │   ← 7 KPI cards
│ 98 666 │ R$ 15M │ R$ 161 │ 77.6%  │ 91.9%  │ 12.6 d │ 66.6%│
├────────┴────────┴────────┴────────┼─────────────────────────┤
│ Volumen mensual de órdenes        │   Evolución del CSAT    │  ← 2 line charts
│  (line chart con marker)          │   (line chart + meta)   │
├──────────────────────────────────┴─────────────────────────┤
│ Slicers laterales: año · mes · estado · categoría           │
└─────────────────────────────────────────────────────────────┘
```

**Visuales a insertar (orden):**
1. **Tarjetas (Card)** — una por KPI, ancho 160 px. Usa formato condicional:
   - CSAT: verde si ≥ 80%, naranja si 70-80%, rojo si < 70%.
   - OTIF: verde si ≥ 95%, naranja 90-95%, rojo < 90%.
2. **Gráfico de líneas** — *N_Orders* en eje Y, `Date[year-month]` en X.
3. **Gráfico de líneas** — *CSAT_%* en eje Y, mismo X. Añadir línea
   constante = 0.80 (meta) con etiqueta "Meta 80%".

### 6.2 Página 2 — **Operación y Logística**

```
┌────────────────────────────────────────────────────────────┐
│   "Operación y Logística"                                  │
├──────────────────────────────────────┬─────────────────────┤
│  Mapa de Brasil — días por estado    │ OTIF gauge (95%)    │
│  (filled map, colorScale por días)   │ Tarjeta retrasos    │
├──────────────────────────────────────┼─────────────────────┤
│  Pareto de estados (% acumulado)     │ Box plot delivery × │
│  (combo chart bar + line)            │ review (small grid) │
└──────────────────────────────────────┴─────────────────────┘
```

**Visuales:**
1. **Filled Map** (visual *Map* de PBI). Ubicación → `customer_state`,
   gradiente → `Avg_Delivery_Days` (escala rojo→verde invertida).
2. **Gauge** con valor *OTIF_%*, max=1, meta=0.95.
3. **Combo bar+line** (Bar Chart con línea agregada). Eje X →
   `customer_state` ordenado descendente por `N_Orders`. Bar →
   `N_Orders`. Line → acumulado.
4. **Box Plot** (visual del marketplace, opcional). Si no está
   disponible, alternativa: tabla con percentiles agrupados por
   `is_positive_review`.

### 6.3 Página 3 — **Satisfacción**

```
┌────────────────────────────────────────────────────────────┐
│   "Satisfacción del cliente"                               │
├─────────────────────────────────────────┬──────────────────┤
│  Treemap categorías × volumen           │  CSAT por método │
│  (color por CSAT_%, tamaño por N_Orders)│  de pago         │
├─────────────────────────────────────────┼──────────────────┤
│  Heatmap categoría × estado (matriz con │ Tabla "órdenes   │
│  formato condicional)                   │ en riesgo"       │
└─────────────────────────────────────────┴──────────────────┘
```

**Visuales:**
1. **Treemap.** Categoría → `Products[product_category_name_english]`,
   detalle → `OrderItems[seller_state]`. Tamaño → `N_Orders`. Color →
   `CSAT_%`.
2. **Bar chart** vertical. Eje → `Payments[payment_type]`. Valor →
   `CSAT_%` (con etiqueta de N para evitar engañar con muestras chicas).
3. **Matrix** (no Table) con filas = categorías, columnas = estados,
   valor = `CSAT_%`. Activar *formato condicional → fondo* con gradiente
   rojo-amarillo-verde centrado en 77 (la media nacional).
4. **Tabla "Órdenes en riesgo".** Esta vista *se llena en la Fase 4*
   con el score del modelo predictivo; por ahora, mostrar las órdenes
   con `is_late = 1` y CSAT histórico < 60%.

---

## 7. Filtros e interactividad

**Slicers globales (visibles en toda página):**

- `Date[year]` — multi-selección, default 2017+2018.
- `Date[month]` — multi-selección, deshabilitar 2016 (apenas 326 órdenes).
- `Customers[customer_state]` — multi-selección, default todos.
- `Products[product_category_name_english]` — multi-selección, default todos.

**Edición de interacciones:**
- En la página 1, evita que el clic en *Volumen mensual* filtre el CSAT
  (queremos verlo en paralelo). *Formato → Editar interacciones → ningún
  filtro*.
- En la página 3, **sí permite** que el treemap filtre el heatmap (drill
  por categoría).

---

## 8. Drillthrough (opcional pero recomendado)

Crear una **página oculta** `Detail_Order` con:
- Encabezado: `order_id`, `customer_state`, `purchase_date`.
- Tabla con todos los ítems de la orden.
- Pago (método, cuotas, total).
- Reseña (score, comentario).

En la página de Satisfacción, sobre la tabla de "Órdenes en riesgo",
clic derecho → *Drillthrough → Detail_Order*.

---

## 9. Exportar a `.pbit` (plantilla) y `.pbix` (entregable)

1. **Archivo → Guardar como → `Olist_Dashboard.pbix`** en
   `BI_Dashboard/`.
2. **Archivo → Exportar → Plantilla de Power BI** →
   `Olist_Dashboard.pbit` (no contiene datos, solo el modelo y los
   visuales; útil para versionar en Git sin pesar 30 MB).

> El `.pbit` es un .zip estructurado; abriéndolo se solicitan las rutas
> de los CSVs (parámetros `RawDataPath`). Define el parámetro durante el
> diseño con:
>
> ```
> Inicio → Transformar datos → Administrar parámetros → Nuevo
> Nombre: RawDataPath  Tipo: Texto  Valor actual: C:\…\Data\processed\
> ```
>
> y reemplaza la ruta literal por el parámetro en *Origen* de cada
> consulta. Así el `.pbit` se puede compartir sin acoplarse a tu disco.

---

## 10. Checklist de entrega

- [ ] Las 8 tablas cargadas, sin errores ni filas perdidas.
- [ ] 7 relaciones del esquema estrella visibles y unidireccionales.
- [ ] Las 18 medidas DAX creadas dentro de `_Measures`.
- [ ] 3 páginas construidas con los visuales del manual.
- [ ] Paleta corporativa aplicada (tema personalizado o manual).
- [ ] Slicers globales sincronizados entre páginas.
- [ ] Drillthrough a `Detail_Order` (si optaste por incluirla).
- [ ] Archivos `.pbix` y `.pbit` exportados a `BI_Dashboard/`.
- [ ] Screenshots de cada página en `Notebooks/figures/pbi_pg{1,2,3}.png`
      para incrustarlos en el informe y la presentación.

---

## Anexo A — Tabla de equivalencias DAX ↔ Python (Pandas)

| Medida DAX | Equivalente Pandas (sobre `mart_orders`) |
|---|---|
| `CSAT_%`            | `mart["is_positive_review"].mean()` |
| `OTIF_%`            | `(mart.query("order_status=='delivered'")["is_late"]==0).mean()` |
| `Avg_Delivery_Days` | `mart.query("order_status=='delivered'")["delivery_days_real"].mean()` |
| `MoM_Growth_%`      | `mart.set_index("order_purchase_timestamp").resample("M").size().pct_change()` |
| `Top3_States_Share` | `mart["customer_state"].value_counts(normalize=True).head(3).sum()` |
| `GMV_Total`         | `mart["total_value"].sum()` |
| `Ticket_Promedio`   | `mart["total_value"].mean()` |

Esta correspondencia uno-a-uno permite **validar** los valores DAX en el
notebook de Fase 3 (sección 6) antes de mostrar el dashboard al jurado.

---

## Anexo B — Solución de errores frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| Las medidas devuelven `BLANK` | Falta de relación entre `OrderItems` y `Date` | Verificar relación con tipo `One to many` desde `Date[date]` |
| MoM_Growth_% siempre 0 | `Date` no marcada como tabla de fechas | *Datos → Marcar como tabla de fechas* |
| Los KPIs no coinciden con el notebook | El filtro `order_status=='delivered'` no se aplica | Asegúrate de filtrar dentro del `CALCULATE` o por filtro de página |
| Mapa de Brasil queda vacío | PBI no reconoce los estados | Cambia el tipo de dato de `customer_state` a *Categoría → Estado/provincia* y configura el país como `Brasil` en *Inicio → Editar consulta* |
| .pbit se rompe al abrir | Ruta del CSV codificada con disco local | Usa el parámetro `RawDataPath` descrito en la sección 9 |
