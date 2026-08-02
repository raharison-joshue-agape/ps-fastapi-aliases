#!/usr/bin/env bash
# FastAPI database setup for macOS (bash).
# Mirrors the Windows PowerShell module (setup-fastapi-database.ps1).
# Compatible with the system bash 3.2 and BSD tools shipped with macOS.
# Generates a fully asynchronous SQLAlchemy stack (create_async_engine,
# AsyncSession, async repositories/services/endpoints) or async MongoDB (motor).

# ------------------------------
# Template writers
# ------------------------------

fastapi_db_config_block() {
    cat <<'PY_EOF'

    # ------------------------------
    # Database Configuration
    # ------------------------------
    DB_HOST: str
    DB_PORT: int
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str
PY_EOF
}

fastapi_db_base() {
    cat <<'PY_EOF'
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
PY_EOF
}

fastapi_db_base_mongo() {
    cat <<'PY_EOF'
from pydantic import BaseModel, Field, GetCoreSchemaHandler
from bson import ObjectId
from typing import Any

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v: Any, info=None):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)

    @classmethod
    def __get_pydantic_json_schema__(cls, core_schema, handler: GetCoreSchemaHandler):
        return {"type": "string"}

class BaseModelMongo(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {ObjectId: str},
    }
PY_EOF
}

fastapi_db_session() {
    cat <<'PY_EOF'
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.debug,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)
PY_EOF
}

fastapi_db_session_mongo() {
    cat <<'PY_EOF'
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from app.core.config import settings

client: AsyncIOMotorClient | None = None
db: AsyncIOMotorDatabase | None = None

def init_db():
    global client, db
    client = AsyncIOMotorClient(settings.DATABASE_URL)
    db = client[settings.DB_NAME]

async def get_db() -> AsyncIOMotorDatabase:
    if db is None:
        init_db()
    return db
PY_EOF
}

fastapi_db_deps() {
    cat <<'PY_EOF'
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import AsyncSessionLocal


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
PY_EOF
}

fastapi_db_deps_mongo() {
    cat <<'PY_EOF'
from fastapi import Depends
from app.database.session import get_db
from motor.motor_asyncio import AsyncIOMotorDatabase

async def get_database(db: AsyncIOMotorDatabase = Depends(get_db)) -> AsyncIOMotorDatabase:
    return db
PY_EOF
}

fastapi_db_init_models() {
    printf '%s\n' 'from app.models.user import User'
}

fastapi_db_user_model() {
    cat <<'PY_EOF'
from sqlalchemy import Column, Integer, String
from app.database.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
PY_EOF
}

fastapi_db_user_model_mongo() {
    cat <<'PY_EOF'
from pydantic import BaseModel, EmailStr, Field
from app.database.base import PyObjectId

class User(BaseModel):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    name: str
    email: EmailStr

    model_config = {
        "populate_by_name": True,
        "arbitrary_types_allowed": True,
        "json_encoders": {PyObjectId: str},
    }
PY_EOF
}

fastapi_db_user_repository() {
    cat <<'PY_EOF'
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, name: str, email: str) -> User:
        user = User(name=name, email=email)
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def get_by_id(self, user_id: int) -> User | None:
        result = await self.db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_all(self) -> list[User]:
        result = await self.db.execute(select(User))
        return list(result.scalars().all())

    async def delete(self, user_id: int) -> bool:
        result = await self.db.execute(delete(User).where(User.id == user_id))
        await self.db.commit()
        return result.rowcount > 0
PY_EOF
}

fastapi_db_user_repository_mongo() {
    cat <<'PY_EOF'
from app.models.user import User
from typing import List, Optional

class UserRepository:
    def __init__(self, db):
        self.db = db

    async def create(self, name: str, email: str) -> User:
        user_dict = {"name": name, "email": email}
        result = await self.db.users.insert_one(user_dict)
        user_dict["_id"] = result.inserted_id
        return User(**user_dict)

    async def get_by_id(self, user_id: str) -> Optional[User]:
        from bson import ObjectId
        user_doc = await self.db.users.find_one({"_id": ObjectId(user_id)})
        return User(**user_doc) if user_doc else None

    async def get_all(self) -> List[User]:
        users_cursor = self.db.users.find()
        return [User(**user) async for user in users_cursor]

    async def delete(self, user_id: str) -> bool:
        from bson import ObjectId
        result = await self.db.users.delete_one({"_id": ObjectId(user_id)})
        return result.deleted_count > 0
PY_EOF
}

