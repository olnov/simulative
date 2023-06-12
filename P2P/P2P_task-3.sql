/* 1. В целом все корректно, для расчета всех активностей мне видится, что нужно учитывать еще таблицу coderun,
 * так как может быть, что в какие-то дни пользователь просто запускал код, но результат не отправлял на проверку. 
 * Тем не менее, это тоже активность.
 * 2. Поправил форматирование, что бы было проще читать код.
 * 3. Можно немного оптимизировать через функцию lead для расчета интервала и убрать промежуточные CTE.
 *    В моем случае отрабатывает примерно на 30% быстрее по показаниям из explain. 
 *    Свой вариант приложил в файле P2P-task-3-2.sql */

/*нумерация в пределах группы (u.user_id) для таблицы В*/
with A as (
select
	u.user_id ,
	u.entry_at,
	row_number() over(partition by u.user_id order by u.entry_at) as num 
from
	userentry u
where
	u.user_id >= 94
order by
	u.user_id
),
/* вывод даты захода на платформу - entry_start и даты следующего захода для каждого юзера -  
 * (период, в пределах которого будет рассчитана активность),
 * если следующего захода нет-выводим текущую дату */
B as (
select
	A.user_id,
	A.entry_at as entry_start ,
	case
		when A1.entry_at is not null then A1.entry_at
		else current_timestamp
	end as entry_end
from
	A
left join A as A1 on
	A1.user_id = A.user_id
	and A1.num = A.num + 1
),
/* Выводим все активности по задачам и тестам*/
C as (
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
/* Считаем попытки решить тесты и задачи */
D as (
select
	B.user_id,
	B.entry_start,
	B.entry_end,
	count(C1.created_at) -- кол -во попыток решить задачи или тесты в период entry_start-entry_end
from
	B
left join C as C1 on
	C1.user_id = B.user_id
	and C1.created_at>B.entry_start
	and C1.created_at<B.entry_end
group by
	B.user_id,
	B.entry_start,
	B.entry_end
having
	count(C1.created_at)= 0 -- вывод заходов на платформу не сопровождающихся активностью
),
/* Количество заходов на платформу не сопровождающихся активностью */
D1 as (
select
	count (*)
from
	D
),
/* Общее количество заходов на платформу */   
D2 as (
select
	count(A.entry_at)
from
	A
)
select
	round (D1.count * 1.0 / D2.count * 100, 0)
from
	D1,	D2
	