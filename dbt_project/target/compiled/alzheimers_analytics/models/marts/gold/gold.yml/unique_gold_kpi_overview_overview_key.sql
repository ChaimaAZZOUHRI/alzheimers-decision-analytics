
    
    

select
    overview_key as unique_field,
    count(*) as n_records

from "alzheimers_analytics"."analytics"."gold_kpi_overview"
where overview_key is not null
group by overview_key
having count(*) > 1


