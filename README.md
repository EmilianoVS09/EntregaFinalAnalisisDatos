# EntregaFinalAnalisisDatos

**Proyecto:** Desarrollo de un Proyecto de Análisis de Datos y Modelo Predictivo para una Aplicación de Negocio
**Caso de estudio:** *Brazilian E-Commerce Public Dataset by Olist* (98 666 órdenes · 2017-2018)
**Autores:** Carlos Alberto Moreno David · Juan Esteban García Ocampo · Emiliano Vélez Suárez · Sebastián Ciro Medellín
**Institución:** ITM · Mayo 2026
**Asignaturas integradas:** Inteligencia de Negocios · Analítica de Datos · Aprendizaje Computacional

---

## Resumen

Solución analítica *end-to-end* sobre el marketplace brasileño Olist. El proyecto
identifica y caracteriza los factores que más influyen en la satisfacción del
cliente (medida por la reseña ≥ 4 estrellas), construye un dashboard en Power BI
para monitorearlos y entrena un clasificador binario (XGBoost) para anticipar
qué órdenes activas terminarán con reseña negativa, permitiendo intervención
preventiva.

### Resultados clave

| Indicador | Valor | Comentario |
|---|---|---|
| CSAT actual | **77.6 %** | Meta 80 % · brecha −2.4 p.p. |
| OTIF (% entregas a tiempo) | **91.9 %** | Meta ≥ 95 % · brecha −3.1 p.p. |
| Concentración top-3 estados | **66.6 %** | Riesgo · objetivo ≤ 50 % |
| Modelo XGBoost · ROC-AUC test | **0.705** | Baseline 0.500 |
| Modelo XGBoost · F1 test | **0.837** | |
| Impacto CSAT esperado (12 meses) | **+3.7 a +4.7 p.p.** | Lleva CSAT a ~82 % |

---

## Estructura del repositorio

```
EntregaFinalAnalisisDatos/
├── Data/
│   ├── olist_*.csv                       (9 archivos crudos)
│   ├── product_category_name_translation.csv
│   └── processed/                        (modelo dimensional estrella)
│       ├── dim_customers.csv             (99 441 filas)
│       ├── dim_sellers.csv               (3 095 filas)
│       ├── dim_products.csv              (32 951 filas)
│       ├── dim_geography.csv             (19 015 filas)
│       ├── dim_date.csv                  (774 filas)
│       ├── dim_reviews.csv               (98 673 filas)
│       ├── fact_order_items.csv          (112 650 filas) ← HECHO 1
│       ├── fact_payments.csv             (103 886 filas) ← HECHO 2
│       └── marts/mart_orders.csv         (98 666 × 31 — tabla denormalizada)
│
├── Notebooks/
│   ├── Fase1_Identificacion_Fuentes_Datos.ipynb   ← evaluación de 5 datasets
│   ├── Fase1_ETL.ipynb                            ← pipeline ETL completo
│   ├── Fase2_EDA.ipynb                            ← KPIs, hipótesis stats, outliers
│   ├── Fase3_BI.ipynb                             ← modelo dimensional + KPIs DAX
│   ├── Fase4_Modelado.ipynb                       ← comparación 4 modelos + XGBoost
│   ├── Fase5_Conclusiones.ipynb                   ← recomendaciones de negocio
│   └── figures/                                   ← visualizaciones (.png)
│       └── fase4/                                 ← gráficos del modelo
│
├── BI_Dashboard/
│   ├── Manual_PowerBI.md                          ← guía paso a paso (30-40 min)
│   ├── PowerQuery_Loaders.m                       ← consultas M para 8 tablas
│   ├── DAX_Measures.dax                           ← 30+ medidas DAX
│   ├── Olist_Dashboard.html                       ← dashboard HTML espejo (Plan B)
│   └── PBI.pbix                                   ← (a construir en Power BI Desktop)
│
├── Models/
│   ├── xgb_positive_review.joblib                 ← modelo serializado
│   ├── cv_results.csv                             ← métricas por modelo (CV)
│   ├── metrics_final.json                         ← métricas finales del XGBoost
│   ├── permutation_importance.csv                 ← importancia de features
│   └── orders_at_risk_top50.csv                   ← top 50 órdenes para PN10
│
└── Documents/
    ├── Informe_Final.docx                         ← informe técnico ~30 páginas
    └── Sustentacion.pptx                          ← presentación 17 slides
```

---

## Las 5 fases en una mirada

| Fase | Notebook | Entregables clave |
|---|---|---|
| **1. Recopilación + ETL** | `Fase1_*.ipynb` | Matriz de selección · pipeline ETL · 12/12 validaciones · esquema estrella |
| **2. EDA** | `Fase2_EDA.ipynb` | 8 KPIs · 5 hipótesis estadísticas (todas rechazadas) · plan de outliers |
| **3. BI** | `Fase3_BI.ipynb` | Dashboard PBI 3 páginas · 30+ medidas DAX · HTML espejo |
| **4. Modelado** | `Fase4_Modelado.ipynb` | Baseline + LogReg + RF + XGBoost · AUC 0.705 · permutation importance |
| **5. Conclusiones** | `Fase5_Conclusiones.ipynb` | 7 recomendaciones · hoja de ruta 90/180/365 d |

---

## Cómo reproducir el proyecto

