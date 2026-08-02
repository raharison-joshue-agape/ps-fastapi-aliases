<div align="center">

# 🚀 FastAPI Project Aliases

### Des raccourcis CLI pour scaffold des projets **FastAPI** complets et **100 % asynchrones** en quelques secondes

Un ensemble de fonctions pour **Bash (Linux/macOS)** et **PowerShell (Windows)** qui génèrent une base de code FastAPI moderne, structurée et prête à l'emploi — sans perdre de temps à tout recréer à chaque projet.

---

[![GitHub stars](https://img.shields.io/github/stars/raharison-joshue-agape/ps-fastapi-aliases?style=for-the-badge&logo=github&logoColor=white&color=gold)](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/raharison-joshue-agape/ps-fastapi-aliases?style=for-the-badge&logo=github&logoColor=white&color=blue)](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/forks)
[![GitHub issues](https://img.shields.io/github/issues/raharison-joshue-agape/ps-fastapi-aliases?style=for-the-badge&logo=github&logoColor=white&color=red)](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/issues)
[![License](https://img.shields.io/github/license/raharison-joshue-agape/ps-fastapi-aliases?style=for-the-badge&color=green)](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/blob/main/LICENSE)
[![Repo size](https://img.shields.io/github/repo-size/raharison-joshue-agape/ps-fastapi-aliases?style=for-the-badge&logo=github&logoColor=white)]()

[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-async-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Linux](https://img.shields.io/badge/Linux-ready-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
[![macOS](https://img.shields.io/badge/macOS-ready-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Windows](https://img.shields.io/badge/Windows-ready-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://www.microsoft.com/windows)

</div>

---

## 📑 Table des matières

- [✨ Fonctionnalités](#-fonctionnalités)
- [⚡ Démarrage rapide](#-démarrage-rapide)
- [🧰 Prérequis](#-prérequis)
- [🐧 Installation Linux](#-installation-linux)
- [🍎 Installation macOS](#-installation-macos)
- [🪟 Installation Windows](#-installation-windows)
- [🔧 Référence des commandes](#-référence-des-commandes)
- [🧩 Architecture et modules](#-architecture-et-modules)
- [📂 Structure du projet](#-structure-du-projet)
- [📖 Aide intégrée](#-aide-intégrée)
- [🧹 Désinstallation](#-désinstallation)
- [🛟 Dépannage](#-dépannage)
- [🤝 Contribution](#-contribution)
- [📄 Licence](#-licence)

---

## ✨ Fonctionnalités

| | |
|---|---|
| ⚡ **Scaffolding en une commande** | Génère un projet FastAPI structuré (API versionnée, core, services, tests, `.env`, `.gitignore`) depuis une seule commande |
| ⚙️ **100 % asynchrone** | `async def` partout : endpoints, `create_async_engine`/`AsyncSession`, `motor`, `aiosmtplib`, `aiofiles` |
| 🗄️ **Multi-base de données** | MySQL, PostgreSQL (SQLAlchemy async) ou MongoDB (`motor`) au choix, avec Alembic initialisé |
| 📧 **Service email** | `EmailService` asynchrone avec templates Jinja2, configuration SMTP complète et **API de test dédiée** |
| 📁 **Uploads de fichiers** | Service asynchrone (images, documents) avec validation taille/extension et serveur statique `/uploads` |
| 🧩 **Architecture modulaire** | Modules thématiques (projet, base de données, email, uploads) chargés depuis un point d'entrée unique |
| 🧠 **Multi-plateforme** | Mêmes commandes, mêmes options, mêmes templates : `new_fastapi` ⇄ `New-Fastapi` |
| 🍎 **macOS / Bash** | Scripts `.sh` compatibles bash 3.2+ intégré (et zsh) + outils BSD |
| ✅ **Feedback clair** | Messages de progression et de succès à chaque étape de l'installation |

---

## ⚡ Démarrage rapide

> ⏱️ Installation en moins d'une minute : copier le dossier, ajouter une ligne, recharger.

```bash
# Linux — ajouter à ~/.bashrc
. ~/.config/alias/fastapi-aliases-project/linux/index.sh
```

```bash
# macOS — ajouter à ~/.zshrc (ou ~/.bash_profile)
. ~/.config/alias/fastapi-aliases-project/macos/index.sh
```

```powershell
# Windows — ajouter au $PROFILE
. "$HOME\.config\alias\fastapi-aliases-project\windows\index.ps1"
```

```bash
# Puis, créer son premier projet :
new_fastapi myapp
cd myapp && source venv/bin/activate
uvicorn app.main:app --reload   # → http://127.0.0.1:8000/docs
```

---

## 🧰 Prérequis

| Exigence | Détail |
|---|---|
| **Python** | 3.9+ avec `venv` et `pip` disponibles dans le `PATH` |
| **Git** | Installé et accessible (pour l'initialisation optionnelle du projet) |
| **Linux** | bash 4.0+ (ou zsh) |
| **macOS** | bash 3.2+ intégré ou zsh (shell par défaut) |
| **Windows** | Windows 10/11, Windows PowerShell 5.1+ ou PowerShell 7 |
| **Base de données** *(optionnel)* | MySQL/MariaDB, PostgreSQL ou MongoDB |

---

## 🐧 Installation Linux

### 1. Copier les fichiers dans votre répertoire de configuration

```bash
mkdir -p ~/.config/alias
cp -r linux ~/.config/alias/fastapi-aliases-project/
```

### 2. Ouvrir votre fichier de configuration shell

```bash
nano ~/.bashrc        # Bash
nano ~/.zshrc         # Zsh
```

### 3. Importer les aliases

Ajoutez cette ligne à la fin du fichier :

```bash
. ~/.config/alias/fastapi-aliases-project/linux/index.sh
```

### 4. Recharger votre configuration

```bash
source ~/.bashrc      # ou : source ~/.zshrc
```

### 5. Créer votre premier projet

```bash
new_fastapi myapp
cd myapp && source venv/bin/activate
uvicorn app.main:app --reload
```

---

## 🍎 Installation macOS

### 1. Copier les fichiers dans votre répertoire de configuration

```bash
mkdir -p ~/.config/alias
cp -r macos ~/.config/alias/fastapi-aliases-project/
```

### 2. Ouvrir votre fichier de configuration shell

```bash
nano ~/.zshrc          # Zsh (shell par défaut de macOS)
nano ~/.bash_profile   # Bash
```

### 3. Importer les aliases

Ajoutez cette ligne à la fin du fichier :

```bash
. ~/.config/alias/fastapi-aliases-project/macos/index.sh
```

### 4. Recharger votre configuration

```bash
source ~/.zshrc        # ou : source ~/.bash_profile
```

### 5. Créer votre premier projet

```bash
new_fastapi myapp
cd myapp && source venv/bin/activate
uvicorn app.main:app --reload
```

> 💡 Les scripts sont compatibles avec le **bash 3.2 embarqué** de macOS (aucune dépendance bash 4+ ni outil GNU) et fonctionnent sous **zsh**.

---

## 🪟 Installation Windows

### 1. Copier les fichiers dans votre répertoire de configuration

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
notepad $PROFILE      # ou : code $PROFILE
```

### 4. Importer les aliases

Ajoutez cette ligne à votre profil :

```powershell
. "$HOME\.config\alias\fastapi-aliases-project\windows\index.ps1"
```

### 5. Recharger votre profil

```powershell
. $PROFILE
```

### 6. Créer votre premier projet

```powershell
New-Fastapi myapp
cd myapp
.\venv\Scripts\Activate
uvicorn app.main:app --reload
```

---

## 🔧 Référence des commandes

Les fonctions se comportent comme des commandes natives et acceptent les mêmes arguments sur les trois plateformes.

### 🚀 Créer un projet

```bash
# Linux / macOS (Bash)
new_fastapi myapp
new_fastapi_project myapp
create_fastapi myapp
create_fastapi_project myapp
```

```powershell
# Windows (PowerShell)
New-Fastapi myapp
New-Fastapi-Project myapp
Create-Fastapi myapp
Create-Fastapi-Project myapp
```

Crée un environnement virtuel, installe les dépendances, et génère l'arborescence asynchrone complète :

```
myapp/
├── app/
│   ├── main.py               # FastAPI async + lifespan + CORS + sessions
│   ├── api/v1/router.py      # Routeur principal
│   ├── api/v1/endpoints/     # health.py (async)
│   ├── core/config.py        # Settings pydantic (.env)
│   └── services/             # response_service.py
├── tests/test_health.py      # Test async (AsyncClient)
├── requirements.txt
├── pytest.ini
├── .env / .env.example
└── .gitignore
```

> 💡 Le nom du projet est optionnel : laissez vide pour le saisir interactivement.

### 🗄️ Configurer la base de données

```bash
# Linux / macOS
fastapi_database
# Windows
Fastapi-Database
```

| Choix | Base de données | Stack générée |
|---|---|---|
| `1` | MySQL / MariaDB | SQLAlchemy async + `aiomysql` + Alembic |
| `2` | PostgreSQL | SQLAlchemy async + `asyncpg` + Alembic |
| `3` | MongoDB | `motor` (100 % async) |

Génère la couche complète : `session.py` (`create_async_engine`, `AsyncSessionLocal`), `deps.py`, modèle `User`, `user_repository.py`, `user_service.py`, endpoints CRUD asynchrones, et `alembic/env.py` async.

### 📧 Configurer le service email

```bash
# Linux / macOS
fastapi_email
# Windows
Fastapi-Email
```

Installe `aiosmtplib` et `Jinja2`, crée `app/templates/emails/`, et génère un `EmailService` asynchrone (`send_email`, rendu de template) avec la configuration `MAIL_*`.

Une **API de test** complète est également générée et enregistrée sous `/email` :

| Endpoint | Description |
|---|---|
| `GET /api/v1/email/templates` | Liste les templates HTML disponibles dans `app/templates/emails` |
| `POST /api/v1/email/preview` | Prévisualise le rendu HTML d'un template avec des données dynamiques |
| `POST /api/v1/email/send` | Envoie un e-mail réel via `EmailService` (SMTP) |

Avec :
- `app/schemas/email.py` — `EmailTemplateRead`, `EmailPreviewRequest` (template_name + `data`), `EmailTestRequest` (`to` validé en `EmailStr`, `subject`, `template_name`, `data`)
- `app/templates/emails/welcome.html` — template d'exemple Jinja2 utilisant `{{ name }}`, `{{ message }}` et `{{ app_name }}`

```bash
# Prévisualiser le template welcome
curl -X POST http://127.0.0.1:8000/api/v1/email/preview \
  -H "Content-Type: application/json" \
  -d '{"template_name": "welcome", "data": {"name": "Alice"}}'

# Envoyer un e-mail de test
curl -X POST http://127.0.0.1:8000/api/v1/email/send \
  -H "Content-Type: application/json" \
  -d '{"to": "destinataire@exemple.com", "subject": "Bienvenue !", "template_name": "welcome", "data": {"name": "Alice"}}'
```

### 📁 Configurer les uploads de fichiers

```bash
# Linux / macOS
fastapi_upload
# Windows
Fastapi-Upload
```

Installe `python-multipart` et `aiofiles`, crée l'arborescence de stockage (`app/uploads/images`, `app/uploads/documents`), et génère un `UploadService` asynchrone avec :

| Endpoint | Description |
|---|---|
| `POST /api/v1/upload/` | Upload d'un fichier (image ou document) |
| `POST /api/v1/upload/many` | Upload de plusieurs fichiers |
| `DELETE /api/v1/upload/{path}` | Suppression d'un fichier (protégé contre les traversées de chemin) |

Validation de l'extension (HTTP 415) et de la taille max `MAX_UPLOAD_SIZE` (HTTP 413), nommage par UUID, catégorisation automatique `images/` vs `documents/`, et service statique `/uploads`.

---

## 🧩 Architecture et modules

L'implémentation suit une **architecture modulaire en couches**, chaque couche ayant une responsabilité unique :

```
 Terminal / Shell de l'utilisateur
      │      (~/.bashrc | ~/.zshrc | $PROFILE)
      ▼
┌────────────────────────────┐
│    index.sh / index.ps1    │  Point d'entrée — charge tous les modules
└────────────┬───────────────┘
             ▼
┌────────────────────────────┐
│  Modules thématiques       │  create-fastapi-project.sh/.ps1
│                            │  setup-fastapi-database.sh/.ps1
│                            │  setup-fastapi-email.sh/.ps1
│                            │  setup-fastapi-upload.sh/.ps1
└────────────┬───────────────┘
             ▼
┌────────────────────────────┐
│  Helpers partagés          │  fastapi_update_api_router / update_env_files
│                            │  gestion config.py, .env, router, main.py
└────────────┬───────────────┘
             ▼
        Projet FastAPI
        (venv + templates générés)
```

- **`index.sh` / `index.ps1`** : source l'ensemble des modules situés dans son propre répertoire, quel que soit l'endroit où le projet a été copié.
- **Modules thématiques** : chacun expose les fonctions publiques d'un domaine (projet, base de données, email, uploads).
- **Helpers partagés** : portent la logique transversale (mise à jour du router, des `.env`, de la config).
- Les trois implémentations (`linux/`, `macos/` et `windows/`) sont **fonctionnellement équivalentes** : mêmes commandes, mêmes options, mêmes templates générés.

| Fichier (Linux / macOS / Windows) | Fonctions |
|---|---|
| `create-fastapi-project.sh` / `.ps1` | `new_fastapi`, `new_fastapi_project`, `create_fastapi`, `create_fastapi_project` / `New-Fastapi`, `New-Fastapi-Project`, `Create-Fastapi`, `Create-Fastapi-Project` |
| `setup-fastapi-database.sh` / `.ps1` | `fastapi_database`, `setup_fastapi_database` / `Fastapi-Database`, `Setup-Fastapi-Database` |
| `setup-fastapi-email.sh` / `.ps1` | `fastapi_email`, `setup_fastapi_mail` / `Fastapi-Email`, `Setup-Fastapi-Mail` |
| `setup-fastapi-upload.sh` / `.ps1` | `fastapi_upload`, `setup_fastapi_upload` / `Fastapi-Upload`, `Setup-Fastapi-Upload` |

> 💡 **macOS** expose les **mêmes noms de fonctions que Linux** (scripts `.sh`) — seule l'installation diffère (`~/.zshrc` / `~/.bash_profile`).

---

## 📂 Structure du projet

```
fastapi-aliases-project/
├── linux/                    # Implémentation Bash pour Linux
│   ├── index.sh              # Point d'entrée (charge tous les modules)
│   ├── create-fastapi-project.sh    # new_fastapi, create_fastapi, ...
│   ├── setup-fastapi-database.sh    # fastapi_database (SQLAlchemy async / motor)
│   ├── setup-fastapi-email.sh       # fastapi_email (aiosmtplib + Jinja2)
│   ├── setup-fastapi-upload.sh      # fastapi_upload (aiofiles + /uploads)
│   └── README.md             # Guide d'installation Linux
├── macos/                    # Implémentation Bash pour macOS (zsh/bash 3.2+)
│   ├── index.sh              # Point d'entrée (charge tous les modules)
│   ├── create-fastapi-project.sh    # new_fastapi, create_fastapi, ...
│   ├── setup-fastapi-database.sh    # fastapi_database (SQLAlchemy async / motor)
│   ├── setup-fastapi-email.sh       # fastapi_email (aiosmtplib + Jinja2)
│   ├── setup-fastapi-upload.sh      # fastapi_upload (aiofiles + /uploads)
│   └── README.md             # Guide d'installation macOS
├── windows/                  # Implémentation PowerShell pour Windows
│   ├── index.ps1             # Point d'entrée (charge tous les modules)
│   ├── create-fastapi-project.ps1   # New-Fastapi, Create-Fastapi, ...
│   ├── setup-fastapi-database.ps1   # Fastapi-Database (SQLAlchemy async / motor)
│   ├── setup-fastapi-email.ps1      # Fastapi-Email (aiosmtplib + Jinja2)
│   ├── setup-fastapi-upload.ps1     # Fastapi-Upload (aiofiles + /uploads)
│   └── README.md             # Guide d'installation Windows
└── README.md                 # Ce fichier
```

---

## 📖 Aide intégrée

Chaque fonction dispose d'une documentation intégrée, découvrable directement dans votre shell :

| Commande (Linux / macOS) | Commande (Windows) | Description |
|---|---|---|
| `type <fonction>` | `Get-Help <fonction>` | Affiche la définition / documentation d'une fonction |
| `declare -f <fonction>` | `Get-Command <fonction>` | Détails d'implémentation |

```bash
# Linux / macOS
type new_fastapi
declare -f fastapi_database
```

```powershell
# Windows
Get-Help New-Fastapi
Get-Command Fastapi-Database
```

---

## 🧹 Désinstallation

### Linux

1. Supprimez la ligne d'import de `~/.bashrc` (ou `~/.zshrc`).
2. Supprimez le répertoire :

```bash
rm -rf ~/.config/alias/fastapi-aliases-project
```

### macOS

1. Supprimez la ligne d'import de `~/.zshrc` (ou `~/.bash_profile`).
2. Supprimez le répertoire :

```bash
rm -rf ~/.config/alias/fastapi-aliases-project
```

### Windows

1. Supprimez la ligne d'import de `$PROFILE`.
2. Supprimez le répertoire :

```powershell
Remove-Item -Path "$HOME\.config\alias\fastapi-aliases-project" -Recurse -Force
```

---

## 🛟 Dépannage

| Symptôme | Solution |
|---|---|
| Les fonctions ne fonctionnent pas | Vérifiez le chemin dans la ligne d'import, puis rechargez : `source ~/.bashrc` (Linux) · `source ~/.zshrc` (macOS) · `. $PROFILE` (Windows) |
| `command not found: new_fastapi` / `Get-Help` ne retourne rien | Les fonctions ne sont pas chargées : confirmez la présence de la ligne d'import correspondant à votre plateforme dans votre fichier de configuration |
| `python3: command not found` | Installez Python 3.9+ et assurez-vous qu'il est disponible dans le `PATH` — macOS : `brew install python` |
| `venv` ne se crée pas | Sous Debian/Ubuntu : `sudo apt install python3-venv` · macOS : activez Xcode Command Line Tools |
| `Module not found: ...` | Un fichier de module est absent — réinstallez le dossier `linux/`, `macos/` ou `windows/` en entier |
| `aiomysql` / `asyncpg` indisponibles | Vérifiez que votre base de données est démarrée et que les credentials dans `.env` sont corrects |
| Uvicorn ne démarre pas | Confirmez que l'environnement virtuel est activé et que les dépendances sont installées (`pip install -r requirements.txt`) |

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. **Fork** le dépôt et créez une branche : `git checkout -b feature/ma-fonctionnalite`
2. **Implémentez** votre changement en respectant l'équivalence Linux/macOS/Windows existante
3. **Testez** vos scripts avant de soumettre
4. **Ouvrez une pull request** avec une description claire de vos modifications

Voir les [issues](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/issues) pour les tâches ouvertes.

---

## 📄 Licence

Ce projet est distribué sous licence open source. Vous pouvez l'utiliser, le modifier et le partager librement.

---

<div align="center">

**Fait avec ❤️ par [Joshué Agapé](https://github.com/raharison-joshue-agape)** — Star ⭐ sur [GitHub](https://github.com/raharison-joshue-agape/ps-fastapi-aliases) si ce projet vous est utile !

</div>
