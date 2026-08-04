<div align="center">

# ⚡ FastAPI Project Aliases — Windows

### Scaffold des projets **FastAPI** asynchrones et complets directement depuis **PowerShell**

Des fonctions courtes et mémorisables qui remplacent les longues séquences de configuration par une seule commande.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Windows](https://img.shields.io/badge/Windows-ready-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-async-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)

</div>

---

## 📑 Table des matières

- [✨ Aperçu](#-aperçu)
- [🧰 Prérequis](#-prérequis)
- [📦 Installation](#-installation)
- [🚀 Utilisation](#-utilisation)
- [📖 Aide intégrée](#-aide-intégrée)
- [🧹 Désinstallation](#-désinstallation)
- [🛟 Dépannage](#-dépannage)
- [🤝 Contribution](#-contribution)

---

## ✨ Aperçu

Au lieu de taper de longues commandes de configuration répétitives, vous utilisez des fonctions courtes qui scaffoldent un projet FastAPI complet et **100 % asynchrone** en quelques secondes :

```powershell
New-Fastapi myapp        # scaffold un projet FastAPI async complet
Fastapi-Database         # configure MySQL, PostgreSQL ou MongoDB
Fastapi-Email            # branche un service email async (aiosmtplib)
Fastapi-Pdf              # ajoute la génération de PDF (WeasyPrint recommandé)
Fastapi-Upload           # ajoute les uploads de fichiers async
```

Les raccourcis sont organisés en modules thématiques chargés automatiquement depuis un **point d'entrée unique** : une seule ligne suffit dans votre profil PowerShell. Chaque fonction dispose d'une aide commentée (`Get-Help`), et la syntaxe est identique à celle de la [version Linux](../README.md#-installation-linux) (`New-Fastapi` ⇄ `new_fastapi`).

---

## 🧰 Prérequis

| Exigence | Détail |
|---|---|
| **Système** | Windows 10 ou 11 |
| **Shell** | Windows PowerShell 5.1+ ou PowerShell 7 |
| **Git** | [Git for Windows](https://git-scm.com/download/win) installé et disponible dans le `PATH` |
| **Python** | Python 3.9+ disponible dans le `PATH` (utilisé pour scaffolder chaque projet) |

---

## 📦 Installation

### 1. Copier le module dans votre répertoire de configuration

```powershell
New-Item -ItemType Directory -Path "$HOME\.config\alias" -Force
Copy-Item -Path "windows" -Destination "$HOME\.config\alias\fastapi-aliases-project\" -Recurse
```

### 2. Vérifier que votre profil PowerShell existe

```powershell
Test-Path $PROFILE
```

- `True` → votre profil existe, passez à l'étape 4.
- `False` → créez-le :

```powershell
New-Item -Path $PROFILE -ItemType File -Force
```

### 3. Ouvrir votre profil

```powershell
notepad $PROFILE
```

ou avec Visual Studio Code :

```powershell
code $PROFILE
```

### 4. Importer les raccourcis

Ajoutez la ligne suivante à votre profil :

```powershell
. "$HOME\.config\alias\fastapi-aliases-project\windows\index.ps1"
```

`index.ps1` est le point d'entrée. Il source (`dot-source`) chaque module situé dans son propre répertoire, si bien que les raccourcis fonctionnent quel que soit l'endroit où le projet a été copié.

### 5. Recharger votre profil

```powershell
. $PROFILE
```

---

## 🚀 Utilisation

Les raccourcis se comportent comme des commandes PowerShell natives :

```powershell
New-Fastapi myapp        # scaffold un nouveau projet FastAPI async
Fastapi-Database         # choisir MySQL, PostgreSQL ou MongoDB
Fastapi-Email            # configurer l'envoi d'emails SMTP
Fastapi-Pdf              # configurer la génération de PDF
Fastapi-Upload           # configurer les uploads async
Get-Help New-Fastapi     # afficher les paramètres et exemples
```

### 📦 Créer un projet

```powershell
New-Fastapi myapp
```

Crée un environnement virtuel, installe les dépendances, et génère l'arborescence asynchrone complète (`app/main.py`, `app/api/v1/...`, `tests/`, `requirements.txt`, `.env`, `.gitignore`).

> 💡 Le nom du projet est optionnel : laissez vide pour le saisir interactivement.

### 🗄️ Configurer la base de données

```powershell
Fastapi-Database
```

Propose MySQL (par défaut), PostgreSQL ou MongoDB. Les setups SQLAlchemy sont générés **entièrement asynchrones** (`create_async_engine`, `AsyncSession`, repositories et endpoints async) ; MongoDB utilise `motor`. Pour MySQL/PostgreSQL, un environnement Alembic est initialisé.

### 📧 Configurer le service email

```powershell
Fastapi-Email
```

Installe `aiosmtplib` et `Jinja2`, crée les dossiers de templates, et génère un `EmailService` asynchrone ainsi que les réglages `MAIL_*` requis.

Une **API de test** complète est également générée et enregistrée sous `/email` :

| Endpoint | Description |
|---|---|
| `GET /api/v1/email/templates` | Liste les templates HTML disponibles dans `app/templates/emails` |
| `POST /api/v1/email/preview` | Prévisualise le rendu HTML d'un template avec des données dynamiques |
| `POST /api/v1/email/send` | Envoie un e-mail réel via `EmailService` (SMTP) |

Avec :
- `app/schemas/email.py` — `EmailTemplateRead`, `EmailPreviewRequest` (template_name + `data`), `EmailTestRequest` (`to` validé en `EmailStr`, `subject`, `template_name`, `data`)
- `app/templates/emails/welcome.html` — template d'exemple Jinja2 utilisant `{{ name }}`, `{{ message }}` et `{{ app_name }}`

```powershell
# Prévisualiser le template welcome
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/email/preview" `
  -ContentType "application/json" `
  -Body '{"template_name": "welcome", "data": {"name": "Alice"}}'

# Envoyer un e-mail de test
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/email/send" `
  -ContentType "application/json" `
  -Body '{"to": "destinataire@exemple.com", "subject": "Bienvenue !", "template_name": "welcome", "data": {"name": "Alice"}}'
```

### 📄 Configurer la génération de PDF

```powershell
Fastapi-Pdf
```

Propose le choix entre trois bibliothèques de génération de PDF :

| # | Bibliothèque | Description |
|---|---|---|
| 1 | **WeasyPrint** | **[RECOMMANDÉ]** Meilleure conversion HTML/CSS vers PDF, supporte les mises en page complexes, les règles CSS `@page` |
| 2 | ReportLab | Génération de PDF de bas niveau, contrôle programmatique, pas de support de templates HTML |
| 3 | FPDF2 | Léger et simple, génération de PDF basique, options de style limitées |

**WeasyPrint est recommandé** car il offre la meilleure expérience pour la conversion HTML vers PDF avec un support complet de CSS.

Une **API de test** complète est générée et enregistrée sous `/pdf` :

| Endpoint | Description |
|---|---|
| `POST /api/v1/pdf/generate` | Génère un PDF à partir d'un template Jinja2 |
| `GET /api/v1/pdf/templates` | Liste les templates HTML disponibles dans `app/templates/pdfs` |

Fichiers générés :
- `app/services/pdf_service.py` — Service de génération de PDF
- `app/schemas/pdf.py` — `PDFGenerateRequest` (template_name, data, output_filename)
- `app/api/v1/endpoints/pdf.py` — Endpoints API
- `app/templates/pdfs/invoice.html` — Template d'exemple (facture professionnelle)

```powershell
# Générer un PDF à partir du template invoice
Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/pdf/generate" `
  -ContentType "application/json" `
  -Body '{"template_name": "invoice", "data": {"title": "Facture #001", "from_name": "Mon Entreprise", "to_name": "Client Test", "date": "01/01/2025", "items": [{"description": "Service", "quantity": 1, "unit_price": "100.00", "total": "100.00"}], "subtotal": "100.00", "tax": "20.00", "total": "120.00"}}'
```

### 📁 Configurer les uploads de fichiers

```powershell
Fastapi-Upload
```

Installe `python-multipart` et `aiofiles`, crée l'arborescence de stockage (`app/uploads/images`, `app/uploads/documents`), et génère un `UploadService` asynchrone avec validation taille/extension, schemas et endpoints `POST`/`DELETE`. Les fichiers uploadés sont servis statiquement depuis `/uploads`.

---

## 📖 Aide intégrée

| Commande | Description |
|---|---|
| `Get-Help <fonction>` | Documentation commentée de n'importe quel raccourci (paramètres, exemples) |

```powershell
Get-Help New-Fastapi
Get-Help Fastapi-Database
```

---

## 🧹 Désinstallation

1. Supprimez la ligne d'import de `$PROFILE`.
2. Supprimez le répertoire :

```powershell
Remove-Item -Path "$HOME\.config\alias\fastapi-aliases-project" -Recurse -Force
```

---

## 🛟 Dépannage

| Symptôme | Solution |
|---|---|
| Les raccourcis sont indisponibles | Vérifiez le chemin d'import dans `$PROFILE`, puis rechargez avec `. $PROFILE`. |
| `❌ python is not recognized` | Installez Python 3.9+ et assurez-vous qu'il est disponible dans le `PATH`. |
| Profil introuvable | Vérifiez que `$PROFILE` existe avec `Test-Path $PROFILE`, en le créant si nécessaire. |

---

## 🤝 Contribution

Voir le [README du dépôt](../README.md#-contribution) pour les consignes de contribution, ou [ouvrir une issue](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/issues).
