
/* Выводим расчеты по задачам */
with A as (
select
	(
	select	count(*)
	from	codesubmit c
	where	c.user_id >= 94
    ) - count(t.id) as "open" ,					--кол-во открытых задач
	count(distinct t.user_id) as count_user,	--кол-во людей купивших хотя бы 1 задачу
	count(t.id) as count_closed,				--сумма купленных закрытых задач
	round(count(t.id)* 1.0 / count(distinct t.user_id), 2) as avg_count_closed,	--среднее кол-во задач на пользователя
       	(
		select	count(distinct c.user_id)
		from	codesubmit c
		where	c.user_id >= 94
       	) - count(distinct t.user_id) as count_user_open --количество пользователей, решавших только бесплатные задачи
from	"transaction" t
where	t.type_id = 23 --покупка задач
and 	t.user_id >= 94
),
/* Выводим расчеты по тестам */
B as (
select
		(
		select	count(*)
		from	teststart t2
		where	t2.user_id >= 94
    	) - count(t.id) as "open", --кол-во открытых тестов
	count(distinct t.user_id) as count_user, --кол-во людей купивших хотя бы 1 тест
	count(t.id) as count_closed, --сумма купленных закрытых тестов
	round(count(t.id)* 1.0 / count(distinct t.user_id), 2) as avg_count_closed, --среднее кол-во тестов на пользователя
       	(
		select	count(distinct t2.user_id)
		from	teststart t2
		where	t2.user_id >= 94
       	) - count(distinct t.user_id) as count_user_open --количество пользователей, решавших только бесплатные тесты
from	"transaction" t
where	t.type_id = 27 --покупка теста
and 	t.user_id >= 94) --сводим результаты	 
select	'problem' as task_type, *
from	A
union
select	'test' as task_type, *
from	B

/* Отберем задачи, которые решали и у которых стоимость равна 0 */
with sort_free_p as (
select
	distinct c.user_id,
	p.id
from
	codesubmit c
join problem p 
on
	p.id = c.problem_id
where
	p."cost" = 0
	and c.user_id >= 94	-- Согласно условиям исключаем пользователей с id меньше 94. 
	and c.is_false = 0	-- Возьмем только те задачи, которые решили верно. Хотя сам не уверен до конца в этом условии.
	and p.id not in (	-- Откидываем задачи (ДЗ), которые фигурируют в таблице problem_to_company согласно условиям.
		select
			distinct problem_id
		from
			problem_to_company ptc
		)				
),
/* Отберем тесты, которые решали и у которых стоимость равна 0 */
sort_free_t as (
select
	distinct c.user_id,
	p.id
from
	testresult t 
join problem p 
on
	p.id = c.problem_id
where
	p."cost" = 0
	and c.user_id >= 94	-- Согласно условиям исключаем пользователей с id меньше 94. 
	and c.is_false = 0	-- Возьмем только те задачи, которые решили верно. Хотя сам не уверен до конца в этом условии.
	and p.id not in (	-- Откидываем задачи (ДЗ), которые фигурируют в таблице problem_to_company согласно условиям.
		select
			distinct problem_id
		from
			problem_to_company ptc
		)				
)

/* Группируем по пользователям, для расчета суммы в дальнейшем */
grp_user as (
select
	user_id,
	count(id) as cnt_per_user
from
	sort_free_p
group by
	user_id
order by
	user_id
)
select sum(cnt_per_user) from grp_user



select * from teststart t 