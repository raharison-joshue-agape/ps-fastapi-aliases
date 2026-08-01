# FastAPI Project Aliases — Linux

A curated collection of FastAPI scaffolding shortcuts that wrap everyday project setup operations for bash on Linux (and WSL).

## Overview

Instead of typing long, repetitive setup commands, you use short, memorable functions that scaffold a complete, asynchronous FastAPI project in seconds:

```bash
new_fastapi myapp       # scaffold a complete async FastAPI project
fastapi_database        # configure MySQL, PostgreSQL or MongoDB
fastapi_email           # wire up an async email service (aiosmtplib)
fastapi_upload          # add async file uploads (images, docs, ...)
```

The aliases are organized into themed modules that load automatically from a single entry point, so only one line needs to be added to your shell configuration. Every function follows the same naming convention as the Windows PowerShell module (`New-Fastapi` → `new_fastapi`, `Fastapi-Database` → `fastapi_database`, ...).

## Prerequisites

| Requirement | Details |
| --- | --- |
| Operating system | Linux (or Windows with WSL) |
| Shell | bash 4+ (also works under zsh) |
| Python | Python 3.9+ with `venv` available |
| Database (optional) | MySQL/MariaDB, PostgreSQL or MongoDB server |

## Installation

### 1. Copy the module to your config directory

```bash
mkdir -p "$HOME/.config/alias"
cp -r linux "$HOME/.config/alias/fastapi-aliases-project/linux"
```

### 2. Load the aliases

Append the following line to `~/.bashrc` (or `~/.zshrc`):

```bash
. "$HOME/.config/alias/fastapi-aliases-project/linux/index.sh"
```

`index.sh` is the entry point. It dot-sources every module located in its own directory, so the shortcuts work no matter where the project has been copied to.

### 3. Reload your shell

```bash
source ~/.bashrc
```

## Module reference

Each module groups functions by topic:

| File | Functions |
| --- | --- |
| `create-fastapi-project.sh` | `new_fastapi`, `new_fastapi_project`, `create_fastapi`, `create_fastapi_project` |
| `setup-fastapi-database.sh` | `fastapi_database`, `setup_fastapi_database` |
| `setup-fastapi-email.sh` | `fastapi_email`, `setup_fastapi_mail` |
| `setup-fastapi-upload.sh` | `fastapi_upload`, `setup_fastapi_upload` |

## Usage

Aliases behave like ordinary bash commands:

```bash
new_fastapi myapp        # scaffold a new async FastAPI project
fastapi_database         # choose MySQL, PostgreSQL or MongoDB
fastapi_email            # configure SMTP email sending
fastapi_upload           # configure async file uploads
```

### Project scaffold

```bash
new_fastapi myapp
```

Creates a virtual environment, installs dependencies, and generates the full async project tree (`app/main.py`, `app/api/v1/...`, `tests/`, `requirements.txt`, `.env`, `.gitignore`).

### Database setup

```bash
fastapi_database
```

Prompts for MySQL (default), PostgreSQL, or MongoDB. SQLAlchemy setups are generated fully asynchronous (`create_async_engine`, `AsyncSession`, async repositories and endpoints); MongoDB uses `motor`. For MySQL/PostgreSQL an Alembic environment is initialized.

### Email setup

```bash
fastapi_email
```

Installs `aiosmtplib` and `Jinja2`, creates the template folders, and generates an async `EmailService` plus the required `MAIL_*` settings.

### File upload setup

```bash
fastapi_upload
```

Installs `python-multipart` and `aiofiles`, creates the storage tree (`app/uploads/images`, `app/uploads/documents`), and generates an async `UploadService` with extension/size validation, schemas, and `POST`/`DELETE` endpoints. Uploaded files are served statically from `/uploads`.

## Built-in help

| Command | Description |
| --- | --- |
| `type <function>` | Show how the alias is defined |
| `declare -f <function>` | Print the full function source |
| `help <function>` | Show bash documentation when provided |

```bash
type new_fastapi
declare -f fastapi_database
```

## Uninstall

1. Remove the import line from `~/.bashrc` (or `~/.zshrc`).
2. Delete the directory:

```bash
rm -rf "$HOME/.config/alias/fastapi-aliases-project"
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Aliases are unavailable | Verify the import path in your shell config, then reload with `source ~/.bashrc`. |
| `bash: new_fastapi: command not found` | Confirm the module was sourced (run `type new_fastapi`). |
| `python3: command not found` | Install Python 3.9+ and make sure it is available in `PATH`. |

## Contributing

See the [repository README](../README.md) for the full project overview, feature set, and contribution guidelines.
