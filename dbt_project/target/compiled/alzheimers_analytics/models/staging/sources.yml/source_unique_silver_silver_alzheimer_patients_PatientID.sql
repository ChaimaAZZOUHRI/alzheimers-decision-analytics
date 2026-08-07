
    
    

select
    PatientID as unique_field,
    count(*) as n_records

from "alzheimers_analytics"."main"."silver_alzheimer_patients"
where PatientID is not null
group by PatientID
having count(*) > 1


