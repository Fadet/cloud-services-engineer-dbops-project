INSERT INTO product (id, name, picture_url, price) VALUES
    (1, 'Сливочная', 'https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/6.jpg', 320.00),
    (2, 'Особая', 'https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/5.jpg', 179.00),
    (3, 'Молочная', 'https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/4.jpg', 225.00),
    (4, 'Нюренбергская', 'https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/3.jpg', 315.00),
    (5, 'Мюнхенская', 'https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/2.jpg', 330.00),
    (6, 'Русская', 'https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/1.jpg', 189.00);

INSERT INTO orders (id, status, date_created)
SELECT
    i,
    (array['pending', 'shipped', 'cancelled'])[floor(random() * 3 + 1)],
    DATE(NOW() - (random() * INTERVAL '90 days'))
FROM generate_series(1, 10000000) s(i);

INSERT INTO order_product (quantity, order_id, product_id)
SELECT
    floor(1 + random() * 50)::int,
    i,
    1 + floor(random() * 6)::int
FROM generate_series(1, 10000000) s(i);

SELECT setval(pg_get_serial_sequence('product', 'id'), (SELECT max(id) FROM product));

SELECT setval(pg_get_serial_sequence('orders', 'id'), (SELECT max(id) FROM orders));
