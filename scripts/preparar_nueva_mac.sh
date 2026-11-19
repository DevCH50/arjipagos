#!/bin/bash
# =============================================================================
# preparar_nueva_mac.sh — deja lista una Mac con Apple silicon para ArjiPagos
# =============================================================================
#
# Automatiza la parte mecánica de MIGRAR_A_NUEVA_MAC_2027.md: Homebrew,
# CocoaPods, oh-my-zsh, el .zshrc, los enlaces de ~/Developer (de los que
# depende el comando «arjipagos»), Flutter, la clave SSH y la memoria de
# Claude Code.
#
# Lo que NO hace, a propósito, porque necesita a una persona delante:
#   - Instalar Xcode (App Store) ni aceptar su licencia sin preguntar.
#   - Importar los certificados .p12 (llevan contraseña).
#   - Iniciar sesión con el Apple ID en Xcode ni dar de alta la clave en GitHub.
#   - Dar permisos de «Acceso total al disco» (solo desde Ajustes del Sistema).
#
# Cómo se ejecuta (con el SSD T7 conectado):
#   bash /Volumes/T7/Developer/arjipagos/scripts/preparar_nueva_mac.sh
#   bash .../preparar_nueva_mac.sh --comprobar      # solo informa, no cambia nada
#   FLUTTER_VERSION=3.50.0 bash .../preparar_nueva_mac.sh
#
# Se llama con «bash» delante porque el T7 es exFAT y no guarda el permiso de
# ejecución de forma fiable.
#
# Es idempotente: se puede ejecutar varias veces. Lo que ya está hecho lo
# salta, y antes de reemplazar el .zshrc guarda un respaldo con fecha.
# =============================================================================

set -u

# ── Constantes ───────────────────────────────────────────────────────────────
readonly T7="/Volumes/T7/Developer"
readonly PROYECTO="$T7/arjipagos"
readonly DEVELOPER="$HOME/Developer"
readonly FLUTTER_DIR="$HOME/develop/flutter"
readonly MARCA_ZSHRC="# >>> arjipagos (preparar_nueva_mac.sh) >>>"
# Enlaces de ~/Developer → T7. Son los mismos que en la Mac Intel.
readonly ENLACES=("arjipagos" "sismmun" "SIACiOS.zip")
# Paquetes de Homebrew que usan el proyecto y la terminal.
readonly PAQUETES_BREW=("cocoapods" "git-lfs" "zsh-autosuggestions" "zsh-syntax-highlighting")
readonly FUENTE_CASK="font-meslo-lg-nerd-font"

SOLO_COMPROBAR=false
[[ "${1:-}" == "--comprobar" ]] && SOLO_COMPROBAR=true

# ── Salida con colores ───────────────────────────────────────────────────────
readonly VERDE='\033[0;32m' AMARILLO='\033[1;33m' ROJO='\033[0;31m' AZUL='\033[0;34m' NC='\033[0m'
titulo() { echo; echo -e "${AZUL}══ $1 ══${NC}"; }
ok()     { echo -e "  ${VERDE}✓${NC} $1"; }
aviso()  { echo -e "  ${AMARILLO}!${NC} $1"; }
error()  { echo -e "  ${ROJO}✗${NC} $1"; }

# Pregunta sí/no. En modo --comprobar siempre responde que no.
preguntar() {
  $SOLO_COMPROBAR && return 1
  local respuesta
  read -r -p "  ¿$1? [s/N] " respuesta
  [[ "$respuesta" =~ ^[sS]$ ]]
}

# Lista de lo que queda pendiente a mano; se imprime al final.
PENDIENTES=()
pendiente() { PENDIENTES+=("$1"); aviso "$1"; }

# =============================================================================
# 1. Comprobaciones previas — si fallan, no se toca nada
# =============================================================================
titulo "1. Comprobaciones previas"

if [[ "$(uname -m)" != "arm64" ]]; then
  error "Esta Mac no es Apple silicon ($(uname -m)). El script es para la Mac nueva."
  error "Si estás en una terminal con Rosetta, ábrela sin Rosetta y vuelve a ejecutarlo."
  exit 1
fi
ok "Apple silicon (arm64)"

VERSION_MACOS="$(sw_vers -productVersion)"
if [[ "${VERSION_MACOS%%.*}" -lt 26 ]]; then
  error "macOS $VERSION_MACOS. Xcode 27 pide Tahoe 26.6 o posterior: actualiza antes."
  exit 1
fi
ok "macOS $VERSION_MACOS"

