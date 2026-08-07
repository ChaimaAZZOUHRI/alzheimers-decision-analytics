
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select average_mmse
from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where average_mmse is null



  
  
      
    ) dbt_internal_test