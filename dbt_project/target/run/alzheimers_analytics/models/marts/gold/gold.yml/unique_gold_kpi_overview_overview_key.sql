
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    overview_key as unique_field,
    count(*) as n_records

from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where overview_key is not null
group by overview_key
having count(*) > 1



  
  
      
    ) dbt_internal_test