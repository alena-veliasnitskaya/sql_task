/*Вывести количество фильмов в каждой категории, отсортировать по убыванию.*/
SELECT COUNT(film_id), category.name
FROM film_category
JOIN category USING(category_id)
GROUP BY category.name
ORDER BY COUNT(film_id) DESC;

/*Вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.*/
SELECT COUNT(rental_id), CONCAT(actor.first_name, ' ', actor.last_name) AS actor_fullname
FROM rental
	INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
	INNER JOIN film ON inventory.film_id = film.film_id
	INNER JOIN film_actor ON film_actor.film_id = film.film_id
	INNER JOIN actor ON film_actor.actor_id = actor.actor_id
GROUP BY actor.first_name, actor.last_name
ORDER BY COUNT(rental_id) DESC
LIMIT 10;


/*Вывести категорию фильмов, на которую потратили больше всего денег.*/
WITH t1 AS (SELECT SUM(amount) as budget, category.name as film_category
FROM payment 
INNER JOIN rental ON payment.rental_id = rental.rental_id
INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
INNER JOIN film ON inventory.film_id = film.film_id
INNER JOIN film_category ON film_category.film_id = film.film_id
INNER JOIN category ON film_category.category_id = category.category_id
GROUP BY film_category
ORDER BY SUM(amount) DESC)
SELECT film_category FROM t1
WHERE budget = (SELECT MAX(budget) FROM t1);

/*Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.*/
SELECT title
FROM film
FULL OUTER JOIN inventory USING(film_id)
WHERE inventory_id IS NULL

/*Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”. 
Если у нескольких актеров одинаковое кол-во фильмов, вывести всех.*/
SELECT actor_fullname, place FROM (
SELECT CONCAT(actor.first_name, ' ', actor.last_name) AS actor_fullname, COUNT(last_name), DENSE_RANK () OVER (ORDER BY COUNT(last_name) DESC) as place
FROM actor
INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
INNER JOIN film_category ON film_actor.film_id = film_category.film_id
INNER JOIN category ON film_category.category_id = category.category_id
WHERE category.name = 'Children' 
GROUP BY actor_fullname) t1
WHERE place < 4;

/*Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). 
Отсортировать по количеству неактивных клиентов по убыванию.*/

SELECT city, SUM(
	             CASE
	             WHEN customer.active = 1 THEN 1 ELSE 0 END) AS active_users,
	         SUM(
		         CASE
		         WHEN customer.active = 0 THEN 1 ELSE 0 END) AS inactive_users
FROM city
INNER JOIN address ON address.city_id = city.city_id
INNER JOIN customer ON customer.address_id = address.address_id
GROUP BY city
ORDER BY inactive_users DESC;

/*Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах 
(customer.address_id в этом city), и которые начинаются на букву “a”. 
То же самое сделать для городов в которых есть символ “-”. Написать все в одном запросе.*/

WITH t1 AS (SELECT name, SUM(CASE
	             WHEN city LIKE 'A%' 
				 THEN DATE_PART('day', rental.return_date - rental.rental_date) * 24 + 
                 DATE_PART('hour', rental.return_date - rental.rental_date)
			     ELSE double precision '0' END) AS rental_hours_city_a, 
             SUM(CASE
	             WHEN city LIKE '%-%' 
				 THEN DATE_PART('day', rental.return_date - rental.rental_date) * 24 + 
                 DATE_PART('hour', rental.return_date - rental.rental_date)
				 ELSE double precision '0' END) AS rental_hours_city_with_hyphen,
				 ROW_NUMBER () OVER (ORDER BY 2 DESC) as place_city_a,
				 ROW_NUMBER () OVER (ORDER BY 3 DESC) as place_city_with_hyphen
FROM category
INNER JOIN film_category ON film_category.category_id = category.category_id
INNER JOIN inventory ON inventory.film_id = film_category.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
INNER JOIN customer ON customer.store_id = inventory.store_id
INNER JOIN address ON customer.address_id = address.address_id
INNER JOIN city ON address.city_id = city.city_id
GROUP BY name)

SELECT * FROM t1 
WHERE place_city_a = 1 and place_city_with_hyphen = 1;

