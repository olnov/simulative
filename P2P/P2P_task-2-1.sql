/* Отберем задачи и тесты, у которых стоимость равна 0 */
with sort_free_p as (
select
	count(p.id) as free_stuff
from
	problem p 
where
	p."cost" = 0
	and p.id not in (	-- Откидываем задачи (ДЗ), которые фигурируют в таблице problem_to_company согласно условиям.
		select
			distinct problem_id
		from
			problem_to_company ptc
		)				
union
select
	count(t.id)
from
	test t
where
	t."cost" = 0
),
/* Отберем тесты, которые решали и у которых стоимость равна 0 */
sort_free_t as (
select
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



select * from test t where "cost" =0