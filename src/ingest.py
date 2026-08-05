"""Ingest the source CSV into the Bronze layer without modifying it."""

from __future__ import annotations

import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd

from src.config import (
    BRONZE_FILE,
    BRONZE_METADATA_FILE,
    SOURCE_FILE,
    create_directories,
)


def calculate_sha256(file_path: Path) -> str:
    """Calculate the SHA-256 fingerprint of a file."""

    sha256 = hashlib.sha256()

    with file_path.open("rb") as file:
        for block in iter(lambda: file.read(1024 * 1024), b""):
            sha256.update(block)

    return sha256.hexdigest()


def ingest_to_bronze(
    source_file: Path = SOURCE_FILE,
    bronze_file: Path = BRONZE_FILE,
    metadata_file: Path = BRONZE_METADATA_FILE,
) -> dict:
    """
    Copy the source CSV into the Bronze layer.

    The Bronze file is kept unchanged to preserve the original data.
    """

    create_directories()

    if not source_file.exists():
        raise FileNotFoundError(
            f"Source file not found: {source_file}"
        )

    if source_file.suffix.lower() != ".csv":
        raise ValueError(
            f"The source file must be a CSV file: {source_file.name}"
        )

    # Copy the original file without transformation
    shutil.copy2(source_file, bronze_file)

    # Read the copied file only to obtain technical information
    dataframe = pd.read_csv(bronze_file)

    metadata = {
        "dataset_name": "Alzheimer's Disease Dataset",
        "source_file": source_file.name,
        "bronze_file": bronze_file.name,
        "ingestion_timestamp_utc": datetime.now(
            timezone.utc
        ).isoformat(),
        "file_size_bytes": bronze_file.stat().st_size,
        "sha256": calculate_sha256(bronze_file),
        "row_count": int(dataframe.shape[0]),
        "column_count": int(dataframe.shape[1]),
        "columns": dataframe.columns.tolist(),
    }

    with metadata_file.open(
        "w",
        encoding="utf-8",
    ) as file:
        json.dump(
            metadata,
            file,
            indent=4,
            ensure_ascii=False,
        )

    return metadata


if __name__ == "__main__":
    ingestion_metadata = ingest_to_bronze()

    print("Bronze ingestion completed successfully.")
    print(
        json.dumps(
            ingestion_metadata,
            indent=4,
            ensure_ascii=False,
        )
    )