<div align="center">

# 🍎 FastAPI Project Aliases — macOS

### Scaffold des projets **FastAPI** asynchrones et complets directement depuis **zsh**

Des fonctions courtes et mémorisables qui remplacent les longues séquences de configuration par une seule commande.

[![Zsh](https://img.shields.io/badge/Zsh-5.0%2B-CC5333?style=for-the-badge&logo=zsh&logoColor=white)](https://www.zsh.org/)
[![macOS](https://img.shields.io/badge/macOS-ready-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/macos/)
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

Les raccourcis sont organisés en modules thématiques chargés automatiquement depuis un **point d'entrée unique** : une seule ligne suffit dans votre configuration shell. Chaque fonction suit la même convention de nommage que les [versions Linux](../README.md#-installation-linux) et [Windows](../README.md#-installation-windows) (`new_fastapi` ⇄ `New-Fastapi`).

> 💡 Les scripts sont **écrits en zsh** et utilisent les outils BSD de macOS : aucune dépendance à bash 4+ ni aux utilitaires GNU.

---

## 🧰 Prérequis

| Exigence | Détail |
|---|---|
| **Système** | macOS (Catalina et ultérieur recommandé) |
| **Shell** | zsh (shell par défaut de macOS) |
| **Python** | Python 3.9+ avec `venv` disponible — via [Homebrew](https://brew.sh/) (`brew install python`) ou Xcode Command Line Tools |
| **Git** | Inclus dans Xcode Command Line Tools |
| **Base de données** *(optionnel)* | Serveur MySQL/MariaDB, PostgreSQL ou MongoDB |

---

## 📦 Installation

### 1. Copier le module dans votre répertoire de configuration

```bash
mkdir -p "$HOME/.config/alias"
cp -r macos "$HOME/.config/alias/fastapi-aliases-project/macos"
```

### 2. Charger les raccourcis

Ajoutez la ligne suivante à `~/.zshrc` (zsh, shell par défaut de macOS) :

```bash
. "$HOME/.config/alias/fastapi-aliases-project/macos/index.zsh"
```

`index.zsh` est le point d'entrée. Il source (`dot-source`) chaque module situé dans son propre répertoire, si bien que les raccourcis fonctionnent quel que soit l'endroit où le projet a été copié.

### 3. Recharger votre shell

```bash
source ~/.zshrc
```

---

## 🚀 Utilisation

Les raccourcis se comportent comme des commandes shell natives :

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
| `type <fonction>` | Affiche le type de la commande |
| `functions <fonction>` | Affiche le code source complet de la fonction |
| `whence -f <fonction>` | Affiche la définition du raccourci |

```bash
type new_fastapi
functions fastapi_database
```

---

## 🧹 Désinstallation

1. Supprimez la ligne d'import de `~/.zshrc`.
2. Supprimez le répertoire :

```bash
rm -rf "$HOME/.config/alias/fastapi-aliases-project"
```

---

## 🛟 Dépannage

| Symptôme | Solution |
|---|---|
| Les raccourcis sont indisponibles | Vérifiez le chemin d'import dans votre configuration shell, puis rechargez avec `source ~/.zshrc`. |
| `zsh: new_fastapi: command not found` | Vérifiez que le module a bien été sourcé (lancez `type new_fastapi`). |
| `python3: command not found` | Installez Python 3.9+ : `brew install python` (ou activez Xcode Command Line Tools). |
| `command not found: pip` | Assurez-vous d'être dans l'environnement virtuel activé (`source venv/bin/activate`) avant les commandes `pip`. |
| Erreurs liées à `venv` | Sur macOS, les Python via Homebrew incluent `venv` ; pour le Python système, installez les Command Line Tools. |

---

## 🤝 Contribution

Voir le [README du dépôt](../README.md#-contribution) pour les consignes de contribution, ou [ouvrir une issue](https://github.com/raharison-joshue-agape/ps-fastapi-aliases/issues).
