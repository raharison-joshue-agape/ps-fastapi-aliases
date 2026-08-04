#!/usr/bin/env bash
# FastAPI PDF setup for Linux (bash).
# Mirrors the Windows PowerShell module (setup-fastapi-pdf.ps1).
# Generates PDF service with WeasyPrint (recommended), ReportLab, or FPDF2.

fastapi_pdf_config_block() {
    cat <<'PY_EOF'

    # ------------------------------
    # PDF Configuration
    # ------------------------------
    PDF_OUTPUT_DIR: str = "output/pdfs"
    PDF_TEMPLATE_DIR: str = "app/templates/pdfs"
PY_EOF
}

fastapi_pdf_service_weasyprint() {
    cat <<'PY_EOF'
from pathlib import Path
from weasyprint import HTML
from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateNotFound

from app.core.config import settings


class PDFService:
    def __init__(self):
        self.env = Environment(
            loader=FileSystemLoader(settings.PDF_TEMPLATE_DIR),
            autoescape=select_autoescape(["html", "xml"])
        )
        self.output_dir = Path(settings.PDF_OUTPUT_DIR)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def render_template(self, template_name: str, data: dict) -> str:
        try:
            template = self.env.get_template(f"{template_name}.html")
            return template.render(**data)
        except TemplateNotFound:
            raise Exception(f"PDF template '{template_name}' not found")
        except Exception as e:
            raise Exception(f"Template rendering error: {str(e)}")

    def generate_pdf(self, template_name: str, data: dict, output_filename: str = None) -> Path:
        html_content = self.render_template(template_name, data)

        if output_filename is None:
            output_filename = f"{template_name}.pdf"

        output_path = self.output_dir / output_filename
        HTML(string=html_content).write_pdf(str(output_path))

        return output_path
PY_EOF
}

fastapi_pdf_service_reportlab() {
    cat <<'PY_EOF'
from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateNotFound

from app.core.config import settings


class PDFService:
    def __init__(self):
        self.env = Environment(
            loader=FileSystemLoader(settings.PDF_TEMPLATE_DIR),
            autoescape=select_autoescape(["html", "xml"])
        )
        self.output_dir = Path(settings.PDF_OUTPUT_DIR)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def render_template(self, template_name: str, data: dict) -> str:
        try:
            template = self.env.get_template(f"{template_name}.html")
            return template.render(**data)
        except TemplateNotFound:
            raise Exception(f"PDF template '{template_name}' not found")
        except Exception as e:
            raise Exception(f"Template rendering error: {str(e)}")

    def generate_pdf_from_text(self, text: str, output_filename: str = None) -> Path:
        if output_filename is None:
            output_filename = "document.pdf"

        output_path = self.output_dir / output_filename
        c = canvas.Canvas(str(output_path), pagesize=A4)
        width, height = A4

        c.setFont("Helvetica", 12)
        text_object = c.beginText(20 * mm, height - 20 * mm)
        text_object.textLine(text)
        c.drawText(text_object)
        c.save()

        return output_path
PY_EOF
}

fastapi_pdf_service_fpdf() {
    cat <<'PY_EOF'
from pathlib import Path
from fpdf import FPDF
from jinja2 import Environment, FileSystemLoader, select_autoescape, TemplateNotFound

from app.core.config import settings


class PDFService:
    def __init__(self):
        self.env = Environment(
            loader=FileSystemLoader(settings.PDF_TEMPLATE_DIR),
            autoescape=select_autoescape(["html", "xml"])
        )
        self.output_dir = Path(settings.PDF_OUTPUT_DIR)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def render_template(self, template_name: str, data: dict) -> str:
        try:
            template = self.env.get_template(f"{template_name}.html")
            return template.render(**data)
        except TemplateNotFound:
            raise Exception(f"PDF template '{template_name}' not found")
        except Exception as e:
            raise Exception(f"Template rendering error: {str(e)}")

    def generate_pdf_from_text(self, text: str, output_filename: str = None) -> Path:
        if output_filename is None:
            output_filename = "document.pdf"

        output_path = self.output_dir / output_filename
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font("Arial", size=12)
        pdf.multi_cell(0, 10, text)
        pdf.output(str(output_path))

        return output_path
PY_EOF
}

fastapi_pdf_schemas() {
    cat <<'PY_EOF'
from typing import Any
from pydantic import BaseModel, Field


class PDFGenerateRequest(BaseModel):
    template_name: str
    data: dict[str, Any] = Field(default_factory=dict)
    output_filename: str | None = None
PY_EOF
}

