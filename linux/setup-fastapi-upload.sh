#!/usr/bin/env bash
# FastAPI file upload setup for Linux (bash).
# Mirrors the Windows PowerShell module (setup-fastapi-upload.ps1).
# Generates an async UploadService (python-multipart + aiofiles), schemas,
# endpoints, static file serving and storage tree.

if ! type fastapi_update_api_router >/dev/null 2>&1; then
    # shellcheck source=setup-fastapi-database.sh
    . "$(dirname "${BASH_SOURCE[0]}")/setup-fastapi-database.sh"
fi

fastapi_upload_config_block() {
    cat <<'PY_EOF'

    # ------------------------------
    # Upload Configuration
    # ------------------------------
    UPLOAD_DIR: str = "app/uploads"
    MAX_UPLOAD_SIZE: int = 5242880  # 5 MB
    ALLOWED_UPLOAD_EXTENSIONS: List[str] = [
        "jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "ico",
        "pdf", "docx", "xlsx", "csv", "txt", "md",
    ]
PY_EOF
}

fastapi_upload_schema() {
    cat <<'PY_EOF'
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
PY_EOF
}

fastapi_upload_service() {
    cat <<'PY_EOF'
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
PY_EOF
}

fastapi_upload_endpoint() {
    cat <<'PY_EOF'
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
PY_EOF
}

fastapi_upload_update_config() {
    local config_path="app/core/config.py"

    if [ ! -f "$config_path" ]; then
        echo "config.py not found at $config_path"
        return
    fi

    if grep -q "UPLOAD_DIR:" "$config_path"; then
        echo "Upload configuration already exists. Skipping..."
        return
    fi

    if grep -qE '^    CORS_ORIGINS: List\[str\]$' "$config_path"; then
        fastapi_config_insert_after_cors "$(fastapi_upload_config_block)" "$config_path"
        echo "Upload configuration added to config.py"
    else
        echo "CORS_ORIGINS block not found in config.py. Skipping config update."
    fi
}

fastapi_upload_update_main() {
    local main_path="app/main.py"

    if [ ! -f "$main_path" ]; then
        echo "main.py not found at $main_path"
        return
    fi

    if grep -q "StaticFiles" "$main_path"; then
        echo "Static file serving already configured. Skipping main.py update."
        return
    fi

    local content
    content=$(cat "$main_path")

    content=${content//from app.core.config import settings/from app.core.config import settings$'\n'from fastapi.staticfiles import StaticFiles$'\n'from pathlib import Path}

    if ! grep -q "UPLOAD_DIR.*mkdir" <<<"$content"; then
        content=$(sed -E 's/^([ \t]*)yield\r?$/\1Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)\n\1yield/' <<<"$content")
    fi

    if ! grep -q "app.mount(" <<<"$content"; then
        content=$(awk -v ml='app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")' '
            /app\.include_router\(api_router/ { last = NR }
            { lines[NR] = $0 }
            END {
                for (i = 1; i <= NR; i++) {
                    print lines[i]
                    if (i == last) print ml
                }
            }
        ' <<<"$content")
    fi

    printf '%s\n' "$content" > "$main_path"
    echo "main.py updated with static file serving for uploads."
}

fastapi_upload_update_gitignore() {
    local gitignore_path=".gitignore"

    [ -f "$gitignore_path" ] || return

    if grep -q "# Uploads" "$gitignore_path"; then
        echo "Upload entries already present in .gitignore. Skipping..."
        return
    fi

    cat >> "$gitignore_path" <<'PY_EOF'

# Uploads
app/uploads/*
!app/uploads/.gitkeep
!app/uploads/images/
!app/uploads/images/.gitkeep
!app/uploads/documents/
!app/uploads/documents/.gitkeep
PY_EOF
    echo "Upload entries added to .gitignore."
}

fastapi_upload() {
    if [ ! -d "venv" ]; then
        echo "Creating virtual environment"
        python3 -m venv venv

        echo "Activating virtual environment"
        # shellcheck disable=SC1091
        source venv/bin/activate
    fi

    echo "Upgrading pip"
    python -m pip install --upgrade pip

    echo "Installing dependencies..."
    pip install python-multipart aiofiles
    pip freeze > requirements.txt

    mkdir -p app/api/v1/endpoints app/schemas app/services app/uploads/images app/uploads/documents

    touch app/uploads/.gitkeep app/uploads/images/.gitkeep app/uploads/documents/.gitkeep

    fastapi_upload_update_config
    fastapi_upload_update_main
    fastapi_upload_update_gitignore

    fastapi_upload_schema > app/schemas/upload.py
    fastapi_upload_service > app/services/upload_service.py
    fastapi_upload_endpoint > app/api/v1/endpoints/upload.py

    fastapi_update_env_files \
        "UPLOAD_DIR=app/uploads" \
        "MAX_UPLOAD_SIZE=5242880" \
        'ALLOWED_UPLOAD_EXTENSIONS=["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "ico", "pdf", "docx", "xlsx", "csv", "txt", "md"]'

    fastapi_update_api_router "app/api/v1/router.py" 'api_router.include_router(upload.router, prefix="/upload", tags=["Upload"])' "upload"

    echo ""
    echo "Upload setup completed successfully!"
    echo "Files are stored in app/uploads/ and served under /uploads"
    echo "Endpoints: POST /api/v1/upload/ | POST /api/v1/upload/many | DELETE /api/v1/upload/{path}"
}

setup_fastapi_upload() {
    fastapi_upload "$@"
}
