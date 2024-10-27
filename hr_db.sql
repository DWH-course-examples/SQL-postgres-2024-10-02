-- source 2 - MSSQL

CREATE TYPE employee_gender AS ENUM (
    'M',
    'F'
);

CREATE TABLE employee (
    id bigint PRIMARY KEY,
    birth_date date NOT NULL,
    first_name varchar(255) NOT NULL,
    last_name varchar(255) NOT NULL,
    gender employee_gender NOT NULL,
    hire_date date NOT NULL
);

CREATE TABLE salary (
    employee_id bigint NOT NULL,
    amount bigint NOT NULL,
    from_date date NOT NULL,
    to_date date NOT NULL,
    CONSTRAINT pk_primary PRIMARY KEY (employee_id, from_date),
    CONSTRAINT salaries_fk FOREIGN KEY (employee_id) REFERENCES employee(id) ON UPDATE RESTRICT ON DELETE CASCADE
);

CREATE TABLE title (
    employee_id bigint NOT NULL,
    title varchar(255) NOT NULL,
    from_date date NOT NULL,
    to_date date,
    CONSTRAINT pk_primary PRIMARY KEY (employee_id, title, from_date),
    CONSTRAINT titles_fk FOREIGN KEY (employee_id) REFERENCES employee(id) ON UPDATE RESTRICT ON DELETE CASCADE
);
