
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select overview_key
from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where overview_key is null



  
  
      
    ) dbt_internal_test