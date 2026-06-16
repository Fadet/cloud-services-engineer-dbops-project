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
