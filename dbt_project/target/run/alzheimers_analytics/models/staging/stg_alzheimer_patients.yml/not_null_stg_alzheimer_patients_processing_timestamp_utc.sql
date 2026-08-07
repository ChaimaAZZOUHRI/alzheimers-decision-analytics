
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select processing_timestamp_utc
from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"
where processing_timestamp_utc is null



  
  
      
    ) dbt_internal_test