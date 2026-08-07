
    
    

select
    demographic_key as unique_field,
    count(*) as n_records

from "alzheimers_analytics"."analytics"."gold_demographics"
where demographic_key is not null
group by demographic_key
having count(*) > 1


