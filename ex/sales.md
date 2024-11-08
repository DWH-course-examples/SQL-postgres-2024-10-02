## DDL

```sql
create table meas_units(
	id Serial Primary Key,
  	name VarChar(256) NOT NULL
);

create table products(
	id Serial Primary Key,
	name varchar(50),	
	is_product boolean NOT NULL,
  	amount int,
  	price decimal,
  	photo_url varchar(255),
  	meas_unit_id int,
  	parent_id int,
  	sum_cost decimal,
  	constraint fk_meas_unit foreign key (meas_unit_id) references meas_units(id),
  	CONSTRAINT FK_Parent FOREIGN KEY(parent_id) references products(id)
);

create table price_history(
	id Serial Primary Key,
  	product_id int,
  	price decimal,
  	date_start timestamp,
  	date_end timestamp,
  	FOREIGN KEY(product_id) references products(id)
);

create table organizations(
	id Serial Primary Key,
  	name text,
  	address text,
  	phone varchar(100)
);

create table invoices(
	id Serial Primary Key,
  	numb int,
  	date_in timestamp,
  	org_id int,
  	in_out char,
  	sum_invoice decimal,
    FOREIGN KEY(org_id) references organizations(id)
);

create table product_to_invoices(
	id Serial Primary Key,
  	product_id int,
  	invoice_id int,
  	amount int,
  	price decimal,
  FOREIGN KEY(product_id) references products(id),
  FOREIGN KEY(invoice_id) references invoices(id)
);
```

Insert data:

```sql
insert into meas_units(name) values ('шт'), ('набор'), ('кг'), ('литр'), ('пуд');

insert into organizations(name, address, phone) 
values ('ООО Рога и Копыта', 'Москва, улица Пушкина', '12345678'),
('Дружба народов', 'Владивосток, ул Пушкинская', '89171201516');

INSERT INTO Organizations(Name, Address, Phone) 
VALUES ('Мультисистемы','Москва,Ходынский б-р, 9','8 (495) 555-43-21'), 
	   ('Инфосистемы','Воронеж, Бульвар Победы, д. 48а, оф. 10','8 (473) 555-43-21'),
       ('Копирайты', 'Находка, пр-кт Восточный, д. 5', '8(432)296-61-48');
       
insert into Organizations(name, address, phone) 
values ('ООО Рога и Копыта_2', 'Ставрополь, улица Мира_2', '00012345678-2');     

INSERT INTO Invoices(Date_IN, Numb, Org_ID, In_Out, Sum_invoice) 
VALUES ('2024-10-11 11:20:00',1,2,'i',100000);  
INSERT INTO Invoices(Date_IN, Numb, Org_ID, In_Out, Sum_invoice) 
VALUES ('2023-10-11 11:20:00',12,2,'i',100000);  
INSERT INTO Invoices(Date_IN, Numb, Org_ID, In_Out, Sum_invoice) 
VALUES ('2024-10-14 11:21:33',9,1,'i',33000);
INSERT INTO Invoices(Date_IN, Numb, Org_ID, In_Out, Sum_invoice) 
VALUES ('2023-09-10 10:21:33',5,2,'i',50000);

INSERT INTO Products(Name, Is_product, Amount, Price, Photo_url ,Meas_Unit_ID,  Sum_Cost) 
VALUES ('Inspark ITSM',TRUE,1,100000,'https://274418.selcdn.ru/cv08300-33250f0d-0664-43fc-9dbf-9d89738d114e/uploads/255954/6c70c5c8-a086-42e5-9368-b98c0ccc0846.png', 1, 1*100000),
('Collaboration',TRUE,1,600,'https://i.pinimg.com/originals/35/9a/f9/359af9812082a927e11cb9112bcd48da.jpg', 1, 1*200),
('Workstation',TRUE,1,50000,'https://habrastorage.org/getpro/geektimes/post_images/753/0b5/e42/7530b5e4214972747e6552c66040cb87.jpg', 1, 1*1000);

insert into price_history(product_id,price,date_start,date_end)
values
(1,100,'2024-01-01','2024-03-01'),
(1,120,'2024-03-01','2024-06-01'),
(1,140,'2024-06-01','2024-09-01'),
(1,200,'2024-09-01','2024-12-01');

INSERT INTO product_to_invoices(Invoice_ID, product_id, Amount, Price)
VALUES (1,1,3,100000);  
INSERT INTO product_to_invoices(Invoice_ID, product_id, Amount, Price)
VALUES (2,1,3,100000);  
INSERT INTO product_to_invoices(Invoice_ID, product_id, Amount, Price)
VALUES (3, 1,1,200000);  
```

