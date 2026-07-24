$fastapi_database_config = @'

    # ------------------------------
    # Database Configuration
    # ------------------------------
    DB_HOST: str
    DB_PORT: int
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str
'@


$fastapi_base_content = @'
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
'@


$fastapi_base_mongos_content = @'
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
'@


$fastapi_session_content = @'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.debug
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False
)
'@


$fastapi_session_mongos_content = @'
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
'@


$fastapi_deps_content = @'
from app.database.session import SessionLocal

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'@


$fastapi_deps_mongos_content = @'
from fastapi import Depends
from app.database.session import get_db
from motor.motor_asyncio import AsyncIOMotorDatabase

async def get_database(db: AsyncIOMotorDatabase = Depends(get_db)) -> AsyncIOMotorDatabase:
    return db
'@


$fastapi_init_db_content =  'from app.models.user import User'


$fastapi_user_model_content = @'
from sqlalchemy import Column, Integer, String
from app.database.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
'@


$fastapi_user_model_mongos_content = @'
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
'@


$fastapi_user_repository_content = @'
from sqlalchemy.orm import Session
from app.models.user import User

class UserRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, name: str, email: str) -> User:
        user = User(name=name, email=email)
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_by_id(self, user_id: int) -> User | None:
        return self.db.query(User).filter(User.id == user_id).first()

    def get_all(self) -> list[User]:
        return self.db.query(User).all()

    def delete(self, user_id: int) -> bool:
        user = self.get_by_id(user_id)
        if user:
            self.db.delete(user)
            self.db.commit()
            return True
        return False
'@

$fastapi_user_repository_mongos_content = @'
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
'@


$fastapi_user_schema_content = @'
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
'@


$fastapi_user_service_content = @'
from app.repositories.user_repository import UserRepository

class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo

    def create_user(self, name: str, email: str):
        return self.repo.create(name, email)

    def get_user(self, user_id: int):
        return self.repo.get_by_id(user_id)

    def list_users(self):
        return self.repo.get_all()

    def delete_user(self, user_id: int):
        return self.repo.delete(user_id)
'@


$fastapi_user_service_mongos_content = @'
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
'@


$fastapi_user_endpoint_content = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database.deps import get_db
from app.services.user_service import UserService
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate, UserRead

router = APIRouter()

@router.post("/", response_model=UserRead)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
    repo = UserRepository(db)
    service = UserService(repo)
    return service.create_user(user.name, user.email)

@router.get("/{user_id}", response_model=UserRead)
def get_user(user_id: int, db: Session = Depends(get_db)):
    repo = UserRepository(db)
    service = UserService(repo)
    user = service.get_user(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/", response_model=list[UserRead])
def list_users(db: Session = Depends(get_db)):
    repo = UserRepository(db)
    service = UserService(repo)
    return service.list_users()

@router.delete("/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db)):
    repo = UserRepository(db)
    service = UserService(repo)
    success = service.delete_user(user_id)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    return {"message": "User deleted"}
'@


$fastapi_user_endpoint_mongos_content = @'
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
'@


$fastapi_alembic_env_content = @'
from app.models import *
from app.core.config import settings
from app.database.base import Base
from logging.config import fileConfig
from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

config = context.config

config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

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


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
'@


$fastapi_readme_updated = @'
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

'@


function fastapi_database_update_config {
    Write-Host "Setting up database config in config.py..."

    $ConfigPath = "app/core/config.py"

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "config.py not found at $ConfigPath"
        return
    }

    $content = Get-Content $ConfigPath -Raw

    if ($content -notmatch "DB_HOST:") {
        $updatedContent = $content -replace "(CORS_ORIGINS:\s*List\[str\])", "`$1`n$fastapi_database_config"

        Set-Content -Path $ConfigPath -Value $updatedContent -Encoding UTF8
        Write-Host "Database configuration added successfully!"
    } else {
        Write-Host "Database configuration already exists. Skipping..."
    }
}


function fastapi_update_Core_config {
    param(
        [Parameter(Mandatory = $true)]
        [string]$db_driver
    )

    Write-Host "Adding DATABASE_URL to config.py..."

    $ConfigPath = "app/core/config.py"

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "config.py not found at $ConfigPath"
        return
    }

    fastapi_database_update_config

    $driver = $db_driver.ToLower()

    switch ($driver) {
        "mongodb"   { $connection = "mongodb://" }
        "postgresql" { $connection = "postgresql+psycopg2://" }
        default      { $connection = "mysql+pymysql://" }
    }

    $db_url_block = @"
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

"@

    $content = Get-Content $ConfigPath -Raw

    if ($content -match "DATABASE_URL") {
        Write-Host "DATABASE_URL already exists. Skipping..."
        return
    }

    $updatedContent = $content -replace "(settings\s*=\s*Settings\(\))", "$db_url_block`n`$1"

    Set-Content -Path $ConfigPath -Value $updatedContent -Encoding UTF8

    Write-Host "DATABASE_URL added successfully!"
}