if [[ ! -d "$PROYECTO" ]]; then
  error "No encuentro $PROYECTO."
  error "Conecta el SSD T7 y comprueba que se monta como /Volumes/T7 (no «T7 1»)."
  exit 1
fi
ok "SSD T7 montado con el proyecto"

if [[ -d /Applications/Xcode.app ]]; then
  ok "Xcode instalado: $(/usr/bin/xcodebuild -version 2>/dev/null | head -1)"
  if [[ "$(xcode-select -p 2>/dev/null)" != "/Applications/Xcode.app/Contents/Developer" ]]; then
    if preguntar "Apuntar las herramientas de línea de comandos a Xcode.app (pide contraseña)"; then
      sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
      sudo xcodebuild -license accept
      xcodebuild -runFirstLaunch
      ok "xcode-select apuntando a Xcode.app"
    else
      pendiente "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer && sudo xcodebuild -license accept"
    fi
  else
    ok "xcode-select apunta a Xcode.app"
  fi
else
  pendiente "Instalar Xcode desde el App Store, abrirlo una vez y volver a ejecutar este script"
fi

# =============================================================================
# 2. Homebrew y paquetes
# =============================================================================
titulo "2. Homebrew y paquetes"

if [[ ! -x /opt/homebrew/bin/brew ]]; then
  if preguntar "Instalar Homebrew en /opt/homebrew"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    pendiente "Instalar Homebrew (https://brew.sh)"
  fi
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew en $(brew --prefix)"

  # shellenv en el .zprofile, para que las terminales nuevas encuentren brew
  if ! grep -q "brew shellenv" "$HOME/.zprofile" 2>/dev/null; then
    if ! $SOLO_COMPROBAR; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
      ok "brew shellenv añadido a ~/.zprofile"
    else
      aviso "Falta brew shellenv en ~/.zprofile"
    fi
  fi

  for paquete in "${PAQUETES_BREW[@]}"; do
    if brew list --formula "$paquete" >/dev/null 2>&1; then
      ok "$paquete"
    elif ! $SOLO_COMPROBAR; then
      brew install "$paquete" && ok "$paquete instalado"
    else
      aviso "Falta $paquete"
    fi
  done

  if brew list --cask "$FUENTE_CASK" >/dev/null 2>&1; then
    ok "Fuente $FUENTE_CASK"
  elif ! $SOLO_COMPROBAR; then
    brew install --cask "$FUENTE_CASK" && ok "Fuente $FUENTE_CASK instalada"
    pendiente "Elegir «MesloLGS Nerd Font» en Terminal → Ajustes → Perfil → Texto"
  fi

  if command -v git-lfs >/dev/null 2>&1 && ! $SOLO_COMPROBAR; then
    git lfs install >/dev/null && ok "git-lfs activado"
  fi

  if command -v pod >/dev/null 2>&1; then
    # CocoaPods tiene que ser nativo: bajo Rosetta da errores de ffi/x86_64
    if file "$(command -v pod)" | grep -q "x86_64" ; then
      error "pod es x86_64: reinstalar CocoaPods desde una terminal sin Rosetta"
    else
      ok "CocoaPods $(pod --version)"
    fi
  fi
fi

# =============================================================================
# 3. git global
# =============================================================================
titulo "3. git"

configurar_git() {
  local clave="$1" valor="$2"
  if [[ "$(git config --global --get "$clave")" == "$valor" ]]; then
    ok "$clave = $valor"
  elif ! $SOLO_COMPROBAR; then
    git config --global "$clave" "$valor" && ok "$clave = $valor (configurado)"
  else
    aviso "Falta $clave = $valor"
  fi
}
configurar_git user.name "DevCH50"
configurar_git user.email "r0@tecnointel.mx"
configurar_git color.ui "true"
configurar_git push.default "simple"

# =============================================================================
# 4. oh-my-zsh
# =============================================================================
titulo "4. oh-my-zsh"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  ok "oh-my-zsh instalado"
elif preguntar "Instalar oh-my-zsh"; then
  # RUNZSH=no: no abre otra shell al terminar. KEEP_ZSHRC=yes: no toca el .zshrc;
  # de eso se encarga el paso 6.
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  [[ -d "$HOME/.oh-my-zsh" ]] && ok "oh-my-zsh instalado"
else
  pendiente "Instalar oh-my-zsh: sin él no hay AUTO_CD ni tema"
fi

# =============================================================================
# 5. Los enlaces de ~/Developer — la mitad del comando «arjipagos»
# =============================================================================
titulo "5. Enlaces de ~/Developer"