fastapi_pdf_endpoint_weasyprint() {
    cat <<'PY_EOF'
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from app.schemas.pdf import PDFGenerateRequest
from app.services.pdf_service import PDFService

router = APIRouter()


@router.post("/generate")
async def generate_pdf(payload: PDFGenerateRequest):
    service = PDFService()
    try:
        output_path = service.generate_pdf(
            template_name=payload.template_name,
            data=payload.data,
            output_filename=payload.output_filename
        )
        return FileResponse(
            path=str(output_path),
            media_type="application/pdf",
            filename=output_path.name
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/templates")
async def list_templates():
    template_dir = Path("app/templates/pdfs")
    if not template_dir.is_dir():
        return []
    return sorted(p.stem for p in template_dir.glob("*.html"))
PY_EOF
}

fastapi_pdf_endpoint_reportlab() {
    cat <<'PY_EOF'
from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from app.schemas.pdf import PDFGenerateRequest
from app.services.pdf_service import PDFService

router = APIRouter()


@router.post("/generate/text")
async def generate_pdf_from_text(text: str, output_filename: str = None):
    service = PDFService()
    try:
        output_path = service.generate_pdf_from_text(text, output_filename)
        return FileResponse(
            path=str(output_path),
            media_type="application/pdf",
            filename=output_path.name
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
PY_EOF
}

fastapi_pdf_template() {
    cat <<'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{{ title | default("Invoice") }}</title>
    <style>
        @page {
            size: A4;
            margin: 20mm;
        }
        body {
            font-family: Arial, Helvetica, sans-serif;
            color: #333;
            line-height: 1.6;
            margin: 0;
            padding: 0;
        }
        .header {
            background-color: #0ea5e9;
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
        }
        .content {
            padding: 20px;
        }
        .info-section {
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
        }
        .info-box {
            flex: 1;
            padding: 15px;
            background-color: #f8fafc;
            border-radius: 6px;
            margin: 0 10px;
        }
        .info-box h3 {
            margin: 0 0 10px 0;
            color: #0ea5e9;
            font-size: 14px;
            text-transform: uppercase;
        }
        .info-box p {
            margin: 5px 0;
            font-size: 13px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }
        th {
            background-color: #f1f5f9;
            font-weight: bold;
            font-size: 13px;
            text-transform: uppercase;
        }
        td {
            font-size: 13px;
        }
        .total-section {
            text-align: right;
            margin-top: 20px;
        }
        .total-row {
            display: flex;
            justify-content: flex-end;
            margin-bottom: 8px;
        }
        .total-label {
            font-weight: bold;
            margin-right: 20px;
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #e2e8f0;
            text-align: center;
            font-size: 12px;
            color: #64748b;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>{{ title | default("Invoice") }}</h1>
        <p>{{ subtitle | default("") }}</p>
    </div>

    <div class="content">
        <div class="info-section">
            <div class="info-box">
                <h3>From</h3>
                <p><strong>{{ from_name | default("Company Name") }}</strong></p>
                <p>{{ from_address | default("") }}</p>
                <p>{{ from_email | default("") }}</p>
            </div>
            <div class="info-box">
                <h3>To</h3>
                <p><strong>{{ to_name | default("Client Name") }}</strong></p>
                <p>{{ to_address | default("") }}</p>
                <p>{{ to_email | default("") }}</p>
            </div>
            <div class="info-box">
                <h3>Details</h3>
                <p><strong>Date:</strong> {{ date | default("") }}</p>
                <p><strong>Invoice #:</strong> {{ invoice_number | default("") }}</p>
                <p><strong>Due:</strong> {{ due_date | default("") }}</p>
            </div>
        </div>

        <table>
            <thead>
                <tr>
                    <th>Description</th>
                    <th>Quantity</th>
                    <th>Unit Price</th>
                    <th>Total</th>
                </tr>
            </thead>
            <tbody>
                {% for item in items | default([]) %}
                <tr>
                    <td>{{ item.description }}</td>
                    <td>{{ item.quantity }}</td>
                    <td>{{ item.unit_price }}</td>
                    <td>{{ item.total }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>

        <div class="total-section">
            <div class="total-row">
                <span class="total-label">Subtotal:</span>
                <span>{{ subtotal | default("0.00") }}</span>
            </div>
            <div class="total-row">
                <span class="total-label">Tax ({{ tax_rate | default("0") }}%):</span>
                <span>{{ tax | default("0.00") }}</span>
            </div>
            <div class="total-row">
                <span class="total-label"><strong>Total:</strong></span>
                <span><strong>{{ total | default("0.00") }}</strong></span>
            </div>
        </div>

        {% if notes %}
        <div style="margin-top: 30px; padding: 15px; background-color: #fffbeb; border-radius: 6px;">
            <strong>Notes:</strong>
            <p>{{ notes }}</p>
        </div>
        {% endif %}
    </div>

    <div class="footer">
        <p>{{ footer | default("Thank you for your business!") }}</p>
    </div>
</body>
</html>
HTML_EOF
}

fastapi_pdf() {
    if [ ! -d "venv" ]; then
        echo "Creating virtual environment"
        python3 -m venv venv

        echo "Activating virtual environment"
        # shellcheck disable=SC1091
        source venv/bin/activate
    fi

    echo "Upgrading pip"
    python -m pip install --upgrade pip

    echo "=========================================="
    echo "  FastAPI PDF Setup"
    echo "=========================================="
    echo ""
    echo "Which PDF library do you want to use?"
    echo ""
    echo "1) WeasyPrint (RECOMMENDED)"
    echo "   - Best HTML/CSS to PDF conversion"
    echo "   - Supports complex layouts & styling"
    echo "   - Uses CSS @page rules"
    echo ""
    echo "2) ReportLab"
    echo "   - Low-level PDF generation"
    echo "   - Programmatic control"
    echo "   - No HTML template support"
    echo ""
    echo "3) FPDF2"
    echo "   - Lightweight & simple"
    echo "   - Basic PDF generation"
    echo "   - Limited styling options"
    echo ""
    echo "=========================================="

    read -r -p "Enter choice (1-3): " PDF_CHOICE

    case "$PDF_CHOICE" in
        1)
            echo "Installing WeasyPrint..."
            pip install WeasyPrint Jinja2
            ;;
        2)
            echo "Installing ReportLab..."
            pip install reportlab Jinja2
            ;;
        3)
            echo "Installing FPDF2..."
            pip install fpdf2 Jinja2
            ;;
        *)
            echo "Invalid choice. Using WeasyPrint (RECOMMENDED) by default."
            pip install WeasyPrint Jinja2
            PDF_CHOICE="1"
            ;;
    esac

    pip freeze > requirements.txt

    mkdir -p app/templates/pdfs app/services app/schemas app/api/v1/endpoints output/pdfs

    case "$PDF_CHOICE" in
        1)
            fastapi_pdf_service_weasyprint > app/services/pdf_service.py
            fastapi_pdf_endpoint_weasyprint > app/api/v1/endpoints/pdf.py
            ;;
        2)
            fastapi_pdf_service_reportlab > app/services/pdf_service.py
            fastapi_pdf_endpoint_reportlab > app/api/v1/endpoints/pdf.py
            ;;
        3)
            fastapi_pdf_service_fpdf > app/services/pdf_service.py
            fastapi_pdf_endpoint_weasyprint > app/api/v1/endpoints/pdf.py
            ;;
    esac

    fastapi_pdf_schemas > app/schemas/pdf.py
    fastapi_pdf_template > app/templates/pdfs/invoice.html

    echo "Registering PDF router in app/api/v1/router.py..."
    fastapi_update_api_router "app/api/v1/router.py" 'api_router.include_router(pdf.router, prefix="/pdf", tags=["PDF"])' "pdf"

    echo "Updating PDF configuration in config.py..."
    local config_path="app/core/config.py"

    if [ ! -f "$config_path" ]; then
        echo "config.py not found at $config_path"
        return
    fi

    if ! grep -q "PDF_OUTPUT_DIR:" "$config_path"; then
        fastapi_config_insert_after_cors "$(fastapi_pdf_config_block)" "$config_path"
        echo "PDF configuration added successfully!"
    else
        echo "PDF configuration already exists. Skipping..."
    fi

    fastapi_update_env_files \
        "PDF_OUTPUT_DIR=output/pdfs" \
        "PDF_TEMPLATE_DIR=app/templates/pdfs"

    echo ""
    echo "PDF setup completed successfully!"
    echo ""
    echo "Generated files:"
    echo "  - app/services/pdf_service.py"
    echo "  - app/schemas/pdf.py"
    echo "  - app/api/v1/endpoints/pdf.py"
    echo "  - app/templates/pdfs/invoice.html"
    echo ""
    echo "API Endpoints:"
    echo "  POST /api/v1/pdf/generate - Generate PDF from template"
    echo "  GET  /api/v1/pdf/templates - List available templates"
}

setup_fastapi_pdf() {
    fastapi_pdf "$@"
}