fastapi_db_user_schema() {
    cat <<'PY_EOF'
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    name: str
    email: EmailStr

class UserRead(BaseModel):
    id: int
    name: str
    email: EmailStr

    class Config:
        # orm_mode = True
        from_attributes = True
PY_EOF
}

fastapi_db_user_service() {
    cat <<'PY_EOF'
from typing import Optional

from app.models.user import User
from app.repositories.user_repository import UserRepository


class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo

    async def create_user(self, name: str, email: str) -> User:
        return await self.repo.create(name, email)

    async def get_user(self, user_id: int) -> Optional[User]:
        return await self.repo.get_by_id(user_id)

    async def list_users(self) -> list[User]:
        return await self.repo.get_all()

    async def delete_user(self, user_id: int) -> bool:
        return await self.repo.delete(user_id)
PY_EOF
}

fastapi_db_user_service_mongo() {
    cat <<'PY_EOF'
from app.repositories.user_repository import UserRepository
from typing import List, Optional
from app.models.user import User

class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo

    async def create_user(self, name: str, email: str) -> User:
        return await self.repo.create(name, email)

    async def get_user(self, user_id: str) -> Optional[User]:
        return await self.repo.get_by_id(user_id)

    async def list_users(self) -> List[User]:
        return await self.repo.get_all()

    async def delete_user(self, user_id: str) -> bool:
        return await self.repo.delete(user_id)
PY_EOF
}

fastapi_db_user_endpoint() {
    cat <<'PY_EOF'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.deps import get_db
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate, UserRead
from app.services.user_service import UserService

router = APIRouter()


async def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    return UserService(UserRepository(db))


@router.post("/", response_model=UserRead)
async def create_user(user: UserCreate, service: UserService = Depends(get_user_service)):
    return await service.create_user(user.name, user.email)


@router.get("/{user_id}", response_model=UserRead)
async def get_user(user_id: int, service: UserService = Depends(get_user_service)):
    user = await service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/", response_model=list[UserRead])
async def list_users(service: UserService = Depends(get_user_service)):
    return await service.list_users()


@router.delete("/{user_id}")
async def delete_user(user_id: int, service: UserService = Depends(get_user_service)):
    success = await service.delete_user(user_id)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted"}
PY_EOF
}

fastapi_db_user_endpoint_mongo() {
    cat <<'PY_EOF'
from fastapi import APIRouter, Depends, HTTPException
from app.services.user_service import UserService
from app.repositories.user_repository import UserRepository
from app.models.user import User
from app.database.session import get_db
from typing import List

router = APIRouter()

async def get_user_service(db=Depends(get_db)) -> UserService:
    repo = UserRepository(db)
    return UserService(repo)

@router.post("/", response_model=User)
async def create_user(name: str, email: str, service: UserService = Depends(get_user_service)):
    return await service.create_user(name, email)

@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str, service: UserService = Depends(get_user_service)):
    user = await service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/", response_model=List[User])
async def list_users(service: UserService = Depends(get_user_service)):
    return await service.list_users()

@router.delete("/{user_id}")
async def delete_user(user_id: str, service: UserService = Depends(get_user_service)):
    success = await service.delete_user(user_id)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted"}
PY_EOF
}

fastapi_db_alembic_env() {
    cat <<'PY_EOF'
import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.ext.asyncio import async_engine_from_config

from app.core.config import settings
from app.database.base import Base
from app.models import *  # noqa: F401,F403

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
PY_EOF
}

fastapi_db_readme_updated() {
    cat <<'PY_EOF'
# Lancer le serveur

```bash
uvicorn app.main:app --reload
```

## Lancer les tests

```bash
pytest
```

### Create the initial migration

```bash
alembic revision --autogenerate -m "init"
```

#### Apply the migration

```bash
alembic upgrade head
```

PY_EOF
}

# ------------------------------
# Shared helpers
# ------------------------------

