CREATE TABLE if not exists mart.f_customer_retention (
    new_customers_count int8 not NULL,
    returning_customers_count int8 not NULL,
    refunded_customer_count int8 not NULL,
    period_name text not NULL,
    period_id int4 not NULL,
    item_id int4 not NULL,
    new_customers_revenue numeric not NULL,
    returning_customers_revenue numeric not NULL,
    customers_refunded numeric not NULL
);

delete from mart.f_customer_retention mfr
where mfr.period_id=DATE_PART('week','{{ds}}'::timestamp);

with freshCustomers as (
    select
        fs.item_id,
        dc.week_of_year as week_of_year,
        fs.customer_id,
        fs.quantity,
        fs.payment_amount,
case
            when count(dcu.customer_id) 
            over(
                partition by dcu.customer_id,
                dc.week_of_year,
                fs.item_id
            ) = 1 then 'new'
            else 'old'
        end as isNew,
        fs.status
    from
        mart.f_sales fs
        left join mart.d_customer dcu on fs.customer_id = dcu.customer_id
        left join mart.d_calendar dc on fs.date_id = dc.date_id
)
INSERT INTO
    mart.f_customer_retention (
        new_customers_count,
        returning_customers_count,
        refunded_customer_count,
        period_name,
        period_id,
        item_id,
        new_customers_revenue,
        returning_customers_revenue,
        customers_refunded
    )
select
    count(
        distinct case
            when isNew = 'new' then customer_id
        end
    ) as new_customers_count,
    count(
        distinct case
            when isNew = 'old' then customer_id
        end
    ) as returning_customers_count,
    count(
        distinct case
            when status = 'refunded' then customer_id
        end
    ) as refunded_customer_count,
    'weekly' as period_name,
    week_of_year as period_id,
    item_id,
    sum(
        distinct case
            when isNew = 'new' then payment_amount
            else 0
        end
    ) as new_customers_revenue,
    sum(
        distinct case
            when isNew = 'old' then payment_amount
            else 0
        end
    ) as returning_customers_revenue,
    sum(
        distinct case
            when status = 'refunded' then quantity
            else 0
        end
    ) as customers_refunded
from
    freshCustomers as nc
group by
    week_of_year,
    item_id