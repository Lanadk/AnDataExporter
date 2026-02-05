# Assemblée Nationale – Data Pipeline

Ce projet permet de **télécharger, parser et importer** les données open data de l’Assemblée nationale  
(acteurs, scrutins, etc.) de manière **fiable, traçable et maintenable**.

Le pipeline est **piloté par la base de données**, pas par le code.

---

## 🎯 Objectifs

- Télécharger les données officielles de l’Assemblée nationale
- Distinguer clairement :
    - les **archives** (immutables)
    - la **législature courante** (mise à jour régulièrement)
- Pouvoir relancer les scripts **sans doublons ni incohérences**
- Préparer une base exploitable pour l’analyse et les applications

---

## 🧠 Principe clé

> **Le code ne décide jamais ce qui est “current” ou “archive”.**
>
> 👉 C’est la base de données qui pilote le workflow.

---

## 🔁 Workflow global


Chaque étape est :
- indépendante
- traçable en base

---

## 1️⃣ Download

### Rôle
- Télécharger les fichiers ZIP / JSON depuis data.assemblee-nationale.fr
- Télécharger :
    - **une seule fois** les archives
    - **régulièrement** la législature courante
- Mettre à jour l’état de téléchargement en base

### Pilotage
Tables utilisées :
- `param_legislatures` Table de parametrage des legislatures
- `ref_data_domains` Table de refentiel des domains métier qu'on exploite
- `param_data_sources` Table de parametrage des sources de données de l'AN (nos urls)
- `data_download` Table de monitoring des fichiers téléchargés

---

## 2️⃣ Parse

### Rôle
- Lire les JSON bruts
- Valider la structure
- Normaliser / transformer les données
- Générer des fichiers intermédiaires propres

---

## 3️⃣ Import

### Rôle
- Importer les données parsées en base métier
- Gérer :
 //TODO 

---

## 4️⃣ Update current

### Rôle
- Garantir que **la législature courante est la seule version active**
- Les archives restent accessibles mais figées
- Assurer la mise à jours des données de la législature courante

