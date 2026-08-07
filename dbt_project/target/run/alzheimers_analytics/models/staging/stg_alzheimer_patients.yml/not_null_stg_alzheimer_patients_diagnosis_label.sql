
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select diagnosis_label
from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"
where diagnosis_label is null



  
  
      
    ) dbt_internal_test