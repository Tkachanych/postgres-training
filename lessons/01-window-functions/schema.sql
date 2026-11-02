DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

CREATE TABLE accounts (
    account_id BIGINT PRIMARY KEY,
    holder_name TEXT NOT NULL
);

CREATE TABLE transactions (
    tx_id BIGINT PRIMARY KEY,
    account_id BIGINT NOT NULL,
    tx_dt DATE NOT NULL,
    amount NUMERIC(14,2) NOT NULL,
    status TEXT NOT NULL
);

INSERT INTO accounts VALUES
(1, 'Иванов'),
(2, 'Петрова'),
(3, 'Сидоров'),
(4, 'Кузнецов'),
(5, 'Смирнова');

INSERT INTO transactions VALUES
(1001, 1, '2026-11-01',  5000.00, 'posted'),
(1002, 1, '2026-11-01', -1200.00, 'posted'),
(1003, 1, '2026-11-03',  2000.00, 'posted'),
(1004, 1, '2026-11-05',  -500.00, 'posted'),
(1005, 1, '2026-11-06',  9999.00, 'declined'),
(1006, 2, '2026-11-02',  1500.00, 'posted'),
(1007, 2, '2026-11-04', -1500.00, 'posted'),
(1008, 3, '2026-11-01',  1000.00, 'posted'),
(1009, 3, '2026-11-01',  1000.00, 'posted'),
(1010, 3, '2026-11-02',  2000.00, 'posted'),
(1011, 3, '2026-11-03',  -500.00, 'posted'),
(1012, 4, '2026-11-01',  4000.00, 'declined');

ANALYZE accounts;
ANALYZE transactions;
