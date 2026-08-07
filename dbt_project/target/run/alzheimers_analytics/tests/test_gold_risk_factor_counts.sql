
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  select *
from "alzheimers_analytics"."analytics"."gold_risk_factors"
where total_patients
    <> patients_with_factor + patients_without_factor
  
  
      
    ) dbt_internal_test