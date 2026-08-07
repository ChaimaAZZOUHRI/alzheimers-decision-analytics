
  
    
    

    create  table
      "alzheimers_analytics"."analytics"."gold_symptoms__dbt_tmp"
  
    as (
      with symptom_records as (

    select
        patient_id,
        diagnosis_code,
        'Memory complaints' as symptom,
        1 as display_order,
        memory_complaints as symptom_present
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Behavioral problems',
        2,
        behavioral_problems
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Confusion',
        3,
        confusion
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Disorientation',
        4,
        disorientation
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Personality changes',
        5,
        personality_changes
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Difficulty completing tasks',
        6,
        difficulty_completing_tasks
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Forgetfulness',
        7,
        forgetfulness
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

),

aggregated as (

    select
        symptom,
        display_order,

        count(*) as total_patients,

        sum(
            case
                when symptom_present = 1 then 1
                else 0
            end
        ) as patients_with_symptom,

        sum(
            case
                when symptom_present = 0 then 1
                else 0
            end
        ) as patients_without_symptom,

        sum(
            case
                when symptom_present = 1
                    and diagnosis_code = 1
                then 1
                else 0
            end
        ) as diagnosed_with_symptom,

        sum(
            case
                when symptom_present = 0
                    and diagnosis_code = 1
                then 1
                else 0
            end
        ) as diagnosed_without_symptom

    from symptom_records

    group by
        symptom,
        display_order

)

select
    symptom as symptom_key,
    symptom,
    display_order,
    total_patients,
    patients_with_symptom,
    patients_without_symptom,
    diagnosed_with_symptom,
    diagnosed_without_symptom,

    round(
        100.0
        * patients_with_symptom
        / nullif(total_patients, 0),
        2
    ) as symptom_prevalence_pct,

    round(
        100.0
        * diagnosed_with_symptom
        / nullif(patients_with_symptom, 0),
        2
    ) as diagnosis_rate_with_symptom_pct,

    round(
        100.0
        * diagnosed_without_symptom
        / nullif(patients_without_symptom, 0),
        2
    ) as diagnosis_rate_without_symptom_pct,

    round(
        (
            100.0
            * diagnosed_with_symptom
            / nullif(patients_with_symptom, 0)
        )
        -
        (
            100.0
            * diagnosed_without_symptom
            / nullif(patients_without_symptom, 0)
        ),
        2
    ) as diagnosis_rate_difference_pct_points

from aggregated
    );
  
  