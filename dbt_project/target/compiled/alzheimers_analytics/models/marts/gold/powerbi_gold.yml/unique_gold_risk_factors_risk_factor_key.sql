
    
    

select
    risk_factor_key as unique_field,
    count(*) as n_records

from "alzheimers_analytics"."analytics"."gold_risk_factors"
where risk_factor_key is not null
group by risk_factor_key
having count(*) > 1


