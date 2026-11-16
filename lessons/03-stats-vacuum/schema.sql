-- Урок 03. Лаборатория: статистика планировщика и VACUUM.
-- Идемпотентный скрипт: можно перепроливать сколько угодно раз.
-- Подключение: база lesson03

DROP TABLE IF EXISTS parcels CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id bigint PRIMARY KEY,
    full_name   text NOT NULL,
    city        text NOT NULL
);

INSERT INTO customers
SELECT
    g,
    'Customer ' || g,
    (ARRAY['Moscow', 'Saint Petersburg', 'Novosibirsk', 'Yekaterinburg',
           'Kazan', 'Omsk', 'Samara', 'Rostov-on-Don'])[1 + (g % 8)]
FROM generate_series(1, 5000) AS g;

ANALYZE customers;

CREATE TABLE parcels (
    parcel_id    bigint PRIMARY KEY,
    customer_id  bigint NOT NULL,
    status       text NOT NULL,
    destination  text NOT NULL,
    weight_kg    numeric(6,2) NOT NULL,
    created_at   timestamptz NOT NULL,
    delivered_at timestamptz,
    note         text
);

-- Для чистоты лаборатории autovacuum на этой таблице выключен.
-- В продакшене так делать нельзя: это только чтобы этапы были воспроизводимы.
ALTER TABLE parcels SET (autovacuum_enabled = false);

INSERT INTO parcels
SELECT
    g AS parcel_id,
    1 + (g % 5000) AS customer_id,
    CASE
        WHEN g % 1000 = 0 THEN 'failed'        -- 0.1%
        WHEN g % 100  = 0 THEN 'returned'      -- 0.9%
        WHEN g % 20   = 0 THEN 'in_transit'    -- 5%
        ELSE 'delivered'                       -- ~94%
    END,
    (ARRAY['Moscow', 'Saint Petersburg', 'Novosibirsk', 'Yekaterinburg',
           'Kazan', 'Omsk', 'Samara', 'Rostov-on-Don'])[1 + (g % 8)],
    round((0.1 + (g % 500) / 100.0)::numeric, 2),
    timestamptz '2026-01-01 00:00:00+00'
        + (g % 270) * interval '1 day'
        + (g % 86400) * interval '1 second',
    CASE
        WHEN g % 20 <> 0 THEN timestamptz '2026-01-02 00:00:00+00'
            + (g % 270) * interval '1 day'
        ELSE NULL
    END,
    repeat('x', 50 + (g % 100))
FROM generate_series(1, 300000) AS g;

CREATE INDEX parcels_status_idx ON parcels (status);
CREATE INDEX parcels_created_at_idx ON parcels (created_at);
CREATE INDEX parcels_customer_id_idx ON parcels (customer_id);

ANALYZE parcels;