# Insert a block after the "CORS_ORIGINS: List[str]" line in config.py
fastapi_config_insert_after_cors() {
    local block="$1"
    local config_path="${2:-app/core/config.py}"

    [ -f "$config_path" ] || return 1

    awk -v blk="$block" '
        $0 ~ /^    CORS_ORIGINS: List\[str\]$/ {
            print
            print blk
            next
        }
        { print }
    ' "$config_path" > "$config_path.tmp" && mv "$config_path.tmp" "$config_path"
}

# Add/replace the module import in app/api/v1/router.py and insert a new include_router line.
# Usage: fastapi_update_api_router <router_file> <new_line> [module_name]
fastapi_update_api_router() {
    local router_file="$1"
    local new_line="$2"
    local module_name="${3:-user}"

    if [ ! -f "$router_file" ]; then
        echo "File not found: $router_file"
        return 1
    fi

    local content
    content=$(cat "$router_file")

    local import_pattern='from app\.api\.v1\.endpoints import (.+)'
    if grep -qE "$import_pattern" <<<"$content"; then
        local current
        current=$(printf '%s\n' "$content" | grep -E "$import_pattern" | head -n1 | sed -E 's/.*import (.*)/\1/')
        if ! printf '%s\n' "$current" | grep -qE "(^|[^A-Za-z0-9_])${module_name}([^A-Za-z0-9_]|$)"; then
            local new_imports
            new_imports="from app.api.v1.endpoints import $current, $module_name"
            content=${content//from app.api.v1.endpoints import $current/$new_imports}
            echo "'$module_name' import added to $router_file"
        fi
    else
        content="from app.api.v1.endpoints import $module_name"$'\n'"$content"
        echo "'$module_name' import added at the top of $router_file"
    fi

    if ! grep -qF "$new_line" <<<"$content"; then
        content=$(awk -v nl="$new_line" '
            /api_router\.include_router\(/ { last = NR }
            { lines[NR] = $0 }
            END {
                for (i = 1; i <= NR; i++) {
                    print lines[i]
                    if (i == last) print nl
                }
            }
        ' <<<"$content")
        echo "include_router line added to $router_file"
    fi

    printf '%s\n' "$content" > "$router_file"
}

# Add KEY=VALUE pairs to .env and .env.example.
# Usage: fastapi_update_env_files "KEY=VALUE" "KEY2=VALUE2" ...
fastapi_update_env_files() {
    local env_files=(".env" ".env.example")

    for env_file in "${env_files[@]}"; do
        [ -f "$env_file" ] || touch "$env_file"

        for entry in "$@"; do
            local key="${entry%%=*}"
            local value="${entry#*=}"
            if ! grep -qE "^${key}=" "$env_file"; then
                printf '%s=%s\n' "$key" "$value" >> "$env_file"
                echo "Added $key to $env_file"
            else
                echo "$key already exists in $env_file, skipping"
            fi
        done
    done
}

# ------------------------------
# Config / core updates
# ------------------------------

fastapi_database_update_config() {
    echo "Setting up database config in config.py..."
    local config_path="app/core/config.py"

    if [ ! -f "$config_path" ]; then
        echo "config.py not found at $config_path"
        return
    fi

    if ! grep -q "DB_HOST:" "$config_path"; then
        fastapi_config_insert_after_cors "$(fastapi_db_config_block)" "$config_path"
        echo "Database configuration added successfully!"
    else
        echo "Database configuration already exists. Skipping..."
    fi
}

fastapi_update_core_config() {
    local db_driver="$1"
    echo "Adding DATABASE_URL to config.py..."
    local config_path="app/core/config.py"

    if [ ! -f "$config_path" ]; then
        echo "config.py not found at $config_path"
        return
    fi

    fastapi_database_update_config

    local connection
    case "$(printf '%s' "$db_driver" | tr '[:upper:]' '[:lower:]')" in
        mongodb)     connection="mongodb://" ;;
        postgresql)  connection="postgresql+asyncpg://" ;;
        *)           connection="mysql+aiomysql://" ;;
    esac

    if grep -q "DATABASE_URL" "$config_path"; then
        echo "DATABASE_URL already exists. Skipping..."
        return
    fi

    local block
    block=$(cat <<EOF
    # ------------------------------
    # Database Connection URL
    # ------------------------------
    from pydantic import computed_field

    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        return (
            f"$connection"
            f"{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

EOF
)

    awk -v blk="$block" '
        /^settings = Settings\(\)$/ { print blk }
        { print }
    ' "$config_path" > "$config_path.tmp" && mv "$config_path.tmp" "$config_path"

    echo "DATABASE_URL added successfully!"
}

# ------------------------------
# Database drivers
# ------------------------------

fastapi_pymysql() {
    echo "Installing dependencies..."
    pip install alembic "sqlalchemy[asyncio]" aiomysql "pydantic[email]"
    pip freeze > requirements.txt

    fastapi_update_core_config "mysql"

    fastapi_update_env_files \
        "DB_HOST=localhost" \
        "DB_PORT=3306" \
        "DB_USER=root" \
        "DB_PASSWORD=password" \
        "DB_NAME=mydb"

    fastapi_db_user_model > app/models/user.py
}

fastapi_psycopg2() {
    echo "Installing dependencies"
    pip install alembic "sqlalchemy[asyncio]" asyncpg "pydantic[email]"
    pip freeze > requirements.txt

    fastapi_update_core_config "postgresql"

    fastapi_update_env_files \
        "DB_HOST=localhost" \
        "DB_PORT=5432" \
        "DB_USER=postgres" \
        "DB_PASSWORD=password" \
        "DB_NAME=mydb"

    fastapi_db_user_model > app/models/user.py
}

fastapi_pymongo() {
    echo "Installing dependencies"
    pip install motor pymongo "pydantic[email]"
    pip freeze > requirements.txt

    fastapi_update_core_config "mongodb"

    fastapi_update_env_files \
        "DB_HOST=localhost" \
        "DB_PORT=27017" \
        "DB_USER=mongo_user" \
        "DB_PASSWORD=password" \
        "DB_NAME=mydb"

    fastapi_db_user_model_mongo > app/models/user.py
}

# ------------------------------
# Main entry point
# ------------------------------

fastapi_database() {
    if [ ! -d "venv" ]; then
        echo "Creating virtual environment"
        python3 -m venv venv

        echo "Activating virtual environment"
        # shellcheck disable=SC1091
        source venv/bin/activate
    fi

    echo "Which database do you want to use?"
    echo "1) MySQL/MariaDB"
    echo "2) PostgreSQL"
    echo "3) MongoDB"
    read -rp "Enter choice (1-3): " db_choice

    echo "Upgrading pip"
    python -m pip install --upgrade pip

    mkdir -p app/api/v1/endpoints app/database app/repositories app/models app/schemas app/services

    case "$db_choice" in
        2)
            echo "Setting up PostgreSQL..."
            fastapi_psycopg2
            ;;
        3)
            echo "MongoDB setup not implemented yet."
            fastapi_pymongo
            ;;
        *)
            echo "Setting up MySQL/MariaDB..."
            fastapi_pymysql
            ;;
    esac

    fastapi_db_init_models > app/models/__init__.py
    fastapi_update_api_router "app/api/v1/router.py" 'api_router.include_router(user.router, prefix="/user", tags=["Users"])' "user"
    fastapi_db_readme_updated > README.md

    if [ "$db_choice" = "3" ]; then
        rm -rf app/schemas
        fastapi_db_user_endpoint_mongo > app/api/v1/endpoints/user.py
        fastapi_db_base_mongo > app/database/base.py
        fastapi_db_session_mongo > app/database/session.py
        fastapi_db_deps_mongo > app/database/deps.py
        fastapi_db_user_repository_mongo > app/repositories/user_repository.py
        fastapi_db_user_service_mongo > app/services/user_service.py
    else
        fastapi_db_user_endpoint > app/api/v1/endpoints/user.py
        fastapi_db_base > app/database/base.py
        fastapi_db_session > app/database/session.py
        fastapi_db_deps > app/database/deps.py
        fastapi_db_user_repository > app/repositories/user_repository.py
        fastapi_db_user_schema > app/schemas/user.py
        fastapi_db_user_service > app/services/user_service.py

        echo "Init Alembic..."
        alembic init alembic

        fastapi_db_alembic_env > alembic/env.py
        printf '*\n' > alembic/versions/.gitignore

        echo ""
        echo "Database setup completed successfully!"
        echo ""
        echo "Create the initial migration:"
        echo "        alembic revision --autogenerate -m \"init\""
        echo "Apply the migration:"
        echo "        alembic upgrade head"
    fi
}

setup_fastapi_database() {
    fastapi_database "$@"
}
