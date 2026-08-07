
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select not_diagnosed_patients
from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where not_diagnosed_patients is null



  
  
      
    ) dbt_internal_test