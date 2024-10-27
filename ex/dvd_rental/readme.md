# DVD rental store

Sample data for a fictional DVD rental store. Pagila includes tables for films, actors, film categories, stores, customers, payments, and more.

- Source: https://github.com/devrimgunduz/pagila
- License: LICENSE.txt
- Copyright (c) Devrim Gündüz <devrim@gunduz.org>

## Find the top 10 most popular film categories based on rental frequency:

```sql
SELECT c.name AS category_name, COUNT(r.rental_id) AS rental_count
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name
ORDER BY rental_count DESC
LIMIT 10;
```

