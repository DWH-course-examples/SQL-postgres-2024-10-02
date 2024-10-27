## TPC-H transactions database

## Prepare DB: Generate data with DBGen

```bash
sudo apt-get install -y gcc git awscli postgresql # install libs

git clone https://github.com/electrum/tpch-dbgen.git # TPCH generator
cd tpch-dbgen
make makefile.suite

./dbgen -v -h -s 10 # generate data

for i in `ls *.tbl`; do sed 's/|$//' $i > ${i/tbl/csv}; echo $i; done; # convert to a CSV format compatible with PostgreSQL
```

Read more at:
- https://github.com/RunningJon/TPC-H
- https://github.com/wangguoke/blog/blob/master/How%20to%20use%20the%20pg_tpch.md

## DDL

```sql
CREATE TABLE nation(
      N_NATIONKEY INTEGER, 
      N_NAME CHAR(25), 
      N_REGIONKEY INTEGER, 
      N_COMMENT VARCHAR(152),
      dummy text);
ALTER TABLE nation ADD PRIMARY KEY (n_nationkey);

CREATE TABLE customer(
      C_CUSTKEY INT, 
      C_NAME VARCHAR(25),
      C_ADDRESS VARCHAR(40),
      C_NATIONKEY INTEGER,
      C_PHONE CHAR(15),
      C_ACCTBAL DECIMAL(15,2),
      C_MKTSEGMENT CHAR(10),
      C_COMMENT VARCHAR(117),
      dummy text);
ALTER TABLE customer ADD PRIMARY KEY (c_custkey);

CREATE TABLE lineitem(
      L_ORDERKEY BIGINT,
      L_PARTKEY INT,
      L_SUPPKEY INT,
      L_LINENUMBER INTEGER,
      L_QUANTITY DECIMAL(15,2),
      L_EXTENDEDPRICE DECIMAL(15,2),
      L_DISCOUNT DECIMAL(15,2),
      L_TAX DECIMAL(15,2),
      L_RETURNFLAG CHAR(1),
      L_LINESTATUS CHAR(1),
      L_SHIPDATE DATE,
      L_COMMITDATE DATE,
      L_RECEIPTDATE DATE,
      L_SHIPINSTRUCT CHAR(25),
      L_SHIPMODE CHAR(10),
      L_COMMENT VARCHAR(44),
      dummy text);
ALTER TABLE lineitem ADD PRIMARY KEY (l_orderkey, l_linenumber);

CREATE TABLE orders(
      O_ORDERKEY BIGINT,
      O_CUSTKEY INT,
      O_ORDERSTATUS CHAR(1),
      O_TOTALPRICE DECIMAL(15,2),
      O_ORDERDATE DATE,
      O_ORDERPRIORITY CHAR(15), 
      O_CLERK  CHAR(15), 
      O_SHIPPRIORITY INTEGER,
      O_COMMENT VARCHAR(79),
      dummy text);
ALTER TABLE orders ADD PRIMARY KEY (o_orderkey);

CREATE TABLE partsupp(
      PS_PARTKEY INT,
      PS_SUPPKEY INT,
      PS_AVAILQTY INTEGER,
      PS_SUPPLYCOST DECIMAL(15,2),
      PS_COMMENT VARCHAR(199),
      dummy text);
ALTER TABLE partsupp ADD PRIMARY KEY (ps_partkey, ps_suppkey);

CREATE TABLE part(
      P_PARTKEY INT,
      P_NAME VARCHAR(55),
      P_MFGR CHAR(25),
      P_BRAND CHAR(10),
      P_TYPE VARCHAR(25),
      P_SIZE INTEGER,
      P_CONTAINER CHAR(10),
      P_RETAILPRICE DECIMAL(15,2),
      P_COMMENT VARCHAR(23),
      dummy text);
ALTER TABLE part ADD PRIMARY KEY (p_partkey);

CREATE TABLE region(
      R_REGIONKEY INTEGER, 
      R_NAME CHAR(25),
      R_COMMENT VARCHAR(152),
      dummy text);
ALTER TABLE region ADD PRIMARY KEY (r_regionkey);

CREATE TABLE SUPPLIER (
      S_SUPPKEY INT,
      S_NAME CHAR(25),
      S_ADDRESS VARCHAR(40),
      S_NATIONKEY INTEGER,
      S_PHONE CHAR(15),
      S_ACCTBAL DECIMAL(15,2),
      S_COMMENT VARCHAR(101),
      dummy text);
ALTER TABLE supplier ADD PRIMARY KEY (s_suppkey);
```

