# Alzheimer Decision Analytics

Projet Fil Rouge réalisé dans le cadre de la formation Data Analyst.

## Objectif

Concevoir une solution data décisionnelle permettant d’analyser les profils
associés au diagnostic de la maladie d’Alzheimer à partir de données
synthétiques.

## Source des données

Dataset : Alzheimer's Disease Dataset  
Auteur : Rabie El Kharoua  
Source : Kaggle  
Lien : https://www.kaggle.com/datasets/rabieelkharoua/alzheimers-disease-dataset

Le dataset contient 2 149 observations et 35 variables.

> Les données sont synthétiques et utilisées uniquement à des fins pédagogiques.
> Ce projet ne constitue pas un dispositif médical.

## Architecture

Le projet utilise une architecture batch Medallion :

- Source : fichier d’origine ;
- Bronze : copie brute et traçable ;
- Silver : données nettoyées et enrichies ;
- Gold : tables analytiques et KPI destinés à Power BI.

## État actuel du projet

Les éléments suivants ont été réalisés :

- création de la structure du projet ;
- création de l’environnement Python ;
- installation des bibliothèques ;
- vérification du dataset ;
- création du fichier `config.py` ;
- création du script d’ingestion `ingest.py` ;
- ingestion du fichier dans la couche Bronze ;
- génération des métadonnées techniques ;
- calcul de l’empreinte SHA-256.

## Technologies

- Python 3.12
- pandas
- PyArrow
- DuckDB
- pytest
- Power BI

## Installation

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt