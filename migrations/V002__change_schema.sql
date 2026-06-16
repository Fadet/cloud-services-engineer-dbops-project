ALTER TABLE product
    ADD COLUMN price double precision;

ALTER TABLE orders
    ADD COLUMN date_created date DEFAULT current_date;

ALTER TABLE product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);

ALTER TABLE orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);

ALTER TABLE order_product
    ADD CONSTRAINT order_product_pkey PRIMARY KEY (order_id, product_id),
    ADD CONSTRAINT order_product_order_fk
        FOREIGN KEY (order_id) REFERENCES orders (id),
    ADD CONSTRAINT order_product_product_fk
        FOREIGN KEY (product_id) REFERENCES product (id);

DROP TABLE product_info;

DROP TABLE orders_date;

