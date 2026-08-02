$fastapi_email_service_content = @'
import aiosmtplib
from email.message import EmailMessage
from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateNotFound

from app.core.config import settings


class EmailService:
    def __init__(self):
        self.env = Environment(
            loader=FileSystemLoader("app/templates"),
            autoescape=select_autoescape(["html", "xml"])
        )


    def render_template(self, template_name: str, data: dict) -> str:
        try:
            template = self.env.get_template(f"emails/{template_name}.html")
            return template.render(**data)

        except TemplateNotFound:
            raise Exception(f"Email template '{template_name}' not found")

        except Exception as e:
            raise Exception(f"Template rendering error: {str(e)}")


    async def send_email(self, to: str, subject: str, template_name: str, data: dict):
        try:
            html_content = self.render_template(template_name, data)

            message = EmailMessage()
            message["From"] = f"{settings.MAIL_FROM_NAME} <{settings.MAIL_FROM}>"
            message["To"] = to
            message["Subject"] = subject

            message.set_content("This is a fallback email")
            message.add_alternative(html_content, subtype="html")

            await aiosmtplib.send(
                message,
                hostname=settings.MAIL_HOST,
                port=settings.MAIL_PORT,
                username=settings.MAIL_USERNAME,
                password=settings.MAIL_PASSWORD,
                start_tls=True,
            )

            return {
                "success": True,
                "message": "Email sent successfully"
            }

        except aiosmtplib.SMTPException as e:
            return {
                "success": False,
                "message": "SMTP error while sending email"
            }

        except ConnectionError as e:
            return {
                "success": False,
                "message": "Connection error while sending email"
            }

        except Exception as e:
            return {
                "success": False,
                "message": "Unexpected error while sending email"
            }

'@


$fastapi_email_env_config = @'

    # ------------------------------
    # Email Configuration
    # ------------------------------
    MAIL_HOST: str
    MAIL_PORT: int
    MAIL_USERNAME: str
    MAIL_PASSWORD: str
    MAIL_FROM: str
    MAIL_FROM_NAME: str
    MAIL_TLS: bool = True
'@


$fastapi_email_schemas_content = @'
from typing import Any
from pydantic import BaseModel, EmailStr, Field


class EmailTemplateRead(BaseModel):
    name: str


class EmailPreviewRequest(BaseModel):
    template_name: str
    data: dict[str, Any] = Field(default_factory=dict)


class EmailTestRequest(BaseModel):
    to: EmailStr
    subject: str
    template_name: str
    data: dict[str, Any] = Field(default_factory=dict)
'@


$fastapi_email_endpoint_content = @'
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import HTMLResponse

from app.schemas.email import EmailPreviewRequest, EmailTemplateRead, EmailTestRequest
from app.services.email_services import EmailService

router = APIRouter()

TEMPLATES_DIR = Path("app/templates/emails")


def _list_template_names() -> list[str]:
    if not TEMPLATES_DIR.is_dir():
        return []
    return sorted(p.stem for p in TEMPLATES_DIR.glob("*.html"))


@router.get("/templates", response_model=list[EmailTemplateRead])
async def list_templates():
    return [{"name": name} for name in _list_template_names()]


@router.post("/preview", response_class=HTMLResponse)
async def preview_template(payload: EmailPreviewRequest):
    service = EmailService()
    try:
        return service.render_template(payload.template_name, payload.data)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/send")
async def send_email(payload: EmailTestRequest):
    service = EmailService()
    result = await service.send_email(
        to=payload.to,
        subject=payload.subject,
        template_name=payload.template_name,
        data=payload.data,
    )
    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("message", "Email sending failed"))
    return result
'@


$fastapi_email_welcome_template = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Welcome, {{ name }}</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f6f8;font-family:Arial,Helvetica,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f8;">
        <tr>
            <td align="center" style="padding:40px 16px;">
                <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:8px;">
                    <tr>
                        <td style="background-color:#0ea5e9;padding:32px;text-align:center;">
                            <h1 style="margin:0;color:#ffffff;font-size:24px;">Welcome, {{ name }}!</h1>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:32px;color:#334155;font-size:15px;line-height:1.6;">
                            <p style="margin:0 0 16px;">Hello {{ name }},</p>
                            <p style="margin:0 0 16px;">{{ message | default("Thank you for joining us!") }}</p>
                            <p style="margin:0;">The {{ app_name | default("FastAPI") }} team</p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
'@


function Fastapi-Email {
    if (-not (Test-Path "venv")) {
        Write-Host "Creating virtual environment"
        python -m venv venv

        Write-Host "Activating virtual environment"
        & .\venv\Scripts\Activate.ps1
    }

    Write-Host "Upgrading pip"
    python -m pip install --upgrade pip

    Write-Host "Installing dependencies..."
    pip install Jinja2 aiosmtplib Jinja2 email-validator
    pip freeze > requirements.txt

    $dirs = @(
        "app/templates/emails",
        "app/services",
        "app/schemas",
        "app/api/v1/endpoints"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "app/services/email_services.py" -Value $fastapi_email_service_content -Encoding UTF8

    Set-Content "app/schemas/email.py" -Value $fastapi_email_schemas_content -Encoding UTF8
    Set-Content "app/api/v1/endpoints/email.py" -Value $fastapi_email_endpoint_content -Encoding UTF8
    Set-Content "app/templates/emails/welcome.html" -Value $fastapi_email_welcome_template -Encoding UTF8

    Write-Host "Registering email router in app/api/v1/router.py..."
    fastapi_update_api_router "app/api/v1/router.py" 'api_router.include_router(email.router, prefix="/email", tags=["Email"])' "email"

    Write-Host "Updating email configuration in config.py..."

    $ConfigPath = "app/core/config.py"

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "config.py not found at $ConfigPath"
        return
    }

    $content = Get-Content $ConfigPath -Raw

    if ($content -notmatch "MAIL_HOST:") {
        $updatedContent = $content -replace "(CORS_ORIGINS:\s*List\[str\])", "`$1`n$fastapi_email_env_config"

        Set-Content -Path $ConfigPath -Value $updatedContent -Encoding UTF8
        Write-Host "Email configuration added successfully!"
    }
    else {
        Write-Host "Email configuration already exists. Skipping..."
    }

    $EnvFiles = @(".env", ".env.example")

    $Variables = @{
        "MAIL_HOST"      = "smtp.gmail.com"
        "MAIL_PORT"      = "587"
        "MAIL_USERNAME"  = "your@email.com"
        "MAIL_PASSWORD"  = "your_password"
        "MAIL_FROM"      = "your@email.com"
        "MAIL_FROM_NAME" = "Your App"
        "MAIL_TLS"       = "true"
    }

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
            }
            else {
                Write-Host "$key already exists in $envfile, skipping"
            }
        }
    }

    Write-Host "Email setup completed successfully!"
}

function Setup-Fastapi-Mail {
    Fastapi-Email
}