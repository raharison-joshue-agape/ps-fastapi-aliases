$fastapi_pdf_config = @'

    # ------------------------------
    # PDF Configuration
    # ------------------------------
    PDF_OUTPUT_DIR: str = "output/pdfs"
    PDF_TEMPLATE_DIR: str = "app/templates/pdfs"
'@


$fastapi_pdf_service_weasyprint_content = @'
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
'@


$fastapi_pdf_service_reportlab_content = @'
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
'@


$fastapi_pdf_service_fpdf_content = @'
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
'@


$fastapi_pdf_schemas_content = @'
from typing import Any
from pydantic import BaseModel, Field


class PDFGenerateRequest(BaseModel):
    template_name: str
    data: dict[str, Any] = Field(default_factory=dict)
    output_filename: str | None = None
'@


$fastapi_pdf_endpoint_weasyprint_content = @'
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
'@


$fastapi_pdf_endpoint_reportlab_content = @'
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
'@


$fastapi_pdf_template = @'
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
                <p><strong>{{ to_name | default("Client Name") }}</p>
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
'@


function Fastapi-Pdf {
    if (-not (Test-Path "venv")) {
        Write-Host "Creating virtual environment"
        python -m venv venv

        Write-Host "Activating virtual environment"
        & .\venv\Scripts\Activate.ps1
    }

    Write-Host "Upgrading pip"
    python -m pip install --upgrade pip

    Write-Host "=========================================="
    Write-Host "  FastAPI PDF Setup"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Which PDF library do you want to use?"
    Write-Host ""
    Write-Host "1) WeasyPrint (RECOMMENDED)"
    Write-Host "   - Best HTML/CSS to PDF conversion"
    Write-Host "   - Supports complex layouts & styling"
    Write-Host "   - Uses CSS @page rules"
    Write-Host ""
    Write-Host "2) ReportLab"
    Write-Host "   - Low-level PDF generation"
    Write-Host "   - Programmatic control"
    Write-Host "   - No HTML template support"
    Write-Host ""
    Write-Host "3) FPDF2"
    Write-Host "   - Lightweight & simple"
    Write-Host "   - Basic PDF generation"
    Write-Host "   - Limited styling options"
    Write-Host ""
    Write-Host "=========================================="

    $PDF_CHOICE = Read-Host "Enter choice (1-3)"

    switch ($PDF_CHOICE) {
        "1" {
            Write-Host "Installing WeasyPrint..."
            pip install WeasyPrint Jinja2
        }
        "2" {
            Write-Host "Installing ReportLab..."
            pip install reportlab Jinja2
        }
        "3" {
            Write-Host "Installing FPDF2..."
            pip install fpdf2 Jinja2
        }
        default {
            Write-Host "Invalid choice. Using WeasyPrint (RECOMMENDED) by default."
            pip install WeasyPrint Jinja2
            $PDF_CHOICE = "1"
        }
    }

    pip freeze > requirements.txt

    $dirs = @(
        "app/templates/pdfs",
        "app/services",
        "app/schemas",
        "app/api/v1/endpoints",
        "output/pdfs"
    )
    foreach ($d in $dirs) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

    switch ($PDF_CHOICE) {
        "1" {
            Set-Content "app/services/pdf_service.py" -Value $fastapi_pdf_service_weasyprint_content -Encoding UTF8
            Set-Content "app/api/v1/endpoints/pdf.py" -Value $fastapi_pdf_endpoint_weasyprint_content -Encoding UTF8
        }
        "2" {
            Set-Content "app/services/pdf_service.py" -Value $fastapi_pdf_service_reportlab_content -Encoding UTF8
            Set-Content "app/api/v1/endpoints/pdf.py" -Value $fastapi_pdf_endpoint_reportlab_content -Encoding UTF8
        }
        "3" {
            Set-Content "app/services/pdf_service.py" -Value $fastapi_pdf_service_fpdf_content -Encoding UTF8
            Set-Content "app/api/v1/endpoints/pdf.py" -Value $fastapi_pdf_endpoint_weasyprint_content -Encoding UTF8
        }
    }

    Set-Content "app/schemas/pdf.py" -Value $fastapi_pdf_schemas_content -Encoding UTF8
    Set-Content "app/templates/pdfs/invoice.html" -Value $fastapi_pdf_template -Encoding UTF8

    Write-Host "Registering PDF router in app/api/v1/router.py..."
    fastapi_update_api_router "app/api/v1/router.py" 'api_router.include_router(pdf.router, prefix="/pdf", tags=["PDF"])' "pdf"

    Write-Host "Updating PDF configuration in config.py..."

    $ConfigPath = "app/core/config.py"

    if (-not (Test-Path $ConfigPath)) {
        Write-Host "config.py not found at $ConfigPath"
        return
    }

    $content = Get-Content $ConfigPath -Raw

    if ($content -notmatch "PDF_OUTPUT_DIR:") {
        $updatedContent = $content -replace "(CORS_ORIGINS:\s*List\[str\])", "`$1`n$fastapi_pdf_config"

        Set-Content -Path $ConfigPath -Value $updatedContent -Encoding UTF8
        Write-Host "PDF configuration added successfully!"
    }
    else {
        Write-Host "PDF configuration already exists. Skipping..."
    }

    $EnvFiles = @(".env", ".env.example")

    $Variables = @{
        "PDF_OUTPUT_DIR"  = "output/pdfs"
        "PDF_TEMPLATE_DIR" = "app/templates/pdfs"
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

    Write-Host ""
    Write-Host "PDF setup completed successfully!"
    Write-Host ""
    Write-Host "Generated files:"
    Write-Host "  - app/services/pdf_service.py"
    Write-Host "  - app/schemas/pdf.py"
    Write-Host "  - app/api/v1/endpoints/pdf.py"
    Write-Host "  - app/templates/pdfs/invoice.html"
    Write-Host ""
    Write-Host "API Endpoints:"
    Write-Host "  POST /api/v1/pdf/generate - Generate PDF from template"
    Write-Host "  GET  /api/v1/pdf/templates - List available templates"
}

function Setup-Fastapi-Pdf {
    Fastapi-Pdf
}
