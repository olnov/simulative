/*1. Задача решена не совсем корректно. Работа с начислениями и средним начислением сделана верно,
 * 	 однако при вычислении среднего списания, бралась сумма из присоединенной таблицы и делилась на
 * 	 количество элементов из табллицы A. При расчете среднего исходим из суммы элементов выборки, деленные
 *	 на количество элементов выборки. Дельту считаем соответсвенно как разницу сумм, деленную на общее количество элементов.
 *2. Поправил форматирование, что бы код лучше читался.
 *3. Заменил названия столбцов кириллицей на латиницу. В зависимости от настроек СУБД могут быть проблемы с отображением.
 *4. Поставил в кавычки зарезервированные имена (transaction). В зависимости от СУБД могут быть проблемы с выполнением 
 *	 запроса.
 *5. Задачу так же возможно решить вариантов перебора таблицы через CASE WHEN, однако, не смотря на то, что выбранный
 *	 вариант выглядит немного более громозко, с т.з. производительности данный вариант показывает COST ~ 2280 против 
 *   варианта с CASE WHEN ~ 2720.
 * */

/* Подготовка таблицы с начислениями */	 
with A as (
select
	sum(t.value) as sum_accrual,
	t.user_id
from
	"transaction" t
where
	t.type_id in(2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 29)--id начислений
	and t.value <= 500
	and t.user_id >= 94
group by
	t.user_id
		),
/* Расчет среднего начисления и суммы */	 
A1 as (
select
	sum(A.sum_accrual) as total_accrual,
	round (sum(A.sum_accrual)/ count(A.user_id), 2) as average_accrual
from
	A
	),
/* Подготовка таблицы списаний */
B as (
select
	sum(t2.value) as sum_write_off,
	t2.user_id
from
	"transaction" t2
where
	t2.type_id in (1, 23, 24, 25, 26, 27, 28) --id списаний
	and t2.value <= 500
	and t2.user_id >= 94
group by
	t2.user_id
	),	
/* Расчет среднего списания и суммы */	 	
B1 as (
select
	sum(B.sum_write_off) as total_write_off,
	round(sum(B.sum_write_off)* 1.0 / count(B.user_id),	2) as average_write_off
from
	B
	),
/* Считаем общее количество пользователей */
C as (
select
	count(distinct t3.user_id) as total_users
from
	"transaction" t3
	)
/* Вывод итоговых значений среднего начисления, списания и дельты */
select
	A1.average_accrual,
	(B1.average_write_off * -1) as average_write_off,
	round ((A1.total_accrual-B1.total_write_off)/C.total_users,2) as delta
from
	A1, B1, C
