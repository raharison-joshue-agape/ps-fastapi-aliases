#!/usr/bin/env bash
# FastAPI email setup for Linux (bash).
# Mirrors the Windows PowerShell module (setup-fastapi-email.ps1).
# Generates an async EmailService (aiosmtplib) + Jinja2 templates.

fastapi_email_config_block() {
    cat <<'PY_EOF'

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
PY_EOF
}

fastapi_email_service() {
    cat <<'PY_EOF'
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

        except aiosmtplib.SMTPException:
            return {
                "success": False,
                "message": "SMTP error while sending email"
            }

        except ConnectionError:
            return {
                "success": False,
                "message": "Connection error while sending email"
            }

        except Exception:
            return {
                "success": False,
                "message": "Unexpected error while sending email"
            }
PY_EOF
}

fastapi_email() {
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
    pip install Jinja2 aiosmtplib email-validator
    pip freeze > requirements.txt

    mkdir -p app/templates/emails app/services

    fastapi_email_service > app/services/email_services.py

    echo "Updating email configuration in config.py..."
    local config_path="app/core/config.py"

    if [ ! -f "$config_path" ]; then
        echo "config.py not found at $config_path"
        return
    fi

    if ! grep -q "MAIL_HOST:" "$config_path"; then
        fastapi_config_insert_after_cors "$(fastapi_email_config_block)" "$config_path"
        echo "Email configuration added successfully!"
    else
        echo "Email configuration already exists. Skipping..."
    fi

    fastapi_update_env_files \
        "MAIL_HOST=smtp.gmail.com" \
        "MAIL_PORT=587" \
        "MAIL_USERNAME=your@email.com" \
        "MAIL_PASSWORD=your_password" \
        "MAIL_FROM=your@email.com" \
        "MAIL_FROM_NAME=Your App" \
        "MAIL_TLS=true"

    echo "Email setup completed successfully!"
}

setup_fastapi_mail() {
    fastapi_email "$@"
}
