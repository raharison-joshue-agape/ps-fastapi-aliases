$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptDir\create-fastapi-project.ps1"
. "$scriptDir\setup-fastapi-database.ps1"
. "$scriptDir\setup-fastapi-email.ps1"
. "$scriptDir\setup-fastapi-upload.ps1"
