$fastapi_upload_config = @'

    # ------------------------------
    # Upload Configuration
    # ------------------------------
    UPLOAD_DIR: str = "app/uploads"
    MAX_UPLOAD_SIZE: int = 5242880  # 5 MB
    ALLOWED_UPLOAD_EXTENSIONS: List[str] = [
        "jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "ico",
        "pdf", "docx", "xlsx", "csv", "txt", "md",
    ]
'@


$fastapi_upload_schema_content = @'
from datetime import datetime

from pydantic import BaseModel


class UploadedFile(BaseModel):
    filename: str
    path: str
    url: str
    content_type: str | None = None
    size: int
    extension: str
    uploaded_at: datetime


class UploadResponse(BaseModel):
    success: bool = True
    message: str = "File uploaded successfully"
    file: UploadedFile
'@


$fastapi_upload_service_content = @'
import uuid
from datetime import datetime, timezone
from pathlib import Path

import aiofiles
from fastapi import HTTPException, UploadFile

from app.core.config import settings


class UploadService:
    IMAGE_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "ico"}
    CHUNK_SIZE = 1024 * 1024

    def __init__(self) -> None:
        self.upload_dir = Path(settings.UPLOAD_DIR)
        self.max_size = settings.MAX_UPLOAD_SIZE
        self.allowed_extensions = {ext.lower() for ext in settings.ALLOWED_UPLOAD_EXTENSIONS}

    def _validate_extension(self, filename: str) -> str:
        extension = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
        if extension not in self.allowed_extensions:
            allowed = ", ".join(sorted(self.allowed_extensions))
            raise HTTPException(
                status_code=415,
                detail=f"Extension '.{extension}' is not allowed. Allowed: {allowed}",
            )
        return extension

    def _category(self, extension: str) -> str:
        return "images" if extension in self.IMAGE_EXTENSIONS else "documents"

    def _destination(self, extension: str) -> Path:
        sub_dir = self.upload_dir / self._category(extension)
        sub_dir.mkdir(parents=True, exist_ok=True)
        return sub_dir / f"{uuid.uuid4().hex}.{extension}"

    async def _size_ok(self, file: UploadFile) -> int:
        size = 0
        while chunk := await file.read(self.CHUNK_SIZE):
            size += len(chunk)
            if size > self.max_size:
                await file.seek(0)
                raise HTTPException(
                    status_code=413,
                    detail=f"File is too large. Maximum allowed size is {self.max_size} bytes",
                )
        await file.seek(0)
        return size

    async def save(self, file: UploadFile) -> dict:
        if not file.filename:
            raise HTTPException(status_code=400, detail="Uploaded file has no filename")

        extension = self._validate_extension(file.filename)
        size = await self._size_ok(file)
        destination = self._destination(extension)

        async with aiofiles.open(destination, "wb") as buffer:
            while chunk := await file.read(self.CHUNK_SIZE):
                await buffer.write(chunk)

        return {
            "filename": file.filename,
            "path": destination.as_posix(),
            "url": f"/uploads/{destination.relative_to(self.upload_dir).as_posix()}",
            "content_type": file.content_type,
            "size": size,
            "extension": extension,
            "uploaded_at": datetime.now(timezone.utc),
        }

    async def save_many(self, files: list[UploadFile]) -> list[dict]:
        return [await self.save(file) for file in files]

    async def delete(self, file_path: str) -> bool:
        root = self.upload_dir.resolve()
        target = (root / file_path).resolve()
        if root not in target.parents or not target.is_file():
            return False
        target.unlink()
        return True
'@


$fastapi_upload_endpoint_content = @'
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from app.schemas.upload import UploadResponse
from app.services.upload_service import UploadService

router = APIRouter()


async def get_upload_service() -> UploadService:
    return UploadService()


@router.post("/", response_model=UploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    service: UploadService = Depends(get_upload_service),
):
    result = await service.save(file)
    return UploadResponse(file=result)


@router.post("/many", response_model=list[UploadResponse])
async def upload_files(
    files: list[UploadFile] = File(...),
    service: UploadService = Depends(get_upload_service),
):
    results = await service.save_many(files)
    return [UploadResponse(file=result) for result in results]


@router.delete("/{file_path:path}")
async def delete_file(
    file_path: str,
    service: UploadService = Depends(get_upload_service),
):
    deleted = await service.delete(file_path)
    if not deleted:
        raise HTTPException(status_code=404, detail="File not found")
    return {"message": "File deleted"}
'@


