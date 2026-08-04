#!/usr/bin/env bash
# FastAPI Project Aliases - Linux (bash) entry point.
# Dot-sources every module located in its own directory, so the shortcuts
# work no matter where the project has been copied to.
#
# Add to ~/.bashrc or ~/.zshrc:
#   . "$HOME/.config/alias/fastapi-aliases-project/linux/index.sh"

_FASTAPI_LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=create-fastapi-project.sh
. "$_FASTAPI_LINUX_DIR/create-fastapi-project.sh"
# shellcheck source=setup-fastapi-database.sh
. "$_FASTAPI_LINUX_DIR/setup-fastapi-database.sh"
# shellcheck source=setup-fastapi-email.sh
. "$_FASTAPI_LINUX_DIR/setup-fastapi-email.sh"
# shellcheck source=setup-fastapi-pdf.sh
. "$_FASTAPI_LINUX_DIR/setup-fastapi-pdf.sh"
# shellcheck source=setup-fastapi-upload.sh
. "$_FASTAPI_LINUX_DIR/setup-fastapi-upload.sh"
