# Migrar a la nueva Mac (Apple silicon) — plan completo

> Escrito el 2026-11-19, con la MacBook Pro 15" de 2018 (Intel, `MacBookPro15,1`, macOS 15.8.3,
> Xcode 26.3) todavía en servicio. Inventario sacado de la máquina real, no de memoria.
>
> **Por qué hay que migrar:** desde **abril de 2027** App Store Connect solo acepta apps compiladas
> con el SDK de iOS 27 (Xcode 27), y Xcode 27 **solo corre en Apple silicon** con macOS Tahoe 26.6+.
> Esta Mac no admite Tahoe. Al subir la 1.0.35+44 Apple ya lo avisó: *«This app was built with the
> iOS 26.2 SDK. Starting April 2027…»*. Ver «Abril de 2027» en `CLAUDE.md`.
>
> **Regla de oro:** la Mac vieja **no se borra ni se vende** hasta que la nueva haya hecho un
> Archive **y** una subida a App Store Connect con éxito. Es el único respaldo que funciona seguro.

---

## ⭐ Lo primero que hay que hacer con la Mac nueva — en este orden

Antes de esto, la §2 tiene que estar hecha **en la Mac vieja** (exportar certificados, mover archives,
respaldar el T7 y la memoria de Claude Code). Si no, parar y hacerla primero.

1. **Encender y crear el usuario de macOS.** Es la cuenta que pide el asistente de configuración
   la primera vez —**no** el Apple ID ni la cuenta de desarrollador—. Nombre corto recomendado:
   `carlosmanuelhidalgoruiz` (ver §3.2). Cuando ofrezca el **Asistente de Migración, decir que no**
   (§3.1).
2. **Actualizar macOS** hasta la última Tahoe (26.6 o posterior).
3. **Instalar Xcode** desde el App Store y **abrirlo una vez** hasta que termine de instalar sus
   componentes.
4. **Dar permisos a Terminal:** Ajustes del Sistema → Privacidad y seguridad → **Acceso total al
   disco** → añadir Terminal. Sin esto, el paso siguiente puede no ver el T7.
5. **Conectar el SSD T7** y comprobar en el Finder que aparece como **T7** (no «T7 1»).
6. **Abrir Terminal y ejecutar el script** que hace todo lo mecánico:

   ```bash
   bash /Volumes/T7/Developer/arjipagos/scripts/preparar_nueva_mac.sh
   ```

   Va por pasos y **pregunta antes de cada cosa grande**. Instala Homebrew, CocoaPods, git-lfs,
   oh-my-zsh y la fuente del tema; configura git; crea los enlaces de `~/Developer`; escribe el
   `.zshrc` con la función `arjipagos` (guardando antes un respaldo del que hubiera); instala
   Flutter en la versión que le digas; baja la plataforma iOS de Xcode; genera la clave SSH y
   restaura la memoria de Claude Code. Al final imprime **lo que quedó pendiente a mano**.

   - Se puede ejecutar **varias veces**: lo que ya está hecho lo salta.
   - `--comprobar` solo informa, sin cambiar nada:
     `bash /Volumes/T7/Developer/arjipagos/scripts/preparar_nueva_mac.sh --comprobar`
   - Para no teclear la versión de Flutter:
     `FLUTTER_VERSION=3.50.0 bash /Volumes/T7/.../preparar_nueva_mac.sh` (la de la **Linux** ese día).
   - Se llama con `bash` delante porque el T7 es exFAT y no guarda el permiso de ejecución.
   - En una Mac Intel se niega a correr: no hace nada.

7. **Cerrar Terminal, abrir una nueva y escribir `arjipagos`.** Tiene que llevar al proyecto.
8. **Lo que el script no puede hacer por ti:** importar los `.p12` (§8.2), iniciar sesión en Xcode
   con el Apple ID (§8.3), pegar la clave SSH en GitHub (§8.1) y elegir la fuente en Terminal (§6.2).
9. **Abrir el proyecto** (§9.3) y pasar **la verificación completa** (§11).

Las secciones de abajo explican cada paso con detalle, por si el script falla en algo o se prefiere
hacerlo a mano.

---

## 0. Resumen en una página

| # | Fase | Dónde | Tiempo aprox. |
| --- | --- | --- | --- |
| 1 | Elegir la Mac | — | — |
| 2 | Preparar la Mac vieja (exportar firma, mover archives, respaldos) | Mac vieja | 1 h |
| 3 | Primer arranque de la nueva **sin** Asistente de Migración | Mac nueva | 30 min |
| 4 | Xcode 27 + componentes de iOS | Mac nueva | 1–2 h (descargas) |
| 5 | Homebrew, CocoaPods, git, git-lfs | Mac nueva | 30 min |
| 6 | Terminal: zsh, oh-my-zsh, el comando `arjipagos` | Mac nueva | 20 min |
| 7 | Flutter (misma versión que la Linux) | Mac nueva | 20 min |
| 8 | Claves: SSH, firma de Apple, cuenta en Xcode | Mac nueva | 30 min |
| 9 | Conectar el SSD T7 y abrir el proyecto | Mac nueva | 10 min |
| 10 | Claude Code y su memoria | Mac nueva | 15 min |
| 11 | Verificación completa: tests, build, iPhone, Archive, subida | Mac nueva | 2–3 h |
| 12 | Lo que cambia al compilar con el SDK 27 (iPhone Duo) | Mac nueva | aparte |
| 13 | Actualizar la documentación y retirar la Mac vieja | las dos | 30 min |

