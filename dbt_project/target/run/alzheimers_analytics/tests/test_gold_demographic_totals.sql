
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  with expected as (

    select count(*) as expected_patients
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

),

group_totals as (

    select
        group_type,
        sum(total_patients) as group_patient_count
    from "alzheimers_analytics"."analytics"."gold_demographics"
    group by group_type

)

select
    group_type,
    group_patient_count,
    expected_patients

from group_totals
cross join expected

where group_patient_count <> expected_patients
  
  
      
    ) dbt_internal_test