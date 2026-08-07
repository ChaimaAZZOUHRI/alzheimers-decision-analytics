
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select average_age
from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where average_age is null



  
  
      
    ) dbt_internal_test