## Views and select

```sql
create or replace view v_org_products as
SELECT products.name, products.is_product, products.Parent_ID 
FROM products 
WHERE products.id in
    (SELECT product_to_invoices.product_id
     FROM product_to_invoices, invoices
     WHERE product_to_invoices.invoice_id = invoices.id
       and  invoices.org_id=1);
       

INSERT INTO Products(Name, Is_product, Amount, Price, Photo_url ,Meas_Unit_ID,  Sum_Cost) 
VALUES ('Inspark ITSM',TRUE,0,100000,'https://274418.selcdn.ru/cv08300-33250f0d-0664-43fc-9dbf-9d89738d114e/uploads/255954/6c70c5c8-a086-42e5-9368-b98c0ccc0846.png', 1, 1*100000);

--inirbyf_select * from products;
select * from invoices;
select * from product_to_invoices;

-- показать список организаций  (названия) покупавших определенный товар (Inspark ITSM)

select distinct organizations.name 
from organizations, products, invoices, product_to_invoices
where products.name = 'Inspark ITSM'
and organizations.id = invoices.org_id
and product_to_invoices.invoice_id = invoices.id
and product_to_invoices.product_id = products.id;


select * from v_org_products;

select distinct o.name 
from organizations o
inner join invoices i ON  o.id = i.org_id
inner join product_to_invoices pti ON  i.id = pti.invoice_id
inner join products p ON  p.id = pti.product_id
where p.name = 'Inspark ITSM';

-- Получить список накладных на поступление товаров от организаций, расположенных на улице Пушкина с 1 января 2024г
SELECT invoices.*, o.Name, Address
FROM invoices, Organizations o
WHERE invoices.Org_ID=o.ID 
  and o.Address like '%Пушкина%'
  and invoices.In_Out='in'
  and invoices.date_in > '2024-01-01'
ORDER BY o.name;

--На какую сумму организации приобрели  товары по годам?

select o.Name, date_part('year', i.Date_in) as "Год", sum(pti.Amount*pti.Price) as "Сумма"
from organizations o
inner join invoices i ON i.org_id = o.id
inner join product_to_invoices pti ON pti.invoice_id = i.id

--Получить суммы закупок организаций по месяцам 2024г.  для организаций, для которых сумма закупок превысила 1000 р. Результатом должна явиться таблица с полями Организация, Месяц, Сумма закупок.
where i.In_Out='i'
group by o.name, date_part('year', i.Date_in)
order by O.Name, date_part('year', i.Date_in);

select o.Name, date_part('month', i.Date_in) as "Месяц", sum(i.sum_invoice) as "Сумма"
from organizations o
inner join invoices i ON i.org_id = o.id
where i.In_Out='i'
group by o.name,date_part('month', i.Date_in)
having sum(i.sum_invoice) > 1000;
```

## UDF and triggers

```sql
create procedure delzero()
language sql as $$
delete from products where amount = 0 and is_product;
$$;

CREATE FUNCTION calc_product_price(p_id int, date_in timestamp) 
RETURNS numeric(10,3) 
AS $$
DECLARE
	cur_price decimal;
BEGIN
	RETURN (select ph.price from price_history ph 
    join products p on ph.product_id = p.id 
    where p.id = p_id AND date_in between ph.date_start AND ph.date_end);
END;
$$ LANGUAGE plpgsql;

-- создаём пользовательскую функцию
CREATE FUNCTION addPriceHistory() 
RETURNS TRIGGER AS $$
BEGIN
	IF TG_OP='INSERT' THEN
    	update price_history set date_end = now() 
        where date_end = '2099-12-31' and prouvt_id = new.id;
    	insert into price_history(product_id,price,date_start,date_end)
		values (new.id,new.price,now(),'2099-12-31');
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

-- создаём триггер
CREATE TRIGGER tg_update_price_history AFTER INSERT -- OR UPDATE OR DELETE
ON products FOR EACH ROW
EXECUTE PROCEDURE addPriceHistory();

INSERT INTO Products(Name, Is_product, Amount, Price, Photo_url ,Meas_Unit_ID,  Sum_Cost) 
VALUES ('Inspark ITSM',TRUE,0,100000,'https://274418.selcdn.ru/cv08300-33250f0d-0664-43fc-9dbf-9d89738d114e/uploads/255954/6c70c5c8-a086-42e5-9368-b98c0ccc0846.png', 1, 1*100000);


call delzero();

select *from products;

select calc_product_price(1, '2024-10-11 11:20:00')
```

