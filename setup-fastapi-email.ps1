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
        "app/services"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    Set-Content "app/services/email_services.py" -Value $fastapi_email_service_content -Encoding UTF8

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
    } else {
        Write-Host "Email configuration already exists. Skipping..."
    }

    $EnvFiles = @(".env", ".env.example")

    $Variables = @{
        "MAIL_HOST" = "smtp.gmail.com"
        "MAIL_PORT" = "587"
        "MAIL_USERNAME" = "your@email.com"
        "MAIL_PASSWORD" = "your_password"
        "MAIL_FROM" = "your@email.com"
        "MAIL_FROM_NAME" = "Your App"
        "MAIL_TLS" = "true"
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
            } else {
                Write-Host "$key already exists in $envfile, skipping"
            }
        }
    }

    Write-Host "Email setup completed successfully!"
}

function Setup-Fastapi-Mail {
    Fastapi-Email
}