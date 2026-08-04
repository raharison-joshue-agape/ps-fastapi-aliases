#!/usr/bin/env zsh
# FastAPI Project Aliases - macOS (zsh) entry point.
# Dot-sources every module located in its own directory, so the shortcuts
# work no matter where the project has been copied to.
#
# Add to ~/.zshrc (zsh, shell par defaut de macOS):
#   . "$HOME/.config/alias/fastapi-aliases-project/macos/index.zsh"

_FASTAPI_MACOS_DIR="${0:A:h}"

# shellcheck source=create-fastapi-project.zsh
. "$_FASTAPI_MACOS_DIR/create-fastapi-project.zsh"
# shellcheck source=setup-fastapi-database.zsh
. "$_FASTAPI_MACOS_DIR/setup-fastapi-database.zsh"
# shellcheck source=setup-fastapi-email.zsh
. "$_FASTAPI_MACOS_DIR/setup-fastapi-email.zsh"
# shellcheck source=setup-fastapi-pdf.zsh
. "$_FASTAPI_MACOS_DIR/setup-fastapi-pdf.zsh"
# shellcheck source=setup-fastapi-upload.zsh
. "$_FASTAPI_MACOS_DIR/setup-fastapi-upload.zsh"
