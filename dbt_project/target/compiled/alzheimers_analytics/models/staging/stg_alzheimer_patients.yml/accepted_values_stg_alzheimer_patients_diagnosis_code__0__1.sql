
    
    

with all_values as (

    select
        diagnosis_code as value_field,
        count(*) as n_records

    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"
    group by diagnosis_code

)

select *
from all_values
where value_field not in (
    '0','1'
)


