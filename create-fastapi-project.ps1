function fastapi_config {
    param([Parameter(Mandatory = $true)][string]$fastProjectName)

    return @"
import json
from typing import List
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = '$fastProjectName'
    ENV: str = "development"
    debug: bool = True
    version: str = "1.0.0"

    CORS_ORIGINS: List[str]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def parse_json_list(cls, v):
        if isinstance(v, str):
            return json.loads(v)
        return v

settings = Settings()
"@
}


$fastapi_router_content = @'
from fastapi import APIRouter
from app.api.v1.endpoints import health

api_router = APIRouter()

api_router.include_router(health.router, prefix="/health", tags=["Health"])
'@


$fastapi_response_service_content = @'
from typing import Any
from fastapi.responses import JSONResponse


class ServiceResponse:
    @staticmethod
    def success(
        data: Any = None,
        message: str = "Success",
        status_code: int = 200
    ):
        return JSONResponse(
            content={
                "success": True,
                "status_code": status_code,
                "message": message,
                "data": data
            }
        )

    @staticmethod
    def error(
        message: str = "Error",
        status_code: int = 400,
        data: Any = None
    ):
        return JSONResponse(
            content={
                "success": False,
                "status_code": status_code,
                "message": message,
                "data": data
            }
        )
'@


$fastapi_health_content = @'
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def health_check():
    return {"status": "ok"}
'@


$fastapi_main_content = @'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.sessions import SessionMiddleware

from app.api.v1.router import api_router
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    debug=settings.debug
)

app.add_middleware(
    SessionMiddleware,
    secret_key="SUPER_SECRET_KEY",
    same_site="lax",
    https_only=False   # localhost
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix="/api/v1")
'@


$fastapi_test_content = @'
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health_check():
    response = client.get("/api/v1/health/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
'@


$fastapi_git_ignore_content = @'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Virtual environments
venv/
.env
.venv/

# IDE / Editor files
.vscode/
.idea/

# Logs
*.log

# pytest cache
.pytest_cache/

# Migrations (si jamais tu ajoutes une DB)
migrations/
'@


$fastapi_pytest_content = @'
[pytest]
pythonpath = .
python_files = test_*.py
'@


$fastapi_readme_content = @'
# Lancer le serveur

```bash
uvicorn app.main:app --reload
```

## Lancer les tests

```bash
pytest
```
'@


$fastapi_env_content = @'
APP_NAME=Clean FastAPI App
DEBUG=True
VERSION=1.0.0

CORS_ORIGINS='["*"]'

'@


function New-Fastapi {
    param(
        [string]$PROJECT_NAME
    )

    if (-not $PROJECT_NAME) {
        $PROJECT_NAME = Read-Host "Project name :"
    }

    New-Item -ItemType Directory -Path $PROJECT_NAME -Force | Out-Null
    Set-Location $PROJECT_NAME

    Write-Host "🔹 Creating virtual environment"
    python -m venv venv

    Write-Host "🔹 Activating virtual environment"
    & .\venv\Scripts\Activate.ps1

    Write-Host "🔹 Upgrading pip"
    python -m pip install --upgrade pip

    Write-Host "🔹 Installing dependencies..."
    pip install fastapi uvicorn pydantic pydantic-settings pytest httpx itsdangerous
    pip freeze > requirements.txt

    $dirs = @(
        "app/api/v1/endpoints",
        "app/core",
        "app/services",
        "tests"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    $fastapi_config_content = fastapi_config $PROJECT_NAME
    Set-Content "app/core/config.py" -Value $fastapi_config_content -Encoding UTF8
    Set-Content "app/api/v1/router.py" -Value $fastapi_router_content -Encoding UTF8
    Set-Content "app/services/response_service.py" -Value $fastapi_response_service_content -Encoding UTF8
    Set-Content "app/api/v1/endpoints/health.py" -Value $fastapi_health_content -Encoding UTF8
    Set-Content "app/main.py" -Value $fastapi_main_content -Encoding UTF8
    Set-Content "tests/test_health.py" -Value $fastapi_test_content -Encoding UTF8
    Set-Content ".gitignore" -Value $fastapi_git_ignore_content -Encoding UTF8
    Set-Content "pytest.ini" -Value $fastapi_pytest_content -Encoding UTF8
    Set-Content "README.md" -Value $fastapi_readme_content -Encoding UTF8
    Set-Content ".env" -Value $fastapi_env_content -Encoding UTF8
    Set-Content ".env.example" -Value $fastapi_env_content -Encoding UTF8

    $GIT = Read-Host "Would you like to initialize Git? (Y/N)"
    if ($GIT.Trim() -match '^[Yy]') {
        git init
        git add -A
        git commit -m "Initial commit"
    }

    Write-Host "Project '$fastProjectName' has been created successfully!"
    Write-Host "🔹 Activate the virtual environment:"
    Write-Host "        venv\Scripts\Activate"
    Write-Host "🔹 Start the FastAPI server:"
    Write-Host "        uvicorn app.main:app --reload"
    Write-Host "🔹 Run tests:"
    Write-Host "        pytest <test_file>"
}


function New-Fastapi-Project {
    param(
        [string]$PROJECT_NAME
    )
    New-Fastapi $PROJECT_NAME
}


function Create-Fastapi {
    param(
        [string]$PROJECT_NAME
    )
    New-Fastapi $PROJECT_NAME
}


function Create-Fastapi-Project {
    param(
        [string]$PROJECT_NAME
    )
    New-Fastapi $PROJECT_NAME
}