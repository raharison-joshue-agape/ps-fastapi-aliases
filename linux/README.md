<div align="center">

# 🐧 FastAPI Project Aliases — Linux

### Scaffold des projets **FastAPI** asynchrones et complets directement depuis **bash**

Des fonctions courtes et mémorisables qui remplacent les longues séquences de configuration par une seule commande.

[![Bash](https://img.shields.io/badge/Bash-4.0%2B-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Linux-ready-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.linux.org/)
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

```bash
new_fastapi myapp       # scaffold un projet FastAPI async complet
fastapi_database        # configure MySQL, PostgreSQL ou MongoDB
fastapi_email           # branche un service email async (aiosmtplib)
fastapi_upload          # ajoute les uploads de fichiers async
```

Les raccourcis sont organisés en modules thématiques chargés automatiquement depuis un **point d'entrée unique** : une seule ligne suffit dans votre configuration shell. Chaque fonction suit la même convention de nommage que la [version Windows](../README.md#-installation-windows) (`new_fastapi` ⇄ `New-Fastapi`, `fastapi_database` ⇄ `Fastapi-Database`).

---

## 🧰 Prérequis

| Exigence | Détail |
|---|---|
| **Système** | Linux (ou Windows avec WSL) |
| **Shell** | bash 4+ (fonctionne aussi sous zsh) |
| **Python** | Python 3.9+ avec `venv` disponible |
| **Base de données** *(optionnel)* | Serveur MySQL/MariaDB, PostgreSQL ou MongoDB |

---

## 📦 Installation

### 1. Copier le module dans votre répertoire de configuration

```bash
mkdir -p "$HOME/.config/alias"
cp -r linux "$HOME/.config/alias/fastapi-aliases-project/linux"
```

### 2. Charger les raccourcis

Ajoutez la ligne suivante à `~/.bashrc` (ou `~/.zshrc`) :

```bash
. "$HOME/.config/alias/fastapi-aliases-project/linux/index.sh"
```

`index.sh` est le point d'entrée. Il source (`dot-source`) chaque module situé dans son propre répertoire, si bien que les raccourcis fonctionnent quel que soit l'endroit où le projet a été copié.

### 3. Recharger votre shell

```bash
source ~/.bashrc
```

---

## 🚀 Utilisation

Les raccourcis se comportent comme des commandes bash natives :

```bash
new_fastapi myapp        # scaffold un nouveau projet FastAPI async
fastapi_database         # choisir MySQL, PostgreSQL ou MongoDB
fastapi_email            # configurer l'envoi d'emails SMTP
fastapi_upload           # configurer les uploads async
```

### 📦 Créer un projet

```bash
new_fastapi myapp
```

Crée un environnement virtuel, installe les dépendances, et génère l'arborescence asynchrone complète (`app/main.py`, `app/api/v1/...`, `tests/`, `requirements.txt`, `.env`, `.gitignore`).

> 💡 Le nom du projet est optionnel : laissez vide pour le saisir interactivement.

### 🗄️ Configurer la base de données

```bash
fastapi_database
```

Propose MySQL (par défaut), PostgreSQL ou MongoDB. Les setups SQLAlchemy sont générés **entièrement asynchrones** (`create_async_engine`, `AsyncSession`, repositories et endpoints async) ; MongoDB utilise `motor`. Pour MySQL/PostgreSQL, un environnement Alembic est initialisé.

### 📧 Configurer le service email

```bash
fastapi_email
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
fastapi_upload
```

Installe `python-multipart` et `aiofiles`, crée l'arborescence de stockage (`app/uploads/images`, `app/uploads/documents`), et génère un `UploadService` asynchrone avec validation taille/extension, schemas et endpoints `POST`/`DELETE`. Les fichiers uploadés sont servis statiquement depuis `/uploads`.

---

## 📖 Aide intégrée

| Commande | Description |
|---|---|
| `type <fonction>` | Affiche la définition du raccourci |
| `declare -f <fonction>` | Affiche le code source complet de la fonction |
| `help <fonction>` | Affiche la documentation bash lorsqu'elle existe |

```bash
type new_fastapi
declare -f fastapi_database
```

---

## 🧹 Désinstallation

1. Supprimez la ligne d'import de `~/.bashrc` (ou `~/.zshrc`).
2. Supprimez le répertoire :

```bash
rm -rf "$HOME/.config/alias/fastapi-aliases-project"
```

---

## 🛟 Dépannage

| Symptôme | Solution |
|---|---|
| Les raccourcis sont indisponibles | Vérifiez le chemin d'import dans votre configuration shell, puis rechargez avec `source ~/.bashrc`. |
| `bash: new_fastapi: command not found` | Vérifiez que le module a bien été sourcé (lancez `type new_fastapi`). |
| `python3: command not found` | Installez Python 3.9+ et assurez-vous qu'il est disponible dans le `PATH`. |

---

## 🤝 Contribution

Voir le [README du dépôt](../README.md#-contribution) pour les consignes de contribution, ou [ouvrir une issue](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/issues).
