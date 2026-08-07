
    
    

with all_values as (

    select
        Diagnosis as value_field,
        count(*) as n_records

    from "alzheimers_analytics"."main"."silver_alzheimer_patients"
    group by Diagnosis

)

select *
from all_values
where value_field not in (
    '0','1'
)


