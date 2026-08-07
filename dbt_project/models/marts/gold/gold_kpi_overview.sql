with patients as (

    select *
    from {{ ref('stg_alzheimer_patients') }}

)

select
    1 as overview_key,

    count(*) as total_patients,

    sum(
        case
            when diagnosis_code = 1 then 1
            else 0
        end
    ) as diagnosed_patients,

    sum(
        case
            when diagnosis_code = 0 then 1
            else 0
        end
    ) as not_diagnosed_patients,

    round(
        100.0
        * sum(
            case
                when diagnosis_code = 1 then 1
                else 0
            end
        )
        / nullif(count(*), 0),
        2
    ) as diagnosis_rate_pct,

    round(avg(age), 2) as average_age,
    round(avg(bmi), 2) as average_bmi,
    round(avg(mmse), 2) as average_mmse,

    round(
        avg(functional_assessment),
        2
    ) as average_functional_assessment,

    round(avg(adl), 2) as average_adl,

    round(
        avg(symptom_count),
        2
    ) as average_symptom_count,

    round(
        avg(medical_history_count),
        2
    ) as average_medical_history_count

from patients
