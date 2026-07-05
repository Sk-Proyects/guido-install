#!/usr/bin/env bash
# Guido — instalador para Mac (doble click). This is the PUBLIC bootstrap artifact
# (spec 2026-07-04 §7): thin by design — prereqs + gh login + clone, then it DELEGATES to
# the cloned repo's installer (heavy logic stays versioned in cortex). Idempotent.
set -u -o pipefail

SRC="${GUIDO_SRC:-$HOME/.guido/src}"
REPO_URL="${GUIDO_REPO_URL:-https://github.com/Sk-Proyects/guido-cortex}"

say() { echo ">> $*"; }
die() { echo "ERROR: $*" >&2; echo "presiona Enter para cerrar."; read -r _; exit 1; }

case "$(uname -s)" in
  Darwin) : ;;
  *) die "este instalador es para Mac. En Windows usa install.bat." ;;
esac

echo ""
echo "  Hola — vamos a instalar Guido. Te va a pedir un par de logins en el navegador."
echo ""

# 1) Homebrew (official installer is interactive; it prompts for your password itself).
if ! command -v brew >/dev/null 2>&1; then
  say "instalando Homebrew (el gestor de paquetes de Mac)..."
  BREW_INSTALLER="$(mktemp)"
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$BREW_INSTALLER" \
    || die "no pude descargar Homebrew — revisa tu conexión a internet"
  /bin/bash "$BREW_INSTALLER" || die "no pude instalar Homebrew"
  rm -f "$BREW_INSTALLER"
  # brew lands outside PATH on first install (Apple Silicon: /opt/homebrew)
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
fi

# 2) git + gh
command -v git >/dev/null 2>&1 || { say "instalando git..."; brew install git || die "git"; }
command -v gh >/dev/null 2>&1 || { say "instalando GitHub CLI..."; brew install gh || die "gh"; }

# 3) gh login — MUST precede the clone (the guido repo is private; spec §15 resolved).
if ! gh auth status >/dev/null 2>&1; then
  say "inicia sesión en GitHub (se abre el navegador)..."
  gh auth login --hostname github.com --git-protocol https --web || die "no pude conectar GitHub"
fi
gh auth setup-git || die "no pude configurar git con tu cuenta de GitHub"

# 4) uv (installs Python automatically when needed)
if ! command -v uv >/dev/null 2>&1; then
  say "instalando uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh || die "no pude instalar uv"
  export PATH="$HOME/.local/bin:$PATH"
fi

# 5) clone the managed copy (guido's own hidden checkout — you never touch it)
if [ ! -d "$SRC/.git" ]; then
  say "descargando Guido..."
  mkdir -p "$(dirname "$SRC")"
  git clone "$REPO_URL" "$SRC" || die "no pude descargar Guido — ¿tu cuenta tiene acceso?"
fi

# 6) delegate to the versioned installer (uv install + launcher + icon + doctor)
bash "$SRC/scripts/install.sh" --managed --yes || die "la instalación falló"

say "¡listo! Guido quedó en tu escritorio."
[ "${GUIDO_BOOTSTRAP_NO_LAUNCH:-0}" = "1" ] && exit 0
exec "$HOME/.guido/bin/guido-launch.sh"
