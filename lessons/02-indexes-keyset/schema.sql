DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
    customer_id BIGINT PRIMARY KEY,
    full_name   TEXT NOT NULL,
    email       TEXT NOT NULL
);

CREATE TABLE orders (
    order_id     BIGINT PRIMARY KEY,
    customer_id  BIGINT NOT NULL REFERENCES customers (customer_id),
    status       TEXT NOT NULL,
    region       TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL,
    paid_at      TIMESTAMPTZ,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0)
);

CREATE TABLE order_items (
    order_id   BIGINT NOT NULL REFERENCES orders (order_id),
    line_no    INT NOT NULL,
    product_id BIGINT NOT NULL,
    qty        INT NOT NULL CHECK (qty > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, line_no)
);

INSERT INTO customers (customer_id, full_name, email)
SELECT i,
       'Клиент ' || i,
       'client' || i || '@shop.example'
FROM generate_series(1, 300) AS i;

INSERT INTO orders (order_id, customer_id, status, region, created_at, paid_at, total_amount)
SELECT i,
       1 + (i * 37) % 300,
       CASE
           WHEN i % 7 IN (0, 1, 2) THEN 'new'
           WHEN i % 7 IN (3, 4)    THEN 'paid'
           WHEN i % 7 = 5          THEN 'cancelled'
           ELSE                         'refunded'
       END,
       CASE
           WHEN i % 5 IN (0, 1) THEN 'EU'
           WHEN i % 5 = 2       THEN 'US'
           WHEN i % 5 = 3       THEN 'APAC'
           ELSE                      'LATAM'
       END,
       TIMESTAMPTZ '2026-06-01 00:00:00+00'
           + ((i::bigint * 7919) % 153) * INTERVAL '1 day'
           + ((i::bigint * 104729) % 86400) * INTERVAL '1 second',
       NULL,
       (((i::bigint * 7919) % 100000) / 100.0)::NUMERIC(12,2)
FROM generate_series(1, 50000) AS i;

UPDATE orders
SET paid_at = created_at + ((order_id % 5) + 1) * INTERVAL '1 day'
WHERE status = 'paid';

INSERT INTO order_items (order_id, line_no, product_id, qty, unit_price)
SELECT o.order_id,
       l.line_no,
       1 + (o.order_id * 131 + l.line_no * 17) % 500,
       1 + (o.order_id + l.line_no) % 5,
       (((o.order_id::bigint * 31 + l.line_no * 7) % 50000) / 100.0)::NUMERIC(12,2)
FROM orders AS o
CROSS JOIN LATERAL generate_series(1, 1 + (o.order_id % 4)::int) AS l(line_no);

ANALYZE customers;
ANALYZE orders;
ANALYZE order_items;
