
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select Diagnosis
from "alzheimers_analytics"."main"."silver_alzheimer_patients"
where Diagnosis is null



  
  
      
    ) dbt_internal_test