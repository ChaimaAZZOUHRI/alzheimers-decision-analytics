
    
    

with all_values as (

    select
        age_group as value_field,
        count(*) as n_records

    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"
    group by age_group

)

select *
from all_values
where value_field not in (
    '60-69','70-79','80-90'
)