### 1. Requisitos

```bash
python >= 3.10
pip install pandas numpy scikit-learn xgboost matplotlib seaborn scipy joblib nbformat openpyxl python-docx python-pptx
```

Para el dashboard Power BI: **Power BI Desktop** (Windows, gratis en Microsoft Store).

### 2. Ejecución secuencial

```bash
# Desde la raíz del proyecto
jupyter notebook Notebooks/Fase1_Identificacion_Fuentes_Datos.ipynb
jupyter notebook Notebooks/Fase1_ETL.ipynb       # genera Data/processed/
jupyter notebook Notebooks/Fase2_EDA.ipynb       # análisis exploratorio
jupyter notebook Notebooks/Fase3_BI.ipynb        # modelo BI + KPIs
jupyter notebook Notebooks/Fase4_Modelado.ipynb  # entrena XGBoost (~30 s)
jupyter notebook Notebooks/Fase5_Conclusiones.ipynb
```

### 3. Construir el dashboard Power BI

Seguir [`BI_Dashboard/Manual_PowerBI.md`](BI_Dashboard/Manual_PowerBI.md) (~30 min):

1. Crear parámetro `RawDataPath` con la ruta a `Data/processed/`.
2. Cargar las 8 tablas con [`PowerQuery_Loaders.m`](BI_Dashboard/PowerQuery_Loaders.m).
3. Crear las relaciones del esquema estrella.
4. Pegar las medidas de [`DAX_Measures.dax`](BI_Dashboard/DAX_Measures.dax).
5. Construir las 3 páginas según el manual.

Como Plan B (sin Power BI Desktop), abrir directamente
[`BI_Dashboard/Olist_Dashboard.html`](BI_Dashboard/Olist_Dashboard.html) en
cualquier navegador.

---

## Cobertura de la rúbrica

| Bloque de la rúbrica (guía PDF) | Cubierto en | Estado |
|---|---|---|
| 1. **Recopilación y Transformación de Datos** — Identificación de fuentes | Fase 1.1 (5 datasets evaluados, matriz ponderada) | ✓ |
| 1. **Recopilación y Transformación de Datos** — ETL | Fase 1.2 (pipeline + 12/12 validaciones) | ✓ |
| 2. **EDA** — Limpieza y análisis preliminar | Fase 2 (KPIs + outliers + univariante) | ✓ |
| 2. **EDA** — Visualización de tendencias y correlaciones | Fase 2 (8 visuals + PCA + heatmaps) | ✓ |
| 3. **BI** — Modelo de datos para extraer insights | Fase 3 (esquema estrella + reglas de negocio RB1-RB10) | ✓ |
| 3. **BI** — Dashboard | `Olist_Dashboard.html` + Manual `.pbix` | ✓ |
| 4. **ML** — Modelo de aprendizaje supervisado | Fase 4 (4 modelos comparados, XGBoost final) | ✓ |
| 4. **ML** — Evaluación con métricas | Accuracy, F1, ROC-AUC, PR-AUC, matriz, ROC/PR | ✓ |
| 5. **Conclusiones y Recomendaciones** | Fase 5 (7 recomendaciones, hoja de ruta) | ✓ |
| **Entregable**: Notebook de Python | 6 notebooks (5 fases + 1 ID fuentes) | ✓ |
| **Entregable**: Documento formal | `Documents/Informe_Final.docx` | ✓ |
| **Entregable**: Dashboard BI | `BI_Dashboard/Olist_Dashboard.html` + manual PBI | ✓ |
| **Entregable**: Presentación | `Documents/Sustentacion.pptx` (17 slides) | ✓ |

---

## Conceptos clave del proyecto

- **Modelo dimensional estrella** — 6 dimensiones + 2 hechos · grano por ítem/orden.
- **Reglas de negocio formalizadas** — 10 reglas (RB1-RB10) que definen
  operacionalmente cada KPI y que son aplicadas idénticamente en Pandas, DAX y ML.
- **5 hipótesis estadísticas** — todas rechazadas con α = 0.05; logística, pago y
  geografía SÍ son drivers reales.
- **Plan de outliers** — documentado en Fase 2 (sección 12.3), aplicado
  reproduciblemente en Fase 4.
- **Permutation importance** — métrica de interpretabilidad modelo-agnóstica;
  reemplaza SHAP por incompatibilidad con XGBoost 3.x.
- **Validación cruzada estratificada** — 3-fold, comparando 4 familias de modelos.

---

## Limitaciones declaradas

- Datos cerrados en 2018 (pre-pandemia).
- Sin contenido textual de las reseñas (NLP fuera de alcance).
- AUC = 0.70: razonable pero no excelente; gran parte de la insatisfacción del
  cliente sigue siendo *no observable* al cierre de la orden.
- Validación con split aleatorio (no temporal). Para producción, validar forward.
- Sin experimento A/B; las recomendaciones son observacionales.

---

## Licencia y créditos

- **Dataset**: Olist Brazilian E-Commerce, licencia CC BY-NC-SA 4.0. Uso
  **académico no comercial**.
- **Código**: para fines educativos.
- **Bibliografía clave**: Chen & Guestrin (XGBoost), Pedregosa et al.
  (scikit-learn), Kimball & Ross (Data Warehouse Toolkit), Lundberg & Lee (SHAP).
