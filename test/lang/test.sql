-- {{TEST}}
select
    order_id,
    case -- {{CONTEXT}}
        when amount > 100 then 'large'




        when amount > 10 then 'medium' -- {{CURSOR}}
        else 'small'
    end as size
from orders;

-- {{TEST}}
create materialized view totals as -- {{CONTEXT}}
select
    customer_id,




    sum(amount) as total -- {{CURSOR}}
from orders
group by customer_id;

-- {{TEST}}
create table orders ( -- {{CONTEXT}}
    order_id int primary key,
    customer_id int,




    amount numeric -- {{CURSOR}}
);

-- {{TEST}}
create view paid_orders as -- {{CONTEXT}}
select
    order_id,




    amount -- {{CURSOR}}
from orders
where amount > 0;

-- {{TEST}}
with orders as ( -- {{CONTEXT}}
    select
        order_id,
        customer_id,




        amount -- {{CURSOR}}
    from raw_orders
)

select * from orders;

-- {{TEST}}
insert into totals (customer_id, total) -- {{CONTEXT}}
select
    customer_id,




    sum(amount) -- {{CURSOR}}
from orders
group by customer_id;

-- {{TEST}}
select *
from orders
where customer_id in ( -- {{CONTEXT}}
    select customer_id
    from customers




    where active -- {{CURSOR}}
);

-- {{TEST}}
update orders -- {{CONTEXT}}
set
    customer_id = 1,




    amount = 0 -- {{CURSOR}}
where order_id = 2;

-- {{TEST}}
create function add_order( -- {{CONTEXT}}
    p_customer int, -- {{CONTEXT}}
    p_amount numeric -- {{CONTEXT}}
) -- {{CONTEXT}}
returns void
language plpgsql
as $$
begin




    insert into orders (customer_id, amount) -- {{CURSOR}}
    values (p_customer, p_amount);
end;
$$;

-- {{TEST}}
create procedure archive_orders( -- {{CONTEXT}}
    p_amount numeric -- {{CONTEXT}}
) -- {{CONTEXT}}
language sql
begin atomic




    delete from orders -- {{CURSOR}}
    where amount = p_amount;
end;

-- {{TEST}}
create procedure purge_orders -- {{CONTEXT}}
language sql
begin atomic




    delete from orders -- {{CURSOR}}
    where amount = 0;
end;
