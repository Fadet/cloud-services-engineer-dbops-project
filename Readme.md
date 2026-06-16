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
