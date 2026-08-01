# FastAPI Project Aliases — Windows

A curated collection of FastAPI scaffolding shortcuts that wrap everyday project setup operations for PowerShell on Windows.

## Overview

Instead of typing long, repetitive setup commands, you use short, memorable functions that scaffold a complete, asynchronous FastAPI project in seconds:

```powershell
New-Fastapi myapp        # scaffold a complete async FastAPI project
Fastapi-Database         # configure MySQL, PostgreSQL or MongoDB
Fastapi-Email            # wire up an async email service (aiosmtplib)
```

The aliases are organized into themed modules that load automatically from a single entry point, so only one line needs to be added to your PowerShell profile. Every function ships with comment-based help discoverable through `Get-Help`.

## Prerequisites

| Requirement | Details |
| --- | --- |
| Operating system | Windows 10 or 11 |
| Shell | Windows PowerShell 5.1+ or PowerShell 7 |
| Git | [Git for Windows](https://git-scm.com/download/win) installed and available in `PATH` |
| Python | Python 3.9+ available in `PATH` (used to scaffold each project) |

## Installation

### 1. Copy the module to your config directory

```powershell
New-Item -ItemType Directory -Path "$HOME\.config\alias" -Force
Copy-Item -Path "windows" -Destination "$HOME\.config\alias\fastapi-aliases-project\" -Recurse
```

### 2. Check whether a PowerShell profile exists

```powershell
Test-Path $PROFILE
```

- `True` → your profile already exists; continue to step 4.
- `False` → create it first:

```powershell
New-Item -Path $PROFILE -ItemType File -Force
```

### 3. Open your profile

```powershell
notepad $PROFILE
```

or with Visual Studio Code:

```powershell
code $PROFILE
```

### 4. Import the aliases

Append the following line to your profile:

```powershell
. "$HOME\.config\alias\fastapi-aliases-project\windows\index.ps1"
```

`index.ps1` is the entry point. It dot-sources every module located in its own directory, so the shortcuts work no matter where the project has been copied to.

### 5. Reload your profile

```powershell
. $PROFILE
```

## Module reference

Each module groups functions by topic:

| File | Functions |
| --- | --- |
| `create-fastapi-project.ps1` | `New-Fastapi`, `New-Fastapi-Project`, `Create-Fastapi`, `Create-Fastapi-Project` |
| `setup-fastapi-database.ps1` | `Fastapi-Database`, `Setup-Fastapi-Database` |
| `setup-fastapi-email.ps1` | `Fastapi-Email`, `Setup-Fastapi-Mail` |

## Usage

Aliases behave like ordinary PowerShell commands:

```powershell
New-Fastapi myapp        # scaffold a new async FastAPI project
Fastapi-Database         # choose MySQL, PostgreSQL or MongoDB
Fastapi-Email            # configure SMTP email sending
Get-Help New-Fastapi     # show parameters and examples
```

### Project scaffold

```powershell
New-Fastapi myapp
```

Creates a virtual environment, installs dependencies, and generates the full async project tree (`app/main.py`, `app/api/v1/...`, `tests/`, `requirements.txt`, `.env`, `.gitignore`).

### Database setup

```powershell
Fastapi-Database
```

Prompts for MySQL (default), PostgreSQL, or MongoDB. SQLAlchemy setups are generated fully asynchronous (`create_async_engine`, `AsyncSession`, async repositories and endpoints); MongoDB uses `motor`. For MySQL/PostgreSQL an Alembic environment is initialized.

### Email setup

```powershell
Fastapi-Email
```

Installs `aiosmtplib` and `Jinja2`, creates the template folders, and generates an async `EmailService` plus the required `MAIL_*` settings.

## Built-in help

| Command | Description |
| --- | --- |
| `Get-Help <function>` | Show comment-based documentation for any alias, including parameters and examples |

```powershell
Get-Help New-Fastapi
Get-Help Fastapi-Database
```

## Uninstall

1. Remove the import line from `$PROFILE`.
2. Delete the directory:

```powershell
Remove-Item -Path "$HOME\.config\alias\fastapi-aliases-project" -Recurse -Force
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Aliases are unavailable | Verify the import path in `$PROFILE`, then reload with `. $PROFILE`. |
| `❌ python is not recognized` | Install Python 3.9+ and ensure it is available in `PATH`. |
| Profile not found | Confirm `$PROFILE` exists with `Test-Path $PROFILE`, creating it if necessary. |

## Contributing

See the [repository README](../README.md) for the full project overview, feature set, and contribution guidelines.
