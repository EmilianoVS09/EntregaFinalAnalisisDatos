// ============================================================================
//   POWER QUERY — Cargadores parametrizados para Olist (modelo estrella)
//   Uso: en Power BI Desktop → Inicio → Transformar datos → Editor avanzado
//        pegar cada bloque en una consulta nueva (nombre indicado en cabecera).
//   Primero crea el parámetro RawDataPath:
//        Inicio → Transformar datos → Administrar parámetros → Nuevo
//          Nombre   : RawDataPath
//          Tipo     : Texto
//          Sugerido : Cualquier valor
//          Valor    : C:\...\EntregaFinalAnalisisDatos\Data\processed\
// ============================================================================

// ---- Parámetro RawDataPath ------------------------------------------------
// (Crear desde la UI, no como código. Aquí solo a modo de recordatorio.)
//   RawDataPath = "C:\Users\<usuario>\Desktop\...\Data\processed\";

// ============================================================================
//  Customers  (file: dim_customers.csv)
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "dim_customers.csv"),
        [Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"customer_id",              type text},
        {"customer_unique_id",       type text},
        {"customer_zip_code_prefix", type text},
        {"customer_city",            type text},
        {"customer_state",           type text}
    })
in
    Tipos

// ============================================================================
//  Sellers  (file: dim_sellers.csv)
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "dim_sellers.csv"),
        [Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"seller_id",              type text},
        {"seller_zip_code_prefix", type text},
        {"seller_city",            type text},
        {"seller_state",           type text}
    })
in
    Tipos

// ============================================================================
//  Products  (file: dim_products.csv)
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "dim_products.csv"),
        [Delimiter=",", Columns=10, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"product_id",                     type text},
        {"product_category_name",          type text},
        {"product_name_lenght",            Int64.Type},
        {"product_description_lenght",     Int64.Type},
        {"product_photos_qty",             Int64.Type},
        {"product_weight_g",               type number},
        {"product_length_cm",              type number},
        {"product_height_cm",              type number},
        {"product_width_cm",               type number},
        {"product_category_name_english",  type text}
    })
in
    Tipos

// ============================================================================
//  Geography  (file: dim_geography.csv)
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "dim_geography.csv"),
        [Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"geolocation_zip_code_prefix", type text},
        {"geolocation_lat",             type number},
        {"geolocation_lng",             type number},
        {"geolocation_city",            type text},
        {"geolocation_state",           type text}
    })
in
    Tipos

// ============================================================================
//  Date  (file: dim_date.csv)  → marcar como tabla de fechas tras cargar
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "dim_date.csv"),
        [Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"date",        type date},
        {"year",        Int64.Type},
        {"quarter",     Int64.Type},
        {"month",       Int64.Type},
        {"month_name",  type text},
        {"week",        Int64.Type},
        {"day",         Int64.Type},
        {"day_of_week", Int64.Type},
        {"is_weekend",  Int64.Type}
    })
in
    Tipos

// ============================================================================
//  Reviews  (file: dim_reviews.csv)
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "dim_reviews.csv"),
        [Delimiter=",", Columns=8, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"review_id",               type text},
        {"order_id",                type text},
        {"review_score",            Int64.Type},
        {"review_comment_title",    type text},
        {"review_comment_message",  type text},
        {"review_creation_date",    type datetime},
        {"review_answer_timestamp", type datetime},
        {"is_positive_review",      Int64.Type}
    })
in
    Tipos

// ============================================================================
//  OrderItems  (file: fact_order_items.csv)  ← tabla de hechos
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "fact_order_items.csv"),
        [Delimiter=",", Columns=15, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"order_id",                       type text},
        {"order_item_id",                  Int64.Type},
        {"product_id",                     type text},
        {"seller_id",                      type text},
        {"shipping_limit_date",            type datetime},
        {"price",                          type number},
        {"freight_value",                  type number},
        {"total_item_value",               type number},
        {"customer_id",                    type text},
        {"order_status",                   type text},
        {"order_purchase_timestamp",       type datetime},
        {"order_delivered_customer_date",  type datetime},
        {"delivery_days_real",             type number},
        {"delivery_delay_days",            type number},
        {"is_late",                        Int64.Type}
    })
in
    Tipos

// ============================================================================
//  Payments  (file: fact_payments.csv)  ← tabla de hechos
// ============================================================================
let
    Origen = Csv.Document(
        File.Contents(RawDataPath & "fact_payments.csv"),
        [Delimiter=",", Columns=5, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"order_id",             type text},
        {"payment_sequential",   Int64.Type},
        {"payment_type",         type text},
        {"payment_installments", Int64.Type},
        {"payment_value",        type number}
    })
in
    Tipos
