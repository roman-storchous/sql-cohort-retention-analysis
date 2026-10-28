with 
	clean_signup_date as (
select 
	user_id, 
	promo_signup_flag,
	replace(replace(split_part(trim(signup_datetime),' ',1), '/','-'),'.','-') as clean_date
from project.cohort_users_raw),
	clean_cohort_users as(
select 
	user_id, 
	promo_signup_flag,
case
	when length(split_part(clean_date,'-',3)) = 4
	then to_date(clean_date,'DD-MM-YYYY')::timestamp
	when length(split_part(clean_date,'-',3)) = 2
	then to_date(clean_date,'DD-MM-YY')::timestamp
end AS signup_datetime
from clean_signup_date),
	clean_event_date as (
select 
	event_id, 
	user_id,
	event_type,
	replace(replace(split_part(trim(event_datetime),' ',1),'/','-'),'.','-') as clean__date
from project.cohort_events_raw
),
	clean_cohort_events as (
select 
	event_id, 
	user_id,
	event_type,
case
	when length(split_part(clean__date,'-',3))=4
	then to_date(clean__date,'DD-MM-YYYY')::timestamp
	when length(split_part(clean__date,'-',3))=2
	then to_date(clean__date,'DD-MM-YY')::timestamp
end as clean_event_datetime
from clean_event_date),
	cohort as (
select
	u.user_id,
	u.promo_signup_flag,
	e.event_id,
	e.event_type,
    to_char(u.signup_datetime, 'YYYY-MM') as signup_month,
    to_char(e.clean_event_datetime, 'YYYY-MM') as event_month,
    (date_part('year', e.clean_event_datetime) - date_part('year', u.signup_datetime)) * 12 + (date_part('month', e.clean_event_datetime) - date_part('month', u.signup_datetime)) as month_offset
from clean_cohort_users as u
left join clean_cohort_events as e
    on u.user_id = e.user_id
where
	u.signup_datetime is not null
	and e.clean_event_datetime is not null
	and e.event_type is not null
	and e.event_type != 'test_event'
	and to_char(e.clean_event_datetime, 'YYYY-MM') between '2025-01' and '2025-06')
select 
	promo_signup_flag,
	month_offset,
	signup_month as cohort_month,
	count(distinct(user_id)) as users_total
from cohort
group by 
	promo_signup_flag,
	cohort_month,
	month_offset
ORDER BY 
    promo_signup_flag, 
    cohort_month,      
    month_offset;

