
    
    

select
    symptom_key as unique_field,
    count(*) as n_records

from "alzheimers_analytics"."analytics"."gold_symptoms"
where symptom_key is not null
group by symptom_key
having count(*) > 1


