with risk_factor_records as (

    select
        patient_id,
        diagnosis_code,
        'Smoking' as risk_factor,
        1 as display_order,
        smoking as risk_present
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Family history of Alzheimer''s',
        2,
        family_history_alzheimers
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Cardiovascular disease',
        3,
        cardiovascular_disease
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Diabetes',
        4,
        diabetes
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Depression',
        5,
        depression
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Head injury',
        6,
        head_injury
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

    union all

    select
        patient_id,
        diagnosis_code,
        'Hypertension',
        7,
        hypertension
    from "alzheimers_analytics"."analytics"."stg_alzheimer_patients"

),

aggregated as (

    select
        risk_factor,
        display_order,

        count(*) as total_patients,

        sum(
            case
                when risk_present = 1 then 1
                else 0
            end
        ) as patients_with_factor,

        sum(
            case
                when risk_present = 0 then 1
                else 0
            end
        ) as patients_without_factor,

        sum(
            case
                when risk_present = 1
                    and diagnosis_code = 1
                then 1
                else 0
            end
        ) as diagnosed_with_factor,

        sum(
            case
                when risk_present = 0
                    and diagnosis_code = 1
                then 1
                else 0
            end
        ) as diagnosed_without_factor

    from risk_factor_records

    group by
        risk_factor,
        display_order

)

select
    risk_factor as risk_factor_key,
    risk_factor,
    display_order,
    total_patients,
    patients_with_factor,
    patients_without_factor,
    diagnosed_with_factor,
    diagnosed_without_factor,

    round(
        100.0
        * patients_with_factor
        / nullif(total_patients, 0),
        2
    ) as factor_prevalence_pct,

    round(
        100.0
        * diagnosed_with_factor
        / nullif(patients_with_factor, 0),
        2
    ) as diagnosis_rate_with_factor_pct,

    round(
        100.0
        * diagnosed_without_factor
        / nullif(patients_without_factor, 0),
        2
    ) as diagnosis_rate_without_factor_pct,

    round(
        (
            100.0
            * diagnosed_with_factor
            / nullif(patients_with_factor, 0)
        )
        -
        (
            100.0
            * diagnosed_without_factor
            / nullif(patients_without_factor, 0)
        ),
        2
    ) as diagnosis_rate_difference_pct_points

from aggregated