function fastapi_update_api_router {
    param(
        [Parameter(Mandatory = $true)]
        [string]$routerFile,
        [Parameter(Mandatory = $true)]
        [string]$newLine
    )

    if (-not (Test-Path $routerFile)) {
        Write-Host "File not found: $routerFile"
        return
    }

    $content = Get-Content $routerFile -Raw

    $importPattern = "from app\.api\.v1\.endpoints import (.+)"
    if ($content -match $importPattern) {
        $currentImports = $Matches[1].Trim()
        if ($currentImports -notmatch "\buser\b") {
            $newImports = "from app.api.v1.endpoints import $currentImports, user"
            $content = [regex]::Replace($content, $importPattern, $newImports)
            Write-Host "'user' import added to $routerFile"
        }
    } else {
        $content = "from app.api.v1.endpoints import user`n" + $content
        Write-Host "'user' import added at the top of $routerFile"
    }

    if ($content -match [regex]::Escape($newLine)) {
        Write-Host "The route already exists in $routerFile. Nothing was added."
    } else {
        $lines = $content -split "`r?`n"
        $lastIndex = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "api_router\.include_router\(.*\)") {
                $lastIndex = $i
            }
        }
        if ($lastIndex -ge 0) {
            $lines = $lines[0..$lastIndex] + $newLine + $lines[($lastIndex + 1)..($lines.Count - 1)]
        } else {
            $lines += $newLine
        }
        $content = $lines -join "`n"
        Write-Host "include_router line added to $routerFile"
    }

    Set-Content -Path $routerFile -Value $content -Encoding UTF8
}


function fastapi_update_env_files {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Variables,
        [string[]]$EnvFiles = @(".env", ".env.example")
    )

    foreach ($envfile in $EnvFiles) {
        if (-not (Test-Path $envfile)) {
            New-Item -ItemType File -Path $envfile | Out-Null
            Write-Host "File created: $envfile"
        }

        $content = Get-Content $envfile -Raw

        foreach ($key in $Variables.Keys) {
            $pattern = "(?m)^$key="
            if ($content -notmatch $pattern) {
                Add-Content -Path $envfile -Value "$key=$($Variables[$key])"
                Write-Host "Added $key to $envfile"
            } else {
                Write-Host "$key already exists in $envfile, skipping"
            }
        }
    }
}


function fastapi_pymysql {
    Write-Host "Installing dependencies..."
    pip install alembic sqlalchemy pymysql "pydantic[email]"
    pip freeze > requirements.txt

    fastapi_update_Core_config -db_driver "mysql"

    $database_mysql_var = @{
        "DB_HOST" = "localhost"
        "DB_PORT" = "3306"
        "DB_USER" = "root"
        "DB_PASSWORD" = "password"
        "DB_NAME" = "mydb"
    }
    fastapi_update_env_files -Variables $database_mysql_var
    Set-Content "app/models/user.py" -Value $fastapi_user_model_content -Encoding UTF8
}


function fastapi_psycopg2Binary {
    Write-Host "Installing dependencies"
    pip install alembic sqlalchemy psycopg2-binary "pydantic[email]"
    pip freeze > requirements.txt

    fastapi_update_Core_config -db_driver "postgresql"

    $database_postgresql_var = @{
        "DB_HOST" = "localhost"
        "DB_PORT" = "5432"
        "DB_USER" = "postgres"
        "DB_PASSWORD" = "password"
        "DB_NAME" = "mydb"
    }
    fastapi_update_env_files -Variables $database_postgresql_var
    Set-Content "app/models/user.py" -Value $fastapi_user_model_content -Encoding UTF8
}


