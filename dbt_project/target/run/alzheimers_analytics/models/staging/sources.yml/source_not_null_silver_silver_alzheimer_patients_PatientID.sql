
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select PatientID
from "alzheimers_analytics"."main"."silver_alzheimer_patients"
where PatientID is null



  
  
      
    ) dbt_internal_test