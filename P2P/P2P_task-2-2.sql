/* По данной задаче было много вопросов, поэтому постарался разложить по блокам,
 * и решил через CTE влоб, что не оптимально, но, надеюсь, верно)
 * 1. Количество бесплатных (открытых) задач - free_cnt. Считаю как количество уникальных записей
 * в coderun и codesumbit. Откидываю значения с user_id меньше 94 и ДЗ (id задач, которые есть в таблице
 * problem_to_company) из этого количества вычитаю количество купленных задач из таблицы транзакций. 
 * 2. Количество бесплатных (открытых) тестов считаю также, кроме откидывания ДЗ, т.к. тут это нерелевантно.
 * 3. Количество купленных задач и тестов - payed_cnt. Нахожу из таблицы транзакций на основании соответсвующего 
 * типа транзакции.
 * 4. Среднее количество купленных задач и тестов на одного ползователя - avg_purchased.
 * 5. Количество пользователей, которые покупали задачи и тесты - cnt_users_purchased.
 * 6. Количество пользователей, которые решали только бесплатные - cnt_users_free. Из общего количества решавших
 * вычитаю тех, кто покупал.*/



/* Посмотрим сколько всего задач решали все пользователи,
 * затем вычтим общее количество купленных задач, таким образом 
 * найдем общее количество бесплатных */
with all_p as (
select distinct 
	problem_id,
	user_id
from
	coderun c
where
	user_id >= 94
	and problem_id not in (
	-- Откидываем задачи (ДЗ), которые фигурируют в таблице problem_to_company согласно условиям.
	select
			distinct problem_id
	from
			problem_to_company ptc
		)
union
select distinct 
	problem_id,
	user_id
from
	codesubmit c
where
	user_id >= 94
	and problem_id not in (
	-- Откидываем задачи (ДЗ), которые фигурируют в таблице problem_to_company согласно условиям.
	select
			distinct problem_id
	from
			problem_to_company ptc
		)
),
/* Посмотрим сколько всего тестов решали все пользователи,
 * затем вычтим общее количество купленных тестов, таким образом 
 * найдем общее количество бесплатных */
all_t as (
select
	test_id,
	user_id
from
	teststart t
where
	user_id >= 94
union
select
	test_id,
	user_id
from
	testresult t
where
	user_id >= 94
order by
	user_id
),
/* Считаем все транзакции покупок задач */
purchases_p as (
select
	user_id,
	count(user_id) as cnt_prb
from
	"transaction" t
where
	type_id = 23
	and user_id >= 94
group by
	user_id
order by
	user_id 
),
/* Считаем все транзакции покупок тестов */
purchases_t as (
select
	user_id,
	count(user_id) as cnt_tst
from
	"transaction" t
where
	type_id = 27
	and user_id >= 94
group by
	user_id
order by
	user_id 
),
/* Считаем общее количество покупок задач */
purchased_p as (
select
	sum(cnt_prb) as sum_purchased_prb
from
	purchases_p
),
/* Считаем общее количество покупок тестов*/
purchased_t as (
select
	sum(cnt_tst) as sum_purchased_tst
from
	purchases_t
),
/* Группируем по пользователям для дальнейших вычислений задач*/
grp_users_p as (
select
	user_id,
	count(distinct problem_id) as cnt_p
from
	all_p
group by
	user_id
order by
	user_id
),
/* Группируем по пользователям для дальнейших вычислений тестов*/
grp_users_t as (
select
	user_id,
	count(distinct test_id) as cnt_t
from
	all_t
group by
	user_id
order by
	user_id
),
/* Суммируем все задачи, что бы получить одну метрику*/
sum_all_p as (
select
	sum(cnt_p) as sum_problems
from
	grp_users_p
),
/* Суммируем все задачи, что бы получить одну метрику*/
sum_all_t as (
select
	sum(cnt_t) as sum_tests
from
	grp_users_t
)
/* Общее количество открытых задач */
select
	'Problem' as "type",
	(sum_all_p.sum_problems-purchased_p.sum_purchased_prb) as free_cnt,
	purchased_p.sum_purchased_prb as payed_cnt,
	round (purchased_p.sum_purchased_prb * 1.0 / (
	select
		count(distinct user_id)
	from
		"transaction" t
	where
		type_id = 23
		and user_id >= 94 ),
	2) as avg_purchased,
	(
	select
		count(distinct user_id)
	from
		"transaction" t
	where
		type_id = 23
		and user_id >= 94 ) as cnt_users_purchased,
	(
	select
		count(distinct user_id)
	from
		all_p ) - (
	select
		count(distinct user_id)
	from
		"transaction" t
	where
		type_id = 23
		and user_id >= 94 ) as cnt_users_free
from
	sum_all_p,
	purchased_p
union
select
	'Test' as "type",
	(sum_all_t.sum_tests-purchased_t.sum_purchased_tst) as free_cnt,
	purchased_t.sum_purchased_tst as payed_cnt,
	round (purchased_t.sum_purchased_tst / (
	select
		count(distinct user_id)
	from
		"transaction" t
	where
		type_id = 27
		and user_id >= 94 ),
	2) as avg_purchased,
	(
	select
		count(distinct user_id)
	from
		"transaction" t
	where
		type_id = 27
		and user_id >= 94 ) as cnt_users_purchased,
	(
	select
		count(distinct user_id)
	from
		all_t ) - (
	select
		count(distinct user_id)
	from
		"transaction" t
	where
		type_id = 27
		and user_id >= 94 ) as cnt_users_free
from
	sum_all_t,
	purchased_t