
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  select *
from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where total_patients
    <> diagnosed_patients + not_diagnosed_patients
  
  
      
    ) dbt_internal_test