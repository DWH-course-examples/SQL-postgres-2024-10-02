## Упражнение 1:

Есть таблицы users и roles:
```sql
CREATE TABLE roles (
                       id SERIAL PRIMARY KEY,
                       role_name VARCHAR(50) NOT NULL
);

INSERT INTO roles (role_name) VALUES ('USER'), ('ADMIN');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    login VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    username VARCHAR(50) NOT NULL,
    role_id INTEGER NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id)
);
```

Написать функцию, добавляющую пользователя с ролью ADMIN:

```sql
DO $$
DECLARE
        admin_role_id INTEGER;
BEGIN
        SELECT id INTO admin_role_id FROM roles WHERE role_name = 'ADMIN';
        INSERT INTO users (login, password, username, role_id) VALUES ('admin', 'admin', 'Administrator', admin_role_id);
END $$;
```

Поменять функцию таким образом, чтобы:
- можно было указывать нужную роль
- можно было указывать параметры пользователя (login, username, email)
- \* можно было автоматически генерировать логин, пароль

## Упражнение 2

https://www.db-fiddle.com/f/9ARWiFLirQs6MNRapAmSDd/2

```sql
CREATE FUNCTION calc_sum(n int) RETURNS numeric(10,3) AS $$
DECLARE
	i decimal;
	s numeric(10,3);
BEGIN
	SELECT 0 into s;
	FOR i IN 1..n LOOP
    	SELECT s+1/(i*i)::decimal INTO s;
    END LOOP;
	RETURN s;
END;
$$ LANGUAGE plpgsql;

select calc_sum(1000)
-- 1/1 + 1/4 + 1/9 + 1/16 + 1/25
```