$SOLO_COMPROBAR || mkdir -p "$DEVELOPER"
for nombre in "${ENLACES[@]}"; do
  destino="$T7/$nombre"
  enlace="$DEVELOPER/$nombre"
  if [[ ! -e "$destino" ]]; then
    aviso "$nombre no existe en el T7; no se crea el enlace"
  elif [[ -L "$enlace" ]]; then
    if [[ "$(readlink "$enlace")" == "$destino" ]]; then
      ok "$enlace → $destino"
    else
      aviso "$enlace apunta a $(readlink "$enlace"); no lo toco"
    fi
  elif [[ -e "$enlace" ]]; then
    # Hay una carpeta o archivo real con ese nombre: no se reemplaza nada
    aviso "$enlace existe y no es un enlace; no lo toco"
  elif ! $SOLO_COMPROBAR; then
    ln -s "$destino" "$enlace" && ok "$enlace → $destino (creado)"
  else
    aviso "Falta el enlace $enlace"
  fi
done

# =============================================================================
# 6. El .zshrc — la otra mitad del comando «arjipagos»
# =============================================================================
titulo "6. ~/.zshrc"

if grep -qF "$MARCA_ZSHRC" "$HOME/.zshrc" 2>/dev/null; then
  ok "~/.zshrc ya está configurado por este script"
elif preguntar "Reemplazar ~/.zshrc (se guarda un respaldo con fecha)"; then
  if [[ -f "$HOME/.zshrc" ]]; then
    respaldo="$HOME/.zshrc.respaldo-$(date +%Y%m%d-%H%M%S)"
    cp "$HOME/.zshrc" "$respaldo" && ok "Respaldo en $respaldo"
  fi
  cat > "$HOME/.zshrc" <<EOF
$MARCA_ZSHRC
# Generado por scripts/preparar_nueva_mac.sh. Ver MIGRAR_A_NUEVA_MAC_2027.md §6.

# ── oh-my-zsh ───────────────────────────────────────────────────────────────
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git vscode python laravel composer postgres jsontools)
source \$ZSH/oh-my-zsh.sh

# ── Integración de iTerm2 (si se usa) ───────────────────────────────────────
test -e "\${HOME}/.iterm2_shell_integration.zsh" && source "\${HOME}/.iterm2_shell_integration.zsh"

# ── PATH ────────────────────────────────────────────────────────────────────
export PATH="\$HOME/develop/flutter/bin:\$HOME/.local/bin:\$PATH"

# ── Complementos de Homebrew ────────────────────────────────────────────────
source "\$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "\$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ── Proyectos ───────────────────────────────────────────────────────────────
# AUTO_CD (de oh-my-zsh): desde ~/Developer, escribir «arjipagos» entra.
# La función hace que funcione desde cualquier carpeta y avisa si falta el SSD.
arjipagos() {
  if [[ ! -d /Volumes/T7/Developer/arjipagos ]]; then
    echo "El SSD T7 no está montado. Conéctalo y vuelve a intentarlo."
    return 1
  fi
  cd ~/Developer/arjipagos
}

# Cada terminal nueva arranca en ~/Developer, como en la Mac Intel.
cd ~/Developer
PROMPT='%1~ %# '
# <<< arjipagos (preparar_nueva_mac.sh) <<<
EOF
  ok "~/.zshrc escrito"
else
  pendiente "Configurar ~/.zshrc a mano (MIGRAR_A_NUEVA_MAC_2027.md §6.4)"
fi

# =============================================================================
# 7. Flutter — la MISMA versión que la Linux
# =============================================================================
titulo "7. Flutter"

if [[ -x "$FLUTTER_DIR/bin/flutter" ]]; then
  ok "Flutter ya instalado: $("$FLUTTER_DIR/bin/flutter" --version 2>/dev/null | head -1)"
  aviso "Comprueba que coincide con la Linux (flutter --version allí)"
elif ! $SOLO_COMPROBAR; then
  version="${FLUTTER_VERSION:-}"
  if [[ -z "$version" ]]; then
    echo "  La versión tiene que ser la misma que la de la Linux (flutter --version allí)."
    read -r -p "  Versión de Flutter [3.50.0]: " version
    version="${version:-3.50.0}"
  fi
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  if git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR" \
     && git -C "$FLUTTER_DIR" checkout --quiet "$version"; then
    "$FLUTTER_DIR/bin/flutter" --version | head -1
    "$FLUTTER_DIR/bin/flutter" precache --ios >/dev/null && ok "Flutter $version listo"
  else
    error "No se pudo instalar Flutter $version"
  fi
else
  aviso "Falta Flutter en $FLUTTER_DIR"
fi

# =============================================================================
# 8. Plataforma iOS (~10 GB, NO se borra nunca)
# =============================================================================
titulo "8. Plataforma iOS de Xcode"

if [[ -d /Applications/Xcode.app ]]; then
  if xcodebuild -showdestinations -scheme Runner -workspace "$PROYECTO/ios/Runner.xcworkspace" 2>/dev/null \
       | grep -q "Any iOS Device"; then
    ok "Destino «Any iOS Device» disponible"
  elif preguntar "Descargar la plataforma iOS (~10 GB, tarda)"; then
    xcodebuild -downloadPlatform iOS && ok "Plataforma iOS instalada"
  else
    pendiente "xcodebuild -downloadPlatform iOS (sin ella no se compila para el iPhone)"
  fi
fi

# =============================================================================
# 9. Clave SSH para GitHub
# =============================================================================
titulo "9. SSH"

if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  ok "Ya hay una clave en ~/.ssh/id_ed25519"
elif preguntar "Generar una clave SSH nueva para GitHub"; then
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "r0@tecnointel.mx" -f "$HOME/.ssh/id_ed25519"
  if ! grep -q "Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
    cat >> "$HOME/.ssh/config" <<'EOF'
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  fi
  ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null
  pbcopy < "$HOME/.ssh/id_ed25519.pub"
  ok "Clave pública copiada al portapapeles"
  pendiente "Pegar la clave en GitHub → Settings → SSH and GPG keys, y probar: ssh -T git@github.com"
else
  pendiente "Configurar SSH para GitHub (MIGRAR_A_NUEVA_MAC_2027.md §8.1)"
fi

# =============================================================================
# 10. Memoria de Claude Code
# =============================================================================
titulo "10. Claude Code"

RESPALDO_CLAUDE="$PROYECTO/otros/claude_respaldo"
MEMORIA_T7="$HOME/.claude/projects/-Volumes-T7-Developer-arjipagos/memory"
if [[ -d "$MEMORIA_T7" ]]; then
  ok "La memoria del proyecto ya está en su sitio"
elif [[ -d "$RESPALDO_CLAUDE/memory_T7" ]]; then
  if ! $SOLO_COMPROBAR; then
    mkdir -p "$(dirname "$MEMORIA_T7")"
    cp -R "$RESPALDO_CLAUDE/memory_T7" "$MEMORIA_T7" && ok "Memoria restaurada"
    # La del enlace de ~/Developer se nombra con el usuario de ESTA Mac
    if [[ -d "$RESPALDO_CLAUDE/memory_Developer" ]]; then
      clave_dev="$(echo "$DEVELOPER/arjipagos" | tr '/' '-')"
      mkdir -p "$HOME/.claude/projects/$clave_dev"
      [[ -d "$HOME/.claude/projects/$clave_dev/memory" ]] \
        || cp -R "$RESPALDO_CLAUDE/memory_Developer" "$HOME/.claude/projects/$clave_dev/memory"
    fi
    if [[ -f "$RESPALDO_CLAUDE/settings.json" && ! -f "$HOME/.claude/settings.json" ]]; then
      cp "$RESPALDO_CLAUDE/settings.json" "$HOME/.claude/settings.json" && ok "settings.json restaurado"
    fi
  else
    aviso "Falta restaurar la memoria desde $RESPALDO_CLAUDE"
  fi
else
  pendiente "No hay respaldo en otros/claude_respaldo: hacerlo en la Mac vieja (plan §10)"
fi

# =============================================================================
# 11. Resumen
# =============================================================================
titulo "Resumen"

[[ -L "$DEVELOPER/arjipagos" ]] && grep -qF "$MARCA_ZSHRC" "$HOME/.zshrc" 2>/dev/null \
  && ok "Comando «arjipagos» listo: abre una terminal NUEVA y escríbelo"

if [[ ${#PENDIENTES[@]} -eq 0 ]]; then
  ok "No queda nada pendiente de este script"
else
  echo
  echo "  Queda por hacer a mano:"
  for p in "${PENDIENTES[@]}"; do echo "    - $p"; done
fi

cat <<'EOF'

  Siempre a mano, después de este script (MIGRAR_A_NUEVA_MAC_2027.md):
    - §3.4  Permisos de Terminal y Xcode: volúmenes extraíbles y Acceso total al disco
    - §8.2  Importar los .p12 de firma (Apple Distribution CF6C8Z3W44)
    - §8.3  Xcode → Settings → Accounts: iniciar sesión con el Apple ID
    - §9.3  arjipagos → flutter pub get → git status (pubspec.lock SIN cambios) → pod install
    - §11   La verificación completa, hasta subir a App Store Connect
EOF
