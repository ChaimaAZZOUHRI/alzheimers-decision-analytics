FROM apache/airflow:3.3.0-python3.12

COPY requirements.txt /requirements.txt

RUN pip install --no-cache-dir -r /requirements.txt

COPY --chown=airflow:root dbt_project /opt/airflow/dbt_project

ENV PYTHONPATH=/opt/airflow