**Lo que NO hay que migrar** (y por qué) está en la §14. Léelo antes de copiar cosas «por si acaso».

---

## 1. Elegir la Mac

Requisitos duros, de los que depende poder publicar:

- **Apple silicon** (M1 o posterior). Cualquier Intel queda descartada: ni Xcode 27 ni, pronto,
  Flutter (desde la 3.47.7 `flutter doctor` avisa que dejará de soportar Macs Intel).
- **Que admita macOS Tahoe 26.6 o posterior**, que es lo que pide Xcode 27. Cualquier Mac con M1 o
  posterior lo admite hoy; aun así, mirar en la ficha de Apple que admite el macOS **vigente** el día
  de la compra, porque marca cuántos años más de Xcode tendrá.
- **Disco interno ≥ 512 GB**, recomendado 1 TB. No es capricho: Xcode ocupa ~40 GB, cada versión de
  iOS que se conecta deja ~6 GB en `iOS DeviceSupport`, el componente «iOS Universal Simulator» son
  ~10.5 GB y **no se puede borrar** (ver `CLAUDE.md`, «NO borrar los runtimes de simulador»), y
  `DerivedData` + la caché de SPM de Firebase suman varios GB más.
- **RAM ≥ 16 GB.** Xcode + el build de Flutter + Firebase por SPM con 8 GB se arrastra.
- **Puerto USB-C/Thunderbolt** para el T7 y para el iPhone (por cable va más rápido la primera
  copia de símbolos).

Lo que **no** importa: pantalla, Pro o Air. Para este proyecto una MacBook Air M-reciente con 16 GB y
1 TB es suficiente.

---

## 2. Preparar la Mac vieja — ANTES de encender la nueva

Todo esto se hace en la Mac Intel, con el T7 conectado.

### 2.1 Dejar el repo limpio y subido

```bash
arjipagos
git status            # debe salir limpio
git pull && git push  # que el remoto tenga todo
```

### 2.2 Mover los archives de Xcode al T7 (mover, no borrar)

Los `.xcarchive` llevan los **dSYM** con los que se simbolizan los crashes de las versiones
publicadas. Hoy hay ~539 MB en `~/Library/Developer/Xcode/Archives` (carpetas 2026-10-01,
2026-10-07, 2026-10-08, 2026-11-19), y dos más ya están en `otros/archives_ios/`.

```bash
mkdir -p /Volumes/T7/Developer/arjipagos/otros/archives_ios
cp -R ~/Library/Developer/Xcode/Archives/* /Volumes/T7/Developer/arjipagos/otros/archives_ios/
# Comprobar que llegaron completos antes de pensar en borrar nada:
du -sh ~/Library/Developer/Xcode/Archives /Volumes/T7/Developer/arjipagos/otros/archives_ios
```

`otros/` está en `.gitignore`: viaja con el disco y no con git. No borrar los originales hasta la §13.

### 2.3 Exportar los certificados de firma (.p12)

Hoy hay 5 identidades en el llavero. **Para ArjiPagos solo cuentan dos**:

| Identidad | Para qué |
| --- | --- |
| `Apple Distribution: Carlos Hidalgo (CF6C8Z3W44)` | **Imprescindible.** Firma los Archive que van a App Store. El `DEVELOPMENT_TEAM` del proyecto es `CF6C8Z3W44` |
| `Apple Development: Carlos Hidalgo (KXUMZRM94T)` | Correr en el iPhone con el botón Run |

Las otras tres (`Carlos Manuel Hidalgo Ruiz`, `apps@centro.gob.mx` y la del H. Ayuntamiento de
Centro) son de otros proyectos; exportarlas igual si se van a seguir usando en la Mac nueva.

Cómo exportar cada una:

1. Abrir **Acceso a Llaveros** → llavero **inicio de sesión** → categoría **Mis certificados**.
2. Desplegar el certificado (triángulo) y comprobar que **lleva su clave privada** debajo. Sin clave
   privada el `.p12` no sirve.
3. Clic derecho → **Exportar…** → formato **.p12** → ponerle contraseña **fuerte**.
4. Guardar los `.p12` en `otros/firma_apple/` del T7 (no viajan por git) **y** apuntar la contraseña
   en el gestor de contraseñas, **nunca** en un archivo junto al `.p12`.

> Alternativa sin `.p12`: con firma automática, Xcode puede crear certificados nuevos en la Mac
> nueva. Funciona, pero Apple limita los certificados de Distribución por cuenta y quedan dos
> activos a la vez. Exportar es más limpio.

### 2.4 Comprobar que los secretos del proyecto están en el T7

No viajan por git (están en `.gitignore`), pero **sí viajan con el disco**, porque viven dentro del
proyecto. Comprobar que existen antes de desconectar:

```bash
cd /Volumes/T7/Developer/arjipagos
ls -la ios/Runner/GoogleService-Info.plist          # Firebase iOS — imprescindible para push
ls -la android/app/google-services.json             # Firebase Android (lo usa la Linux)
ls -la android/key.properties android/app/firma/    # firma de Play (lo usa la Linux)
ls -la otros/AuthKey_*.p8                           # clave APNs / App Store Connect API
```

**Hacer una segunda copia** de esos archivos en otro sitio que no sea el T7 (gestor de contraseñas
con adjuntos, o un disco aparte cifrado). Si el T7 se pierde o se corrompe, la clave de subida de
Play (`arjipagos_key.jks`) **no se puede recuperar** y obliga a un trámite con Google.

### 2.5 Respaldo completo del T7

El T7 es **exFAT** y es el único sitio donde vive el proyecto con sus secretos. Antes de conectarlo
a otra máquina con otro macOS:

```bash
# Con otro disco conectado (ej. /Volumes/RESPALDO):
rsync -a --progress /Volumes/T7/Developer/ /Volumes/RESPALDO/T7_Developer_$(date +%F)/
```

### 2.6 Anotar lo que la Mac vieja tiene y la nueva necesitará

Ya está inventariado aquí abajo, pero si pasa tiempo entre este documento y la compra, volver a
sacarlo:

```bash
brew leaves; brew list --cask       # paquetes
gem list cocoapods                  # versión de CocoaPods
flutter --version                   # versión de Flutter
xcodebuild -version
git config --global --list
ls ~/.ssh
```

Inventario del 2026-11-19:

| Qué | Valor en la Mac vieja | En la nueva |
| --- | --- | --- |
| macOS | 15.8.3 Sequoia | Tahoe 26.6+ |
| Xcode | 26.3 (17C529) | **27.x** (el más reciente estable) |
| Flutter | 3.50.0, en `~/develop/flutter` | La misma que tenga la Linux ese día |
| CocoaPods | 1.16.2 (`/usr/local/bin/pod`, de Homebrew) | El de Homebrew, actual |
| Ruby | el del sistema, 2.6.10 | No se usa directamente; CocoaPods trae el suyo con Homebrew |
| Homebrew | `/usr/local` (Intel) | `/opt/homebrew` (Apple silicon) |
| Paquetes brew | `cocoapods`, `zsh-autosuggestions`, `zsh-syntax-highlighting` (+ `autoconf`, `httpd`, `libiconv`, `openldap`, `python@3.8`, `python@3.15` de otros proyectos) | Solo los tres primeros + `git-lfs` |
| Cask | `android-studio` | **No** (Android se compila en la Linux) |
| MacPorts | instalado y **roto** («OS platform mismatch») | **No** instalarlo |
| Shell | zsh + oh-my-zsh (tema `agnoster`) + iTerm2 shell integration | Igual |
| git | `user.name=DevCH50`, `user.email=r0@tecnointel.mx`, git-lfs | Igual |
| SSH | `~/.ssh/id_ed25519` + `config` (GitHub) | Clave **nueva** (ver §8.1) |
| iPhone de pruebas | iPhone 17 Pro Max (`iPhone18,2`), iOS 27.2.1 | El mismo |

---

## 3. Primer arranque de la Mac nueva

### 3.1 NO usar el Asistente de Migración para las herramientas

El Asistente de Migración copiaría el Homebrew de Intel (`/usr/local`), CocoaPods de x86_64, el
MacPorts roto y las rutas de Android, y correrían **bajo Rosetta**. Es la receta para errores raros
de arquitectura (`arm64` vs `x86_64`) al compilar pods o plugins nativos. Todo lo de desarrollo se
instala **limpio**.

Si se quiere el Asistente para documentos, fotos o el correo, usarlo desmarcando **Aplicaciones** y
**Otros archivos y carpetas**, y nunca para la carpeta de usuario completa.

### 3.2 Crear el usuario de macOS

Es la **cuenta de usuario de macOS** que el asistente de configuración pide crear al encender la
Mac por primera vez. **No** es el Apple ID ni la cuenta de desarrollador de Apple. Pide dos nombres:

| Campo | Qué es | En la Mac Intel |
| --- | --- | --- |
| **Nombre completo** | El que se ve en la pantalla de inicio | Libre |
| **Nombre de la cuenta** (nombre corto) | El de la carpeta personal: `/Users/<nombre>` | `carlosmanuelhidalgoruiz` |

- **Recomendado:** usar el mismo nombre corto, `carlosmanuelhidalgoruiz`, para que la carpeta
  personal vuelva a ser `/Users/carlosmanuelhidalgoruiz`. Así siguen valiendo las rutas que salen en
  notas y documentos, y la memoria de Claude Code ligada a `~/Developer/arjipagos` (que se nombra
  con esa ruta, §10).
- **Revisarlo antes de continuar:** el asistente **propone el nombre corto él solo** a partir del
  nombre completo, y puede salir otro (por ejemplo `carloshidalgo`). Cambiarlo después de crear la
  cuenta es engorroso.
- Si se elige otro nombre, no pasa nada grave: el `.zshrc` de la §6 y el script usan `$HOME`, así
  que `arjipagos` funciona igual. Solo cambian esas rutas.

### 3.3 Actualizar macOS

**Ajustes del Sistema → General → Actualización de software** hasta la última versión de Tahoe
(26.6 o superior: es el mínimo de Xcode 27).

### 3.4 Ajustes del sistema que importan aquí

- **Privacidad y seguridad → Archivos y carpetas / Discos extraíbles:** permitir a **Terminal**
  (o iTerm2) y a **Xcode** el acceso a **volúmenes extraíbles**. Sin esto, macOS pregunta cada vez,
  o deja `/Volumes/T7` invisible para el proceso y el `cd` falla con *Operation not permitted*.
- **Privacidad y seguridad → Acceso total al disco:** añadir Terminal (o iTerm2). Evita cuelgues
  silenciosos con `xattr` y Spotlight sobre el T7.
- **Energía:** que no duerma los discos durante un Archive largo.

---

## 4. Xcode 27 y los componentes de iOS

1. Instalar **Xcode** desde el App Store (o desde developer.apple.com → Downloads si se necesita una
   versión concreta). Abrirlo una vez para que instale los componentes adicionales.
2. Aceptar la licencia y fijar las herramientas de línea de comandos:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   xcodebuild -runFirstLaunch
   ```

3. **Instalar la plataforma iOS.** En Xcode 26+ el soporte de dispositivo y el simulador son **un
   solo componente**: sin él no se compila ni para el iPhone físico.

   ```bash
   xcodebuild -downloadPlatform iOS
   ```

   Son ~10 GB. **No borrarlo nunca** aunque no se usen simuladores (ver `CLAUDE.md`).

4. Comprobar:

   ```bash
   xcodebuild -version
   xcodebuild -showsdks | grep iphoneos      # debe salir iOS 27.x
   ```

**Rosetta:** no hace falta para este proyecto. Si algún paso pide instalarla, es señal de que algo
se instaló para Intel por error: parar y revisar antes de aceptar.

---

## 5. Homebrew, CocoaPods, git y git-lfs

```bash
# Homebrew (en Apple silicon vive en /opt/homebrew)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Lo que usa el proyecto y la terminal
brew install cocoapods git-lfs zsh-autosuggestions zsh-syntax-highlighting
git lfs install

# Comprobar arquitectura: TODO debe decir arm64
file "$(which pod)" "$(brew --prefix)/bin/git-lfs"
pod --version
```

**git global** (lo mismo que hoy):

```bash
git config --global user.name  "DevCH50"
git config --global user.email "r0@tecnointel.mx"
git config --global color.ui true
git config --global push.default simple
```

Lo que **no** se instala: MacPorts, `httpd`, `openldap`, `python@3.8`, `autoconf`, `libiconv` (son de
otros proyectos o restos), ni Android Studio (Android se hace en la Linux; ver `CLAUDE.md`, «Dos
máquinas»). Si otro proyecto los necesita, se instalan cuando toque.

---

## 6. La terminal y el comando `arjipagos`

### 6.1 Cómo funciona hoy (para reproducirlo igual)

No hay ningún alias ni script llamado `arjipagos`. Son tres piezas juntas:

1. El `.zshrc` termina en un `cd ~/Developer`, así que **cada terminal nueva arranca en
   `~/Developer`**.
2. En `~/Developer` hay **enlaces simbólicos** al SSD:

   ```
   ~/Developer/arjipagos   -> /Volumes/T7/Developer/arjipagos
   ~/Developer/sismmun     -> /Volumes/T7/Developer/sismmun
   ~/Developer/SIACiOS.zip -> /Volumes/T7/Developer/SIACiOS.zip
   ```

3. oh-my-zsh activa la opción **`AUTO_CD`**: escribir el nombre de una carpeta, sin `cd`, entra en
   ella. Por eso `arjipagos` a secas te deja en el proyecto del T7.

Funciona **solo desde `~/Developer`**. En la Mac nueva se hace igual y además se añade una función
para que `arjipagos` funcione **desde cualquier carpeta** (§6.4).

### 6.2 oh-my-zsh y tema

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

El tema `agnoster` necesita una fuente con símbolos *powerline* para no mostrar cuadritos:

```bash
brew install --cask font-meslo-lg-nerd-font
```

Y en Terminal (o iTerm2) → Ajustes → Perfil → Texto → elegir **MesloLGS Nerd Font**.

**iTerm2** (opcional; hoy está su *shell integration*): instalar con `brew install --cask iterm2` y,
dentro de iTerm2, menú **iTerm2 → Install Shell Integration**, que vuelve a crear
`~/.iterm2_shell_integration.zsh`.

### 6.3 Los enlaces de `~/Developer`

Con el T7 **conectado** (§9):

```bash
mkdir -p ~/Developer
ln -s /Volumes/T7/Developer/arjipagos   ~/Developer/arjipagos
ln -s /Volumes/T7/Developer/sismmun     ~/Developer/sismmun
ln -s /Volumes/T7/Developer/SIACiOS.zip ~/Developer/SIACiOS.zip
ls -la ~/Developer
```

### 6.4 El `.zshrc`

Reemplazar el `~/.zshrc` que deja oh-my-zsh por este. Es el de hoy **sin** lo que ya no aplica
(MacPorts, Android, Antigravity, la ruta fija con el nombre de usuario) y **con** la función
`arjipagos`:

```zsh
# ── oh-my-zsh ───────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git vscode python laravel composer postgres jsontools)
source $ZSH/oh-my-zsh.sh

# ── Integración de iTerm2 (si se usa) ───────────────────────────────────────
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# ── PATH ────────────────────────────────────────────────────────────────────
export PATH="$HOME/develop/flutter/bin:$HOME/.local/bin:$PATH"

# ── Complementos de Homebrew ────────────────────────────────────────────────
source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ── Proyectos ───────────────────────────────────────────────────────────────
# AUTO_CD ya lo activa oh-my-zsh: desde ~/Developer, escribir «arjipagos» entra.
# La función hace que funcione desde cualquier carpeta y avisa si el SSD no está.
arjipagos() {
  if [[ ! -d /Volumes/T7/Developer/arjipagos ]]; then
    echo "El SSD T7 no está montado. Conéctalo y vuelve a intentarlo."
    return 1
  fi
  cd ~/Developer/arjipagos
}

# Cada terminal nueva arranca en ~/Developer, como en la Mac vieja.
cd ~/Developer
PROMPT='%1~ %# '
```

> `PROMPT='%1~ %# '` al final **pisa** el prompt de `agnoster`; así está hoy. Si se quiere el
> prompt de colores del tema, quitar esa línea.

Recargar y probar:

```bash
source ~/.zshrc
arjipagos && pwd     # → /Users/<usuario>/Developer/arjipagos
pwd -P               # → /Volumes/T7/Developer/arjipagos
```

**Abrir una terminal nueva** y escribir `arjipagos`: tiene que llevar al proyecto igual que hoy.

---

## 7. Flutter

**La versión de Flutter de la Mac tiene que ser la MISMA que la de la Linux.** El `pubspec.lock`
fija paquetes que dependen del SDK (con la 3.50, `test_api` 0.7.14), y un `flutter pub get` con otra
versión lo reescribe. Ver «Y Flutter también se va de Intel» en `CLAUDE.md`.

```bash
# En la Linux, antes:  flutter --version   → anotar la versión (ej. 3.50.0)
mkdir -p ~/develop
git clone https://github.com/flutter/flutter.git -b stable ~/develop/flutter
cd ~/develop/flutter && git checkout <versión-de-la-linux>   # ej. 3.50.0
flutter --version
flutter precache --ios
flutter doctor -v
```

En `flutter doctor` es **normal y esperado** que salgan en rojo o amarillo:

- **Android toolchain / Android Studio:** en la Mac no se compila Android. Ignorar.
- **Chrome:** no se usa web. Ignorar.

Tiene que salir en verde: **Flutter**, **Xcode** y **CocoaPods**. Y ya **no** debe salir el aviso
*«Flutter is deprecating support for Intel-based Macs»*: si sale, es que algo corre bajo Rosetta.

---

## 8. Claves y cuentas

### 8.1 SSH para GitHub — clave nueva

Mejor generar una nueva que copiar la privada de la Mac vieja:

```bash
ssh-keygen -t ed25519 -C "r0@tecnointel.mx"     # con passphrase
eval "$(ssh-agent -s)"
cat >> ~/.ssh/config <<'EOF'
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
```

GitHub → Settings → **SSH and GPG keys** → New SSH key → pegar. Ponerle de título la Mac nueva.

```bash
ssh -T git@github.com     # → "Hi DevCH50! You've successfully authenticated…"
```

La clave de la Mac vieja se **revoca en GitHub** en la §13, no antes.

> Antes de generar, mirar el `~/.ssh/config` de la Mac vieja: si tiene más `Host` (otros servidores,
> el backend), hay que replicarlos y dar de alta la clave nueva en cada uno.

### 8.2 Certificados de firma

Doble clic en cada `.p12` de `otros/firma_apple/` (§2.3) → llavero **inicio de sesión** → escribir
su contraseña. Comprobar:

```bash
security find-identity -v -p codesigning
# Debe aparecer al menos:
#   "Apple Distribution: Carlos Hidalgo (CF6C8Z3W44)"
#   "Apple Development: Carlos Hidalgo (KXUMZRM94T)"
```

Después, **borrar los `.p12` del T7** o moverlos a un sitio cifrado: ya están en el llavero y en el
gestor de contraseñas.

### 8.3 Cuenta de Apple en Xcode

**Xcode → Settings → Accounts → +** → Apple ID de la cuenta de desarrollador. Seleccionar el equipo
`CF6C8Z3W44` → **Download Manual Profiles**. Con firma automática (`CODE_SIGN_STYLE = Automatic`)
Xcode baja o regenera los perfiles solo; no hace falta copiar `~/Library/MobileDevice/Provisioning
Profiles`.

> Si al subir sale *«You do not have required contracts…»*, no es la Mac: es un acuerdo sin aceptar
> en developer.apple.com o en App Store Connect → Business, y solo lo puede aceptar el Account
> Holder. Pasó el 2026-11-19.

### 8.4 Bundle ID: NO tocar

iOS se publica como **`com.example.arjipagos`** (App Store, desde la 1.0.20). Que en Android sea
`mx.moriah.arjipagos` es deliberado. **Xcode puede sugerir cambiarlo en la Mac nueva: no hacerlo.**

---

## 9. Conectar el SSD T7 y abrir el proyecto

### 9.1 Montarlo

Conectar el T7. Debe aparecer como **`/Volumes/T7`**, exactamente con ese nombre: de él dependen los
enlaces de `~/Developer`, el `storeFile` de `android/key.properties` y la memoria de Claude Code
(§10). Si macOS lo monta como `T7 1` (pasa cuando hay otro volumen con el mismo nombre), expulsar el
otro y volver a montar.

```bash
ls /Volumes/T7/Developer
diskutil info /Volumes/T7 | grep -E "Personality|Volume Name"   # → ExFAT, T7
```

### 9.2 exFAT: lo que hay que saber

El T7 es **exFAT**. En macOS recientes ese formato pasa por **FSKit**, y en esta Mac ya se vio que
leer los atributos extendidos (`xattr`) de `Runner.xcodeproj`/`Runner.xcworkspace` puede quedarse
**colgado**, y Xcode o `xcodebuild` parecen congelados sin dar error. Antes de culpar a Xcode:

```bash
cd /Volumes/T7/Developer/arjipagos/ios
time xattr -l Runner.xcodeproj Runner.xcworkspace   # debe volver al instante
```

Si se cuelga: expulsar y volver a montar el T7; si persiste, `dot_clean -m /Volumes/T7/Developer/arjipagos`.

**Decisión pendiente, NO para el día de la migración:** pasar el T7 a **APFS** quitaría este
problema y daría mejor rendimiento en builds, pero:

- borra el disco (habría que restaurar desde el respaldo de la §2.5), y
- **la Linux no lee APFS**: si el T7 se conecta alguna vez a la Linux, debe seguir en exFAT.

Lo decide Carlos, con calma y con respaldo verificado. Hasta entonces, exFAT.

### 9.3 Primera apertura

```bash
arjipagos
git status                 # limpio
git pull                   # al día con la Linux
flutter clean
flutter pub get
git status                 # ⚠️ pubspec.lock NO debe cambiar; si cambia, la versión de Flutter no coincide (§7)
cd ios && pod install && cd ..
open ios/Runner.xcworkspace   # el .xcworkspace, NUNCA el .xcodeproj
```

En `pod install` deben salir las líneas del `post_install` del Podfile:

```
✔ LastUpgradeCheck se queda en 2700 (project.pbxproj)
✔ Run Script 'Generate dSYM for objective_c native asset' configurado en Runner
```

Y comprobar que `ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift`
quedó en `.iOS("15.0")`.

---

## 10. Claude Code y su memoria

Claude Code guarda en `~/.claude/` la configuración y, por proyecto, la **memoria** (lo aprendido
sobre ArjiPagos: el bundle `com.example`, las dos máquinas, la Mac Intel…). La carpeta de cada
proyecto se nombra **por la ruta** del proyecto: la del T7 es
`~/.claude/projects/-Volumes-T7-Developer-arjipagos/`. Como el T7 se monta en la misma ruta, **la
memoria vuelve a encajar sola** si se copia.

En la Mac vieja:

```bash
mkdir -p /Volumes/T7/Developer/arjipagos/otros/claude_respaldo
cp -R ~/.claude/projects/-Volumes-T7-Developer-arjipagos/memory \
      /Volumes/T7/Developer/arjipagos/otros/claude_respaldo/memory_T7
cp -R ~/.claude/projects/-Users-carlosmanuelhidalgoruiz-Developer-arjipagos/memory \
      /Volumes/T7/Developer/arjipagos/otros/claude_respaldo/memory_Developer 2>/dev/null
cp ~/.claude/settings.json /Volumes/T7/Developer/arjipagos/otros/claude_respaldo/
cp -R ~/.claude/skills     /Volumes/T7/Developer/arjipagos/otros/claude_respaldo/ 2>/dev/null
```

En la Mac nueva, tras instalar Claude Code e iniciar sesión **una vez**:

```bash
mkdir -p ~/.claude/projects/-Volumes-T7-Developer-arjipagos
cp -R /Volumes/T7/Developer/arjipagos/otros/claude_respaldo/memory_T7 \
      ~/.claude/projects/-Volumes-T7-Developer-arjipagos/memory
cp /Volumes/T7/Developer/arjipagos/otros/claude_respaldo/settings.json ~/.claude/
cp -R /Volumes/T7/Developer/arjipagos/otros/claude_respaldo/skills ~/.claude/ 2>/dev/null
```

Si en la Mac nueva el usuario **no** se llama `carlosmanuelhidalgoruiz`, la memoria de
`~/Developer/arjipagos` cambia de nombre de carpeta (`-Users-<nuevo>-Developer-arjipagos`): copiar
`memory_Developer` a esa ruta.

Lo que **no** se copia: `history.jsonl`, `sessions`, `shell-snapshots`, `cache`, `file-history`,
`paste-cache`, `session-env`. Son de sesiones pasadas y referencian rutas de la Mac vieja.

`.claude/settings.local.json` dentro del proyecto viaja con el T7; no hay que hacer nada.

**Actualizar la memoria** en cuanto la Mac nueva esté en servicio: la nota «Mac Intel sin Xcode 27»
deja de ser cierta (§13).

---

## 11. Verificación — la Mac nueva no está lista hasta que pase TODO esto

Por orden. Si un paso falla, no seguir al siguiente.

| # | Prueba | Cómo | Debe dar |
| --- | --- | --- | --- |
| 1 | Terminal | Abrir terminal nueva → `arjipagos` | Entra en el proyecto; `pwd -P` = `/Volumes/T7/Developer/arjipagos` |
| 2 | Arquitectura | `uname -m`; `file "$(which pod)"` | `arm64` en los dos |
| 3 | Flutter | `flutter --version` | La misma que la Linux |
| 4 | Lock | `flutter pub get && git status` | `pubspec.lock` sin cambios |
| 5 | Análisis | `flutter analyze` | Sin errores ni avisos (los `info` de `material.dart` son conocidos) |
| 6 | Tests | `flutter test` | Todos en verde (1211 el 2026-11-19) |
| 7 | Config crítica | `ApiConfig.isProduction = true`, `kTemporadaForzada = null`, `LastUpgradeCheck`, esquema Launch/Archive en `Release` | Como en `CLAUDE.md` |
| 8 | Build | `./scripts/build_ios.sh` | `✓ Built build/ios/iphoneos/Runner.app` |
| 9 | iPhone | Conectar el iPhone 17 por cable → confiar → **Modo desarrollador** activado | Xcode lo ve. La primera vez copia símbolos (~6 GB): en Apple silicon tarda bastante menos que la hora de la Intel, pero **no desconectar** |
| 10 | Run | Botón Run en Xcode | La app arranca. En la consola **no** sale ninguna línea `flutter:` |
| 11 | Recorrido | Login, Pagos Pendientes, Otros pagos, Pagos Realizados, Facturas, Notificaciones, Configuraciones | Todo carga, claro y oscuro |
| 12 | Nativo | Abrir un ticket PDF (share sheet), webview del pago (sin pagar), Face ID desde Configuraciones, un push con la app abierta y minimizada | Funcionan como en la tabla de `CLAUDE.md` |
| 13 | Archive | Product → Archive | Se crea; aviso `empty dSYM` de `objective_c` es normal |
| 14 | Subida | Organizer → Distribute App → App Store Connect | «Upload Successful». **Ya sin el aviso del SDK 26.2** |
| 15 | TestFlight | App Store Connect → TestFlight | La build aparece y se instala en el iPhone |

Solo cuando el **14** salga bien se pasa a la §13.

---

## 12. Lo que cambia al compilar con el SDK de iOS 27 — NO es parte de la migración

Mover el proyecto a la Mac nueva **no debe cambiar el comportamiento de la app**. Pero compilar con
el SDK 27 sí cambia cosas, y conviene saberlas para no confundir «se rompió con la Mac» con «cambió
con el SDK»:

- **iPhone Duo.** Con el SDK **27.1** o posterior la app deja el modo compatibilidad y ocupa la
  pantalla interior entera (~669 × 951 pt, casi cuadrada), redimensionándose al plegar. El test
  `test/widgets/iphone_duo/pantallas_iphone_duo_test.dart` ya cubre los desbordes, pero **no** cómo
  se ve. `Info.plist` declara solo vertical y `UIRequiresFullScreen = true`: **no tocarlo** hasta ver
  la app en el Duo o su simulador. Ver «El iPhone Duo» en `CLAUDE.md`.
- **Capturas del iPhone Duo** (1398 × 2034 y 2007 × 2853 px) obligatorias para App Store Connect con
  el SDK 27.1. Se sacan del simulador del Duo: **la Mac nueva sí puede usar simuladores**.
- **Simuladores.** La decisión de no usarlos era por espacio y por la Intel. En la Mac nueva, para el
  Duo, hace falta el simulador. El esquema sigue con `LaunchAction = Release` y
  `SUPPORTED_PLATFORMS = iphoneos` en Release/Profile: para el simulador usar `flutter run -d <id>`
  (fuerza Debug) o cambiar la `LaunchAction` a Debug **sin commitearlo**, como dice `CLAUDE.md`.
- **«Update to recommended settings».** Xcode 27 lo volverá a ofrecer: **rechazarlo**. Si sube
  `LastUpgradeCheck` por encima de 2700, se respeta (el Podfile solo pone un suelo).
- **Al estrenar Xcode 27, tocar solo** `LAST_UPGRADE_MINIMO` en `ios/Podfile` y `TARGET_VERSION` en
  `scripts/build_ios.sh` (hoy los dos en `2700`), y solo si se decide subir el suelo.
- **Ruido nuevo en la consola.** Un SDK nuevo trae mensajes nuevos. Antes de darlos por ruido,
  `grep -rI` en `lib/`, `ios/Runner/` y `ios/Pods/`, como dice la tabla de `CLAUDE.md`.

Esto es una tarea aparte, con su propia prueba en el iPhone y el Duo, y **nunca dentro del release
de la migración**.

---

## 13. Cerrar la migración

Solo después de la verificación 14 de la §11.

### 13.1 Documentación del proyecto

- `CLAUDE.md`, sección «Abril de 2027»: cambiar «ESTA Mac ya no podrá publicar» por el modelo nuevo,
  Xcode 27.x y macOS. Quitar o marcar como histórico lo de la Intel (Xcode 26.3, la hora de copia de
  símbolos, «la Mac está en macOS 15.8.1»).
- `CLAUDE.md`, «Dos máquinas»: anotar el modelo de la Mac nueva.
- `CLAUDE.md`, «Flujo de ejecución: solo dispositivo físico»: añadir que el simulador del Duo sí se
  usa.
- `ARJIPAGOS_PROGRESS.md`: la entrada de la migración, con versiones y resultado de la §11.
- Este documento: marcar al principio **«Migración completada el AAAA-MM-DD»**.

### 13.2 Memoria de Claude Code

Pedirle a Claude Code en la Mac nueva que actualice las memorias `mac-intel-sin-xcode-27` y
`builds-mac-ios-linux-android` con la máquina nueva.

### 13.3 Retirar la Mac vieja

1. **Revocar** su clave SSH en GitHub (Settings → SSH keys).
2. **Xcode → Settings → Accounts:** quitar la cuenta de Apple.
3. Comprobar una última vez que los archives están en `otros/archives_ios/` del T7 (§2.2).
4. Si se van a quitar sus certificados de firma: **no revocarlos en developer.apple.com** si se
   importaron los mismos `.p12` en la nueva, porque se invalidarían también allí.
5. Cerrar sesión en Apple ID / iCloud (**Ajustes → Apple ID → Cerrar sesión**) y desactivar
   **Buscar mi Mac**.
6. Solo entonces, borrado: **Ajustes del Sistema → General → Transferir o restablecer → Borrar
   contenidos y ajustes**.

---

## 14. Lo que NO se migra (y por qué)

| Qué | Por qué no |
| --- | --- |
| Homebrew de `/usr/local` y todo lo instalado ahí | Es de Intel. Se reinstala en `/opt/homebrew` |
| MacPorts (`/opt/local`) | Ya está roto en la Mac vieja («OS platform mismatch») |
| Android Studio, SDK de Android, `JAVA_HOME` | Android se compila en la Linux |
| Antigravity (`~/.antigravity`) | No es del proyecto. Instalar aparte si se usa |
| `~/Library/Developer/Xcode/DerivedData` | Se regenera |
| `~/Library/Developer/Xcode/iOS DeviceSupport` | Es de Xcode 26.3 y del iPhone a esa versión; Xcode 27 lo vuelve a generar al conectar |
| `~/Library/Caches/org.swift.swiftpm` | Se regenera (el primer build reclona Firebase: tarda) |
| Perfiles de aprovisionamiento | Con firma automática Xcode los regenera |
| `build/` del proyecto | Se regenera y el `flutter clean` lo borra |
| Historial y sesiones de Claude Code | Rutas y contexto de la Mac vieja |
| La clave SSH privada vieja | Se genera una nueva (§8.1) |
| `python@3.8`, `httpd`, `openldap`, `autoconf`, `libiconv` | De otros proyectos o restos; instalar si alguno los pide |

---

## 15. Si algo sale mal

| Síntoma | Causa probable | Qué hacer |
| --- | --- | --- |
| `arjipagos: command not found` / `no such file or directory` | El T7 no está montado, o no existen los enlaces de `~/Developer` | `ls /Volumes/T7`; repetir §6.3 |
| `cd: operation not permitted` en `/Volumes/T7` | Terminal sin permiso de volúmenes extraíbles | §3.4 |
| `pubspec.lock` cambia tras `pub get` | Flutter distinto del de la Linux | `cd ~/develop/flutter && git checkout <versión>` y repetir |
| `pod install` habla de `x86_64` o `ffi` | CocoaPods o Ruby bajo Rosetta | `brew reinstall cocoapods` desde una terminal sin Rosetta (`arch` debe decir `arm64`) |
| Error de Firebase de *minimum platform version 15.0* | `Package.swift` regenerado en 13.0 | `cd ios && pod install`; ver `CLAUDE.md` |
| *No Xcode build settings have been found* | Falta el componente de plataforma iOS | `xcodebuild -downloadPlatform iOS` (§4) |
| Xcode o `xcodebuild` se quedan congelados sin error | `xattr` del T7 colgado por FSKit | §9.2 |
| *No signing certificate "iOS Distribution" found* | No se importó el `.p12` de Distribución | §8.2 |
| *You do not have required contracts* | Acuerdo de Apple sin aceptar | §8.3 |
| La app no recibe push | Falta `GoogleService-Info.plist` | §2.4; viene del T7, no de git |
| Xcode propone cambiar el bundle ID | Sugerencia de Xcode | **No aceptar** (§8.4) |