function fastapi_pymongo {
    Write-Host "Installing dependencies"
    pip install motor pymongo "pydantic[email]"
    pip freeze > requirements.txt

    fastapi_update_Core_config -db_driver "mongodb"

    $database_mongos_var = @{
        "DB_HOST" = "localhost"
        "DB_PORT" = "27017"
        "DB_USER" = "mongo_user"
        "DB_PASSWORD" = "password"
        "DB_NAME" = "mydb"
    }
    fastapi_update_env_files -Variables $database_mongos_var
    Set-Content "app/models/user.py" -Value $fastapi_user_model_mongos_content -Encoding UTF8
}


function Fastapi-Database {
    if (-not (Test-Path "venv")) {
        Write-Host "Creating virtual environment"
        python -m venv venv

        Write-Host "Activating virtual environment"
        & .\venv\Scripts\Activate.ps1
    }

    Write-Host "Which database do you want to use?"
    Write-Host "1) MySQL/MariaDB"
    Write-Host "2) PostgreSQL"
    Write-Host "3) MongoDB"

    $DB_CHOICE = Read-Host "Enter choice (1-3)"

    Write-Host "Upgrading pip"
    python -m pip install --upgrade pip

    $dirs = @(
        "app/api/v1/endpoints",
        "app/database",
        "app/repositories",
        "app/models",
        "app/schemas",
        "app/services"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    switch ($DB_CHOICE) {
        "1" {
            Write-Host "Setting up MySQL/MariaDB..."
            fastapi_pymysql
        }
        "2" {
            Write-Host "Setting up PostgreSQL..."
            fastapi_psycopg2Binary
        }
        "3" {
            Write-Host "MongoDB setup not implemented yet."
            fastapi_pymongo
        }
        default {
            Write-Host "Invalid choice. Using MySQL by default."
            fastapi_pymysql
        }
    }

    Set-Content "app/models/__init__.py" -Value $fastapi_init_db_content -Encoding UTF8
    $newLine = 'api_router.include_router(user.router, prefix="/user", tags=["Users"])'
    fastapi_update_api_router -routerFile "app/api/v1/router.py" -newLine $newLine
    Set-Content "README.md" -Value $fastapi_readme_updated -Encoding UTF8

    if ($DB_CHOICE -eq "3") {
        Remove-Item -Path "app/schemas"
        Set-Content "app/api/v1/endpoints/user.py" -Value $fastapi_user_endpoint_mongos_content -Encoding UTF8
        Set-Content "app/database/base.py" -Value $fastapi_base_mongos_content -Encoding UTF8
        Set-Content "app/database/session.py" -Value $fastapi_session_mongos_content -Encoding UTF8
        Set-Content "app/database/deps.py" -Value $fastapi_deps_mongos_content -Encoding UTF8
        Set-Content "app/repositories/user_repository.py" -Value $fastapi_user_repository_mongos_content -Encoding UTF8
        Set-Content "app/services/user_service.py" -Value $fastapi_user_service_mongos_content -Encoding UTF8
    } else {
        Set-Content "app/api/v1/endpoints/user.py" -Value $fastapi_user_endpoint_content -Encoding UTF8
        Set-Content "app/database/base.py" -Value $fastapi_base_content -Encoding UTF8
        Set-Content "app/database/session.py" -Value $fastapi_session_content -Encoding UTF8
        Set-Content "app/database/deps.py" -Value $fastapi_deps_content -Encoding UTF8
        Set-Content "app/repositories/user_repository.py" -Value $fastapi_user_repository_content -Encoding UTF8
        Set-Content "app/schemas/user.py" -Value $fastapi_user_schema_content -Encoding UTF8
        Set-Content "app/services/user_service.py" -Value $fastapi_user_service_content -Encoding UTF8

        Write-Host "Init Alembic..."
        alembic init alembic

        Set-Content "alembic/env.py" -Value $fastapi_alembic_env_content -Encoding UTF8
        Set-Content "alembic/versions/.gitignore" -Value "*" -Encoding UTF8

        Write-Host ""
        Write-Host "Database setup completed successfully!"
        Write-Host ""
        Write-Host "🔹 Create the initial migration:"
        Write-Host '        alembic revision --autogenerate -m "init"'
        Write-Host "🔹 Apply the migration:"
        Write-Host "        alembic upgrade head"
    }
}

function Setup-Fastapi-Database {
    Fastapi-Database
}