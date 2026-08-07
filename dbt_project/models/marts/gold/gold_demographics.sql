with patient_groups as (

    select
        patient_id,
        diagnosis_code,
        age,
        mmse,
        'Age group' as group_type,
        1 as group_type_order,
        cast(age_group as varchar) as group_value,
        case
            when age_group = '60-69' then 1
            when age_group = '70-79' then 2
            when age_group = '80-90' then 3
        end as category_order
    from {{ ref('stg_alzheimer_patients') }}

    union all

    select
        patient_id,
        diagnosis_code,
        age,
        mmse,
        'Gender' as group_type,
        2 as group_type_order,
        gender_label as group_value,
        case
            when gender_label = 'Male' then 1
            when gender_label = 'Female' then 2
        end as category_order
    from {{ ref('stg_alzheimer_patients') }}

    union all

    select
        patient_id,
        diagnosis_code,
        age,
        mmse,
        'Ethnicity' as group_type,
        3 as group_type_order,
        ethnicity_label as group_value,
        case
            when ethnicity_label = 'Caucasian' then 1
            when ethnicity_label = 'African American' then 2
            when ethnicity_label = 'Asian' then 3
            when ethnicity_label = 'Other' then 4
        end as category_order
    from {{ ref('stg_alzheimer_patients') }}

    union all

    select
        patient_id,
        diagnosis_code,
        age,
        mmse,
        'Education' as group_type,
        4 as group_type_order,
        education_label as group_value,
        case
            when education_label = 'None' then 1
            when education_label = 'High School' then 2
            when education_label = 'Bachelor''s' then 3
            when education_label = 'Higher Education' then 4
        end as category_order
    from {{ ref('stg_alzheimer_patients') }}

)

select
    group_type || '|' || group_value
        as demographic_key,

    group_type,
    group_type_order,
    group_value,
    category_order,

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
    round(avg(mmse), 2) as average_mmse

from patient_groups

group by
    group_type,
    group_type_order,
    group_value,
    category_order