## Tasks

### Task 0

Fill tables with generated data:

```bash
export POSTGRES_URI="postgres://postgres:<pass>@<host>:5432/postgres"
psql $POSTGRES_URI

\copy customer from  '/home/dbgen/tpch-dbgen/data/customer.csv' WITH (FORMAT csv, DELIMITER '|');
\copy lineitem from  '/home/dbgen/tpch-dbgen/data/lineitem.csv' WITH (FORMAT csv, DELIMITER '|');
\copy nation from  '/home/dbgen/tpch-dbgen/data/nation.csv' WITH (FORMAT csv, DELIMITER '|');
\copy orders from  '/home/dbgen/tpch-dbgen/data/orders.csv' WITH (FORMAT csv, DELIMITER '|');
\copy part from  '/home/dbgen/tpch-dbgen/data/part.csv' WITH (FORMAT csv, DELIMITER '|');
\copy partsupp from  '/home/dbgen/tpch-dbgen/data/partsupp.csv' WITH (FORMAT csv, DELIMITER '|');
\copy region from  '/home/dbgen/tpch-dbgen/data/region.csv' WITH (FORMAT csv, DELIMITER '|');
\copy supplier from  '/home/dbgen/tpch-dbgen/data/supplier.csv' WITH (FORMAT csv, DELIMITER '|');
```


### Task 1
Connect tables with foreign keys

Solutin:
```sql
ALTER TABLE supplier ADD CONSTRAINT supplier_nation_fk FOREIGN KEY (s_nationkey) REFERENCES nation (n_nationkey);
ALTER TABLE partsupp ADD CONSTRAINT partsupp_part_fk FOREIGN KEY (ps_partkey) REFERENCES part (p_partkey);
ALTER TABLE partsupp ADD CONSTRAINT partsupp_supplier_fk FOREIGN KEY (ps_suppkey) REFERENCES supplier (s_suppkey);
ALTER TABLE customer ADD CONSTRAINT customer_nation_fk FOREIGN KEY (c_nationkey) REFERENCES nation (n_nationkey);
ALTER TABLE orders ADD CONSTRAINT orders_customer_fk FOREIGN KEY (o_custkey) REFERENCES customer (c_custkey);
ALTER TABLE lineitem ADD CONSTRAINT lineitem_order_fk FOREIGN KEY (l_orderkey) REFERENCES orders (o_orderkey);
ALTER TABLE lineitem ADD CONSTRAINT lineitem_part_fk FOREIGN KEY (l_partkey) REFERENCES part (p_partkey);
ALTER TABLE lineitem ADD CONSTRAINT lineitem_partsupp_fk FOREIGN KEY (l_partkey, l_suppkey) REFERENCES partsupp (ps_partkey, ps_suppkey);
ALTER TABLE nation ADD CONSTRAINT nation_region_fk FOREIGN KEY (n_regionkey) REFERENCES region (r_regionkey);
```

### Task 2
Build stage layer for DWH.

Let's JOIN raw tables:
- Create `raw_inventory` table
- Create `raw_transactions` table
- Create `raw_orders` table

What JOIN type do we need?

Let's split tables in stage layer to raw_stage (tables) and stage (views)
- Create views `v_stg_inventory` for `raw_inventory`
- Create views `v_stg_transactions` for `raw_transactions`
- Create views `v_stg_orders` for `raw_orders`

### Task 3
Aggregating data:
- build dimention-model (facts `f_lineorder_flat` and `f_orders_stats`) - star scheme

Adapt queries:
```sql
SELECT
      L_ITEMKEY
    , L_ORDERKEY
    , L_PARTKEY
    , L_SUPPKEY
    , L_LINENUMBER
    , L_QUANTITY
    , L_EXTENDEDPRICE
    , L_DISCOUNT
    , L_TAX
    , L_RETURNFLAG
    , L_LINESTATUS
    , L_SHIPDATE
    , L_COMMITDATE
    , L_RECEIPTDATE
    , L_SHIPINSTRUCT
    , L_SHIPMODE
    , L_COMMENT
    
    , O_ORDERKEY
    , O_CUSTKEY
    , O_ORDERSTATUS
    , O_TOTALPRICE
    , O_ORDERDATE
    , O_ORDERPRIORITY
    , O_CLERK
    , O_SHIPPRIORITY
    , O_COMMENT

    , C_CUSTKEY
    , C_NAME
    , C_ADDRESS
    , C_NATIONKEY
    , C_PHONE
    , C_ACCTBAL
    , C_MKTSEGMENT
    , C_COMMENT

    , S_SUPPKEY
    , S_NAME
    , S_ADDRESS
    , S_NATIONKEY
    , S_PHONE
    , S_ACCTBAL
    , S_COMMENT

    , P_PARTKEY
    , P_NAME
    , P_MFGR
    , P_BRAND
    , P_TYPE
    , P_SIZE
    , P_CONTAINER
    , P_RETAILPRICE
    , P_COMMENT    

FROM lineitem AS l
    INNER JOIN orders AS o ON o.O_ORDERKEY = l.L_ORDERKEY
    INNER JOIN customer AS c ON c.C_CUSTKEY = o.O_CUSTKEY
    INNER JOIN supplier AS s ON s.S_SUPPKEY = l.L_SUPPKEY
    INNER JOIN part AS p ON p.P_PARTKEY = l.L_PARTKEY;

SELECT
    toYear(O_ORDERDATE) AS O_ORDERYEAR
    , O_ORDERSTATUS
    , O_ORDERPRIORITY
    , count(DISTINCT O_ORDERKEY) AS num_orders
    , count(DISTINCT C_CUSTKEY) AS num_customers
    , sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM <table name>
WHERE 1=1
GROUP BY
    toYear(O_ORDERDATE)
    , O_ORDERSTATUS
    , O_ORDERPRIORITY;
```

- Simulate next day load
- Prepare Point-in-Time & Bridge Tables
- query data about q1, q2, q3 orders

Adapt query:
```sql
-- Q1
SELECT
    l_returnflag,
    l_linestatus,
    sum(l_quantity) as sum_qty,
    sum(l_extendedprice) as sum_base_price,
    sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
    avg(l_quantity) as avg_qty,
    avg(l_extendedprice) as avg_price,
    avg(l_discount) as avg_disc,
    count(*) as count_order
FROM
    lineitem
WHERE
    l_shipdate <= date '1998-12-01' - interval '90' day
GROUP BY
    l_returnflag,
    l_linestatus
ORDER BY
    l_returnflag,
    l_linestatus;


-- Q2
SELECT
    l_orderkey,
    sum(l_extendedprice * (1 - l_discount)) as revenue,
    o_orderdate,
    o_shippriority
FROM
    customer,
    orders,
    lineitem
WHERE
    c_mktsegment = 'BUILDING'
    AND c_custkey = o_custkey
    AND l_orderkey = o_orderkey
    AND o_orderdate < date '1995-03-15'
    AND l_shipdate > date '1995-03-15'
GROUP BY
    l_orderkey,
    o_orderdate,
    o_shippriority
ORDER BY
    revenue desc,
    o_orderdate
LIMIT 20;

-- Q3

SELECT
    100.00 * sum(case
        when p_type like 'PROMO%'
            then l_extendedprice * (1 - l_discount)
        else 0
    end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue
FROM
    lineitem,
    part
WHERE
    l_partkey = p_partkey
    AND l_shipdate >= date '1995-09-01'
    AND l_shipdate < date '1995-09-01' + interval '1' month;
```

- Do we need Data Vault model?

### Task 3
Test indexes:
- Try to search lineitems by parts and suppliers
- Look at explain query
- Add indexes
- Look at explain again

Solution:
```sql
CREATE INDEX lineitem_idx3 ON lineitem (l_partkey, l_suppkey);
```
