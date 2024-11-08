https://www.db-fiddle.com/f/4shGUK2zomNf8GzryVmwXZ/4

```sql
create table ranks(c varchar(10));

insert into ranks(c) values('A'),('A'),('B'),('B'),('B'),('C'),('E');

CREATE TABLE product_groups (
	group_id serial PRIMARY KEY,
	group_name VARCHAR (255) NOT NULL
);

CREATE TABLE sales(
	year SMALLINT CHECK(year > 0),
	group_id INT NOT NULL,
	amount DECIMAL(10,2) NOT NULL,
	PRIMARY KEY(year,group_id),
  	FOREIGN KEY (group_id) REFERENCES product_groups (group_id)
);

CREATE TABLE products (
	product_id serial PRIMARY KEY,
	product_name VARCHAR (255) NOT NULL,
	price DECIMAL (11, 2),
	group_id INT NOT NULL
);

INSERT INTO products (product_name, group_id,price)
VALUES
	('Microsoft Lumia', 1, 200),
	('HTC One', 1, 400),
	('Nexus', 1, 500),
	('iPhone', 1, 900),
	('HP Elite', 2, 1200),
	('Lenovo Thinkpad', 2, 700),
	('Sony VAIO', 2, 700),
	('Dell Vostro', 2, 800),
	('iPad', 3, 700),
	('Kindle Fire', 3, 150),
	('Samsung Galaxy Tab', 3, 200);

INSERT INTO product_groups (group_name)
VALUES
	('Smartphone'),
	('Laptop'),
	('Tablet');

INSERT INTO 
	sales(year, group_id, amount) 
VALUES
	(2018,1,1474),
	(2018,2,1787),
	(2018,3,1760),
	(2019,1,1915),
	(2019,2,1911),
	(2019,3,1118),
	(2020,1,1646),
	(2020,2,1975),
	(2020,3,1516);

select c, 
rank() over(order by c)  as rank_number ,
dense_rank() over(order by c)  as dense_rank_number
from ranks;

-- group_name, current_year, current_amount, prev_year_amount group by group_id, 

select pg.group_name, s.year,s.amount as current_amount,
LAG(s.amount, 1) over(partition by s.group_id order by s.year) as prev_year_amount
from sales s
join product_groups pg ON s.group_id = pg.group_id;

select pg.group_name, p.product_name, p.price,
avg(p.price) over(partition by p.group_id) as avg_price
from products p
join product_groups pg ON p.group_id = pg.group_id;
-- rank 1 - higher price, 100 - lower price (column price_rank)group by group_id
```
