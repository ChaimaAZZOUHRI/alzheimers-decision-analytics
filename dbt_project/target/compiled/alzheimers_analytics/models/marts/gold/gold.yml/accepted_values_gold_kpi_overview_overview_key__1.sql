
    
    

with all_values as (

    select
        overview_key as value_field,
        count(*) as n_records

    from "alzheimers_analytics"."analytics"."gold_kpi_overview"
    group by overview_key

)

select *
from all_values
where value_field not in (
    '1'
)


