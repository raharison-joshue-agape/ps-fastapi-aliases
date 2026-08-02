#!/usr/bin/env bash
# FastAPI project scaffolding for macOS (bash).
# Compatible with the system bash 3.2 shipped with macOS.
# Mirrors the Windows PowerShell module (create-fastapi-project.ps1).

new_fastapi_config() {
    local fast_project_name="$1"
    cat <<EOF
import json
from typing import List
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = '$fast_project_name'
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
EOF
}

new_fastapi_router() {
    cat <<'PY_EOF'
from fastapi import APIRouter
from app.api.v1.endpoints import health

api_router = APIRouter()

api_router.include_router(health.router, prefix="/health", tags=["Health"])
PY_EOF
}

new_fastapi_response_service() {
    cat <<'PY_EOF'
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
PY_EOF
}

new_fastapi_health() {
    cat <<'PY_EOF'
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def health_check():
    return {"status": "ok"}
PY_EOF
}

new_fastapi_main() {
    cat <<'PY_EOF'
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.sessions import SessionMiddleware

from app.api.v1.router import api_router
from app.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    debug=settings.debug,
    lifespan=lifespan,
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
PY_EOF
}

new_fastapi_test() {
    cat <<'PY_EOF'
import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app


@pytest.mark.anyio
async def test_health_check():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/v1/health/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
PY_EOF
}

new_fastapi_gitignore() {
    cat <<'PY_EOF'
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
PY_EOF
}

new_fastapi_pytest_ini() {
    cat <<'PY_EOF'
[pytest]
pythonpath = .
python_files = test_*.py
PY_EOF
}

new_fastapi_readme() {
    cat <<'PY_EOF'
# Lancer le serveur

```bash
uvicorn app.main:app --reload
```

## Lancer les tests

```bash
pytest
```
PY_EOF
}

new_fastapi_env() {
    cat <<'PY_EOF'
APP_NAME=Clean FastAPI App
DEBUG=True
VERSION=1.0.0

CORS_ORIGINS='["*"]'

PY_EOF
}

new_fastapi() {
    local project_name="${1:-}"
    if [ -z "$project_name" ]; then
        read -rp "Project name: " project_name
    fi

    mkdir -p "$project_name" || return 1
    cd "$project_name" || return 1

    echo "Creating virtual environment"
    python3 -m venv venv

    echo "Activating virtual environment"
    # shellcheck disable=SC1091
    source venv/bin/activate

    echo "Upgrading pip"
    python -m pip install --upgrade pip

    echo "Installing dependencies..."
    pip install fastapi uvicorn pydantic pydantic-settings pytest httpx anyio itsdangerous
    pip freeze > requirements.txt

    mkdir -p app/api/v1/endpoints app/core app/services tests

    new_fastapi_config "$project_name" > app/core/config.py
    new_fastapi_router > app/api/v1/router.py
    new_fastapi_response_service > app/services/response_service.py
    new_fastapi_health > app/api/v1/endpoints/health.py
    new_fastapi_main > app/main.py
    new_fastapi_test > tests/test_health.py
    new_fastapi_gitignore > .gitignore
    new_fastapi_pytest_ini > pytest.ini
    new_fastapi_readme > README.md
    new_fastapi_env > .env
    new_fastapi_env > .env.example

    read -rp "Would you like to initialize Git? (Y/N): " git_init
    case "$git_init" in
        [Yy]*)
            git init
            git add -A
            git commit -m "Initial commit"
            ;;
    esac

    echo "Project '$project_name' has been created successfully!"
    echo "Activate the virtual environment:"
    echo "        source venv/bin/activate"
    echo "Start the FastAPI server:"
    echo "        uvicorn app.main:app --reload"
    echo "Run tests:"
    echo "        pytest <test_file>"
}

new_fastapi_project() {
    new_fastapi "$@"
}

create_fastapi() {
    new_fastapi "$@"
}

create_fastapi_project() {
    new_fastapi "$@"
}
