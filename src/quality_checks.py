"""Contrôles de qualité de la couche Bronze."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any

import pandas as pd

from src.config import (
    BINARY_COLUMNS,
    BRONZE_FILE,
    CATEGORY_RULES,
    EXPECTED_COLUMNS,
    QUALITY_CSV_FILE,
    QUALITY_JSON_FILE,
    RANGE_RULES,
    create_directories,
)


def create_check(
    check_name: str,
    status: str,
    observed: Any,
    expected: Any,
    details: str,
) -> dict:
    """Créer le résultat standardisé d'un contrôle."""

    return {
        "check_name": check_name,
        "status": status,
        "observed": observed,
        "expected": expected,
        "details": details,
    }


def check_schema(dataframe: pd.DataFrame) -> list[dict]:
    """Vérifier les colonnes du dataset."""

    actual_columns = dataframe.columns.tolist()

    missing_columns = [
        column
        for column in EXPECTED_COLUMNS
        if column not in actual_columns
    ]

    unexpected_columns = [
        column
        for column in actual_columns
        if column not in EXPECTED_COLUMNS
    ]

    checks = [
        create_check(
            check_name="column_count",
            status=(
                "PASS"
                if len(actual_columns) == len(EXPECTED_COLUMNS)
                else "FAIL"
            ),
            observed=len(actual_columns),
            expected=len(EXPECTED_COLUMNS),
            details="Vérification du nombre total de colonnes.",
        ),
        create_check(
            check_name="missing_columns",
            status="PASS" if not missing_columns else "FAIL",
            observed=missing_columns,
            expected=[],
            details="Vérification des colonnes obligatoires manquantes.",
        ),
        create_check(
            check_name="unexpected_columns",
            status="PASS" if not unexpected_columns else "WARNING",
            observed=unexpected_columns,
            expected=[],
            details="Vérification des colonnes non prévues.",
        ),
    ]

    return checks


def check_missing_values(dataframe: pd.DataFrame) -> list[dict]:
    """Vérifier les valeurs manquantes."""

    missing_by_column = dataframe.isna().sum()
    total_missing = int(missing_by_column.sum())

    missing_details = {
        column: int(value)
        for column, value in missing_by_column.items()
        if value > 0
    }

    return [
        create_check(
            check_name="missing_values",
            status="PASS" if total_missing == 0 else "WARNING",
            observed=total_missing,
            expected=0,
            details=json.dumps(
                missing_details,
                ensure_ascii=False,
            ),
        )
    ]


def check_duplicates(dataframe: pd.DataFrame) -> list[dict]:
    """Vérifier les doublons et l'unicité de PatientID."""

    duplicated_rows = int(dataframe.duplicated().sum())

    duplicated_patient_ids = int(
        dataframe["PatientID"].duplicated().sum()
    )

    null_patient_ids = int(
        dataframe["PatientID"].isna().sum()
    )

    return [
        create_check(
            check_name="duplicated_rows",
            status="PASS" if duplicated_rows == 0 else "WARNING",
            observed=duplicated_rows,
            expected=0,
            details="Nombre de lignes complètement dupliquées.",
        ),
        create_check(
            check_name="duplicated_patient_ids",
            status=(
                "PASS"
                if duplicated_patient_ids == 0
                else "FAIL"
            ),
            observed=duplicated_patient_ids,
            expected=0,
            details="PatientID doit être unique.",
        ),
        create_check(
            check_name="null_patient_ids",
            status="PASS" if null_patient_ids == 0 else "FAIL",
            observed=null_patient_ids,
            expected=0,
            details="PatientID ne doit pas être vide.",
        ),
    ]


def check_binary_columns(dataframe: pd.DataFrame) -> list[dict]:
    """Vérifier que les variables binaires contiennent seulement 0 et 1."""

    checks = []

    for column in BINARY_COLUMNS:
        actual_values = set(
            dataframe[column].dropna().unique().tolist()
        )

        invalid_values = sorted(
            actual_values - {0, 1}
        )

        checks.append(
            create_check(
                check_name=f"binary_domain_{column}",
                status="PASS" if not invalid_values else "FAIL",
                observed=invalid_values,
                expected=[0, 1],
                details=(
                    f"La variable {column} doit contenir "
                    "uniquement 0 ou 1."
                ),
            )
        )

    return checks


def check_category_columns(dataframe: pd.DataFrame) -> list[dict]:
    """Vérifier les codes des variables catégorielles."""

    checks = []

    for column, allowed_values in CATEGORY_RULES.items():
        actual_values = set(
            dataframe[column].dropna().unique().tolist()
        )

        invalid_values = sorted(
            actual_values - allowed_values
        )

        checks.append(
            create_check(
                check_name=f"category_domain_{column}",
                status="PASS" if not invalid_values else "FAIL",
                observed=invalid_values,
                expected=sorted(allowed_values),
                details=f"Vérification des codes de {column}.",
            )
        )

    return checks


def check_numeric_ranges(dataframe: pd.DataFrame) -> list[dict]:
    """Vérifier les intervalles des variables numériques."""

    checks = []

    for column, limits in RANGE_RULES.items():
        minimum, maximum = limits

        values = pd.to_numeric(
            dataframe[column],
            errors="coerce",
        )

        out_of_range = (
            (values < minimum)
            | (values > maximum)
        )

        out_of_range_count = int(
            out_of_range.sum()
        )

        checks.append(
            create_check(
                check_name=f"numeric_range_{column}",
                status=(
                    "PASS"
                    if out_of_range_count == 0
                    else "FAIL"
                ),
                observed={
                    "minimum_observed": float(values.min()),
                    "maximum_observed": float(values.max()),
                    "out_of_range_count": out_of_range_count,
                },
                expected={
                    "minimum": minimum,
                    "maximum": maximum,
                },
                details=(
                    f"Vérification de l'intervalle numérique "
                    f"de {column}."
                ),
            )
        )

    return checks


def check_constant_columns(dataframe: pd.DataFrame) -> list[dict]:
    """Identifier les colonnes qui contiennent une seule valeur."""

    constant_columns = [
        column
        for column in dataframe.columns
        if dataframe[column].nunique(dropna=False) <= 1
    ]

    return [
        create_check(
            check_name="constant_columns",
            status="WARNING" if constant_columns else "PASS",
            observed=constant_columns,
            expected=[],
            details=(
                "Les colonnes constantes sont conservées dans Bronze, "
                "mais pourront être exclues de Silver."
            ),
        )
    ]


def run_quality_checks() -> dict:
    """Exécuter tous les contrôles et sauvegarder les rapports."""

    create_directories()

    if not BRONZE_FILE.exists():
        raise FileNotFoundError(
            "Le fichier Bronze n'existe pas. "
            "Exécutez d'abord : python -m src.ingest"
        )

    dataframe = pd.read_csv(BRONZE_FILE)

    checks = []

    checks.extend(check_schema(dataframe))
    checks.extend(check_missing_values(dataframe))
    checks.extend(check_duplicates(dataframe))
    checks.extend(check_binary_columns(dataframe))
    checks.extend(check_category_columns(dataframe))
    checks.extend(check_numeric_ranges(dataframe))
    checks.extend(check_constant_columns(dataframe))

    failed_checks = [
        check
        for check in checks
        if check["status"] == "FAIL"
    ]

    warning_checks = [
        check
        for check in checks
        if check["status"] == "WARNING"
    ]

    if failed_checks:
        overall_status = "FAIL"
    elif warning_checks:
        overall_status = "PASS_WITH_WARNINGS"
    else:
        overall_status = "PASS"

    report = {
        "generated_at_utc": datetime.now(
            timezone.utc
        ).isoformat(),
        "input_file": str(BRONZE_FILE),
        "row_count": int(dataframe.shape[0]),
        "column_count": int(dataframe.shape[1]),
        "overall_status": overall_status,
        "failed_check_count": len(failed_checks),
        "warning_count": len(warning_checks),
        "checks": checks,
    }

    with QUALITY_JSON_FILE.open(
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            report,
            file,
            indent=4,
            ensure_ascii=False,
            default=str,
        )

    checks_dataframe = pd.DataFrame(checks)

    checks_dataframe["observed"] = (
        checks_dataframe["observed"].apply(
            lambda value: json.dumps(
                value,
                ensure_ascii=False,
                default=str,
            )
            if isinstance(value, (dict, list))
            else value
        )
    )

    checks_dataframe["expected"] = (
        checks_dataframe["expected"].apply(
            lambda value: json.dumps(
                value,
                ensure_ascii=False,
                default=str,
            )
            if isinstance(value, (dict, list))
            else value
        )
    )

    checks_dataframe.to_csv(
        QUALITY_CSV_FILE,
        index=False,
        encoding="utf-8-sig",
    )

    return report


if __name__ == "__main__":
    quality_report = run_quality_checks()

    print("Data-quality checks completed.")
    print()
    print("Overall status:", quality_report["overall_status"])
    print("Rows:", quality_report["row_count"])
    print("Columns:", quality_report["column_count"])
    print(
        "Failed checks:",
        quality_report["failed_check_count"],
    )
    print(
        "Warnings:",
        quality_report["warning_count"],
    )