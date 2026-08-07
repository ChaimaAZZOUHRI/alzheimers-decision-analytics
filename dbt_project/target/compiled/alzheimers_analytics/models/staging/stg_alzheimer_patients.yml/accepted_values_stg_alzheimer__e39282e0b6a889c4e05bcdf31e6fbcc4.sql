
    
    

with all_values as (

    select
        diagnosis_label as value_field,
        count(*) as n_records

    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"
    group by diagnosis_label

)

select *
from all_values
where value_field not in (
    'Diagnosed','Not Diagnosed'
)


