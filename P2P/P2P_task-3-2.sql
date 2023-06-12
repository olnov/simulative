/* Подготавливаем таблицу для расчета интервала проверки активности.
 * Используем интервал между предыдущим и следующим заходом. */
with A as (	
select
	user_id,
	entry_at as start_date,
	case 
		when (lead(entry_at) over (partition by user_id order by entry_at)) is null
		then current_timestamp 
		else (lead(entry_at) over (partition by user_id order by entry_at))
	end end_date
from userentry u
where user_id>=94
order by entry_at 
),
/* Выводим все активности по задачам и тестам*/
B as (
select
	t.user_id ,
	t.created_at
from
	teststart t
where
	t.user_id >= 94 
union
select 
	c.user_id ,
	c.created_at
from
	codesubmit c
where
	c.user_id >= 94
union
select  
	c2.user_id ,
	c2.created_at
from
	coderun c2
where
	c2.user_id >= 94
order by
	user_id, created_at
),
/* Выводим даты, когда не было активностей*/
C as (
select
	a.user_id,
	a.start_date,
	a.end_date,
	count (b.created_at)
from A
left join B
on a.user_id=b.user_id and b.created_at>=a.start_date and b.created_at<a.end_date
group by a.user_id, a.start_date, a.end_date
having count(b.created_at)=0
),
/* Считаем общее количество заходов */
D as (
select count(*) all_entries from A
),
/* Считаем общее количество дней без активностей */
E as (
select count(*) no_activity from C
)
select ((no_activity*1.0/all_entries)*100)::numeric (3,0) as no_activity_percentage
from D,E