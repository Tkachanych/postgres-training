# Урок 03. Статистика планировщика и VACUUM: лаборатория

## Цель

Увидеть на реальных данных, как устаревшая статистика меняет план, зачем нужен
`ANALYZE`, как `VACUUM` влияет на visibility map и index-only scan, и почему
размер таблицы после `VACUUM` не уменьшается.

Работаем этапами: этот файл будет дополняться по мере прохождения.

## Подготовка

Подключись к `lesson03` в DBeaver по [инструкции проекта](../../README.md).
Чтобы начать лабораторию заново, выполни `schema.sql` как SQL-скрипт в этой базе.
Он пересоздаёт таблицы `parcels` и `customers`.

Важно: на таблице `parcels` **намеренно выключен autovacuum** — чтобы этапы
были воспроизводимы. В продакшене так делать нельзя. Все действия с
`ANALYZE`/`VACUUM` на этой таблице выполняем руками.

## Этап 1. Снять baseline

Запиши в `solution.sql` SQL-запросы, которые показывают:

1. Размер таблицы `parcels`: heap, индексы, total (в удобном виде, например через
   `pg_size_pretty`).
2. Состояние статистики и vacuum из `pg_stat_user_tables`:
   `n_live_tup`, `n_dead_tup`, `n_mod_since_analyze`, `last_analyze`,
   `last_autoanalyze`, `vacuum_count`, `autovacuum_count`.
3. Содержимое `pg_stats` для колонки `status`: `null_frac`, `n_distinct`,
   `most_common_vals`, `most_common_freqs`, `correlation`.
4. Оценку числа строк планировщиком (`pg_class.reltuples`) и фактическое число
   строк (`count(*)`).
5. `EXPLAIN (ANALYZE, BUFFERS)` для запроса:

```sql
SELECT count(*) FROM parcels WHERE status = 'failed';
```

Ограничения этапа:

- только чтение (`SELECT`, `EXPLAIN`); никаких `INSERT`/`UPDATE`/`DELETE`,
  `ANALYZE` и `VACUUM`;
- в `solution.sql` должны быть именно SQL-запросы, а не `\d+` из psql;
- для плана используй `EXPLAIN (ANALYZE, BUFFERS)`.

### Ожидаемый результат

Ориентиры (точные значения `most_common_freqs` могут немного отличаться из-за
выборки `ANALYZE`):

| Показатель | Ожидание |
|---|---|
| heap | ~56 MB |
| индексы | ~15 MB |
| total | ~70 MB |
| `n_live_tup` | 300000 |
| `n_dead_tup` | 0 |
| `n_mod_since_analyze` | Обычно 0. Если загрузка данных и `ANALYZE` прошли в одной транзакции, счётчик может включать 300000 вставок |
| `last_analyze` | заполнен |
| `last_autoanalyze` | NULL |
| `n_distinct` для `status` | 4 |
| `most_common_vals` | `{delivered,in_transit,returned,failed}` |
| `delivered` | ~0.95 |
| `in_transit` | ~0.039 |
| `returned` | ~0.009 |
| `failed` | ~0.0012 |
| `reltuples` | 300000 |
| фактическое `count(*)` | 300000 |

План для `count(*) ... WHERE status = 'failed'`:

- `Index Only Scan using parcels_status_idx`;
- оценка `rows` порядка 300 и зависит от выборки `ANALYZE`, факт `rows` = 300;
- **`Heap Fetches: 300`**;
- время порядка 1 мс.

### Дополнительный вопрос уровня Middle+

Почему при свежей статистике и только что созданном индексе план показывает
`Heap Fetches: 300`, а не `0`? Что должно произойти с таблицей, чтобы стало `0`,
и почему?

## Что прислать

1. `solution.sql` с запросами этапа 1.
2. Краткий отчёт: какие значения получились, совпала ли оценка с фактом,
   какой план выбрал планировщик.
3. Ответ на дополнительный вопрос в [theory-answers.md](theory-answers.md).

После проверки выдам этап 2.
