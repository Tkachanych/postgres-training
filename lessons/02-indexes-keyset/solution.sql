EXPLAIN (ANALYZE, BUFFERS)
with cte as (
  select o.order_id 
       , o.created_at 
       , o.total_amount 
  from orders as o
 where o.region = 'EU'
   and o.created_at >= '2026-10-01 00:00:00 UTC'
   and o.created_at < '2026-11-01 00:00:00 UTC'
   and status in ('new', 'paid')
) select order_id, created_at, total_amount
    from cte
   where (total_amount, order_id) < (500.00, 30000)
   order by total_amount desc, order_id desc
limit 20;

drop index if exists idx_orders;
create index if not exists idx_orders 
on orders (total_amount desc, order_id desc)
include (created_at, region)
where status in ('new', 'paid')
;


analyze orders;

/* БЕЗ ИНДЕКСОВ
Limit  (cost=1961.93..1961.98 rows=20 width=22) (actual time=16.900..16.906 rows=20.00 loops=1)
  Buffers: shared hit=586
  ->  Sort  (cost=1961.93..1962.02 rows=36 width=22) (actual time=16.898..16.901 rows=20.00 loops=1)
        Sort Key: o.total_amount DESC, o.order_id DESC
        Sort Method: top-N heapsort  Memory: 27kB
        Buffers: shared hit=586
        ->  Seq Scan on orders o  (cost=0.00..1961.00 rows=36 width=22) (actual time=0.036..16.371 rows=1441.00 loops=1)
              Filter: ((status = ANY ('{new,paid}'::text[])) AND (region = 'EU'::text) AND (ROW(total_amount, order_id) < ROW(500.00, 30000)) AND (date_trunc('month'::text, (created_at AT TIME ZONE 'UTC'::text)) = '2026-10-01 00:00:00'::timestamp without time zone))
              Rows Removed by Filter: 48559
              Buffers: shared hit=586
Planning Time: 0.158 ms
Execution Time: 17.004 ms


-- С индексами
Limit  (cost=0.29..43.82 rows=20 width=22) (actual time=0.052..0.381 rows=20.00 loops=1)
  Buffers: shared hit=236
  ->  Index Scan using idx_orders on orders o  (cost=0.29..3143.00 rows=1444 width=22) (actual time=0.051..0.376 rows=20.00 loops=1)
        Index Cond: (ROW(total_amount, order_id) < ROW(500.00, 30000))
        Filter: ((created_at >= '2026-10-01 04:00:00+04'::timestamp with time zone) AND (created_at < '2026-11-01 04:00:00+04'::timestamp with time zone) AND (region = 'EU'::text))
        Rows Removed by Filter: 212
        Index Searches: 1
        Buffers: shared hit=236
Planning Time: 0.229 ms
Execution Time: 0.419 ms
 */