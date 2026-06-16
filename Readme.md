# dbops-project
Проектная работа дисциплины "DBOps".

## Подготовка базы данных

Создана отдельная база данных `store`:

```sql
CREATE DATABASE store;
```

Создан пользователь для запуска Flyway-миграций и автотестов:

```sql
CREATE USER dbops_user WITH PASSWORD 'dbops_password';
```

Пользователю выданы права на базу данных `store`:

```sql
GRANT ALL PRIVILEGES ON DATABASE store TO dbops_user;
```

Права на схему `public` в базе `store`:

```sql
\c store

GRANT ALL ON SCHEMA public TO dbops_user;
ALTER SCHEMA public OWNER TO dbops_user;
```

## Миграции

В директории `migrations` создана миграция `V001__create_tables.sql`. Она описывает исходную структуру таблиц:

- `product`;
- `product_info`;
- `orders`;
- `orders_date`;
- `order_product`.

Миграция запускается в GitHub Actions через Flyway перед автотестами.

## Нормализация

Таблицы `product` и `product_info` частично дублировали друг друга: обе хранили идентификатор и название товара. Для нормализации в таблицу `product` добавлено поле `price`, после чего таблица `product_info` удаляется.

Таблицы `orders` и `orders_date` также частично дублировали друг друга: обе хранили идентификатор и статус заказа. Для нормализации в таблицу `orders` добавлено поле `date_created`, после чего таблица `orders_date` удаляется.

Миграция `V002__change_schema.sql` изменяет структуру базы:

- добавляет `product.price`;
- добавляет `orders.date_created`;
- добавляет первичные ключи для `product` и `orders`;
- добавляет связи `order_product.order_id -> orders.id` и `order_product.product_id -> product.id`;
- удаляет неиспользуемые таблицы `product_info` и `orders_date`.

Миграция `V003__insert_data.sql` заполняет нормализованные таблицы тестовыми данными.

## Индексы

Для ускорения запроса по проданным сосискам за предыдущую неделю добавлена миграция `V004__create_index.sql`.

Она создает индексы:

- `idx_orders_status_date_created` для фильтрации заказов по статусу и дате;
- `idx_order_product_order_id` для соединения заказов с товарами в заказах.

## Запрос по продажам за предыдущую неделю

Количество проданных сосисок по дням за предыдущую неделю:

```sql
SELECT
    o.date_created,
    SUM(op.quantity) AS total_sausages_sold
FROM orders AS o
JOIN order_product AS op
    ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created
ORDER BY o.date_created;
```

## Время выполнения до создания индексов
Обычное выполнение запроса с включённым `\timing`:
```text
Time: 2752.548 ms
```
Фрагмент `EXPLAIN ANALYZE` до создания индексов:
```text
Parallel Hash Join
  Hash Cond: (op.order_id = o.id)
  -> Parallel Seq Scan on order_product op
  -> Parallel Hash
       -> Parallel Seq Scan on orders o
            Filter: ((status)::text = 'shipped'::text)
                    AND (date_created > (CURRENT_DATE - '7 days'::interval))

Planning Time: 1.233 ms
Execution Time: 2394.608 ms
```
До создания индексов PostgreSQL выполнял последовательное параллельное сканирование таблиц `orders` и `order_product`.

## Время выполнения после создания индексов
Обычное выполнение запроса с включённым `\timing`:
```text
Time: 1870.841 ms
```
Фрагмент `EXPLAIN ANALYZE` после создания индексов:

```text
Parallel Hash Join
  Hash Cond: (op.order_id = o.id)
  -> Parallel Seq Scan on order_product op
  -> Parallel Hash
       -> Parallel Bitmap Heap Scan on orders o
            Recheck Cond: ((status)::text = 'shipped'::text)
                          AND (date_created > (CURRENT_DATE - '7 days'::interval))
            -> Bitmap Index Scan on orders_status_date_idx
                 Index Cond: ((status)::text = 'shipped'::text)
                             AND (date_created > (CURRENT_DATE - '7 days'::interval))

Planning Time: 0.468 ms
Execution Time: 2472.232 ms
```
После создания индексов PostgreSQL начал использовать индекс `orders_status_date_idx` для отбора заказов по статусу и дате.

## Вывод
После создания индексов обычное время выполнения запроса сократилось с `2752.548 ms` до `1870.841 ms`, то есть примерно на `32%`.
При этом `EXPLAIN ANALYZE` показывает, что индекс `orders_status_date_idx` используется для фильтрации таблицы `orders`.
Таблица `order_product` всё ещё читается через `Parallel Seq Scan`, так как PostgreSQL выбирает параллельное сканирование большой таблицы как более выгодный план для данного объёма данных.