function fastapi_upload_update_config {
    $ConfigPath = "app/core/config.py"

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "config.py not found at $ConfigPath"
        return
    }

    $content = Get-Content $ConfigPath -Raw

    if ($content -match "UPLOAD_DIR:") {
        Write-Host "Upload configuration already exists. Skipping..."
        return
    }

    if ($content -match "CORS_ORIGINS:\s*List\[str\]") {
        $updatedContent = $content -replace "(CORS_ORIGINS:\s*List\[str\])", "`$1`n$fastapi_upload_config"
        Set-Content -Path $ConfigPath -Value $updatedContent -Encoding UTF8
        Write-Host "Upload configuration added to config.py"
    }
    else {
        Write-Host "CORS_ORIGINS block not found in config.py. Skipping config update."
    }
}


function fastapi_upload_update_main {
    $MainPath = "app/main.py"

    if (-not (Test-Path $MainPath)) {
        Write-Host "main.py not found at $MainPath"
        return
    }

    $content = Get-Content $MainPath -Raw

    if ($content -match "StaticFiles") {
        Write-Host "Static file serving already configured. Skipping main.py update."
        return
    }

    $content = $content -replace "(from app\.core\.config import settings)", "`$1`nfrom fastapi.staticfiles import StaticFiles`nfrom pathlib import Path"

    if ($content -notmatch "UPLOAD_DIR.*mkdir") {
        $content = [regex]::Replace($content, "(?m)^([ \t]*)yield\r?$", "`$1Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)`n`$1yield")
    }

    if ($content -notmatch "app\.mount\(") {
        $lines = $content -split "`r?`n"
        $lastIndex = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "app\.include_router\(api_router") {
                $lastIndex = $i
            }
        }
        if ($lastIndex -ge 0) {
            $mountLine = 'app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")'
            $lines = $lines[0..$lastIndex] + $mountLine + $lines[($lastIndex + 1)..($lines.Count - 1)]
            $content = $lines -join "`n"
        }
    }

    Set-Content -Path $MainPath -Value $content -Encoding UTF8
    Write-Host "main.py updated with static file serving for uploads."
}


function fastapi_upload_update_gitignore {
    $GitIgnorePath = ".gitignore"

    if (-not (Test-Path $GitIgnorePath)) {
        return
    }

    $content = Get-Content $GitIgnorePath -Raw

    if ($content -match "# Uploads") {
        Write-Host "Upload entries already present in .gitignore. Skipping..."
        return
    }

    $uploadGitIgnore = @'

# Uploads
app/uploads/*
!app/uploads/.gitkeep
!app/uploads/images/
!app/uploads/images/.gitkeep
!app/uploads/documents/
!app/uploads/documents/.gitkeep
'@

    Add-Content -Path $GitIgnorePath -Value $uploadGitIgnore -Encoding UTF8
    Write-Host "Upload entries added to .gitignore."
}


function Fastapi-Upload {
    if (-not (Test-Path "venv")) {
        Write-Host "Creating virtual environment"
        python -m venv venv

        Write-Host "Activating virtual environment"
        & .\venv\Scripts\Activate.ps1
    }

    Write-Host "Upgrading pip"
    python -m pip install --upgrade pip

    Write-Host "Installing dependencies..."
    pip install python-multipart aiofiles
    pip freeze > requirements.txt

    $dirs = @(
        "app/api/v1/endpoints",
        "app/schemas",
        "app/services",
        "app/uploads/images",
        "app/uploads/documents"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    New-Item -ItemType File -Path "app/uploads/.gitkeep" -Force | Out-Null
    New-Item -ItemType File -Path "app/uploads/images/.gitkeep" -Force | Out-Null
    New-Item -ItemType File -Path "app/uploads/documents/.gitkeep" -Force | Out-Null

    fastapi_upload_update_config
    fastapi_upload_update_main
    fastapi_upload_update_gitignore

    Set-Content "app/schemas/upload.py" -Value $fastapi_upload_schema_content -Encoding UTF8
    Set-Content "app/services/upload_service.py" -Value $fastapi_upload_service_content -Encoding UTF8
    Set-Content "app/api/v1/endpoints/upload.py" -Value $fastapi_upload_endpoint_content -Encoding UTF8

    $upload_env_var = @{
        "UPLOAD_DIR"               = "app/uploads"
        "MAX_UPLOAD_SIZE"          = "5242880"
        "ALLOWED_UPLOAD_EXTENSIONS" = '["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "ico", "pdf", "docx", "xlsx", "csv", "txt", "md"]'
    }
    fastapi_update_env_files -Variables $upload_env_var

    $newLine = 'api_router.include_router(upload.router, prefix="/upload", tags=["Upload"])'
    fastapi_update_api_router -routerFile "app/api/v1/router.py" -newLine $newLine -ModuleName "upload"

    Write-Host ""
    Write-Host "Upload setup completed successfully!"
    Write-Host "Files are stored in app/uploads/ and served under /uploads"
    Write-Host "Endpoints: POST /api/v1/upload/ | POST /api/v1/upload/many | DELETE /api/v1/upload/{path}"
}

function Setup-Fastapi-Upload {
    Fastapi-Upload
}
