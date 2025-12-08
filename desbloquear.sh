#!/bin/bash
set -euo pipefail

# GUI assistant to flash the BIOS for Ceibal / Positivo BGH (11CLE2Plus).
# Pensado para doble clic: todo se hace con ventanas (zenity).

KERNEL_VERSION="3.19.0-33-generic"
GRUB_ENTRY="Opciones avanzadas para Ubuntu>Ubuntu, con Linux $KERNEL_VERSION"

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
AFULNX_PATH="$SCRIPT_DIR/afulnx_64"
AFUWIN_ROM_PATH="$SCRIPT_DIR/afuwin.rom"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/update_bios.desktop"
LOG_FILE="$SCRIPT_DIR/desbloquear.log"
DRY_RUN=0
SUDO_PASS=""

info()   { zenity --info --width=420 --title="Desbloqueo BIOS" --text="$*"; }
error()  { zenity --error --width=420 --title="Desbloqueo BIOS" --text="$*"; exit 1; }
warnbox(){ zenity --warning --width=420 --title="Desbloqueo BIOS" --text="$*"; }
ask()    { zenity --question --width=420 --title="Desbloqueo BIOS" --text="$*"; }

ensure_zenity() {
    if command -v zenity >/dev/null 2>&1; then
        return
    fi

    mapfile -t pkgs < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name "zenity*.deb" | sort)
    if [[ "${#pkgs[@]}" -eq 0 ]]; then
        echo "Falta 'zenity' y no se encontro ningun zenity*.deb junto al script."
        echo "Copia los .deb de zenity (incluido zenity-common si aplica) a esta carpeta y vuelve a ejecutar."
        exit 1
    fi

    echo "Instalando zenity desde paquetes locales (se solicitara contraseña de administrador si es necesario):"
    printf ' - %s\n' "${pkgs[@]}"

    if command -v pkexec >/dev/null 2>&1; then
        pkexec env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" dpkg -i "${pkgs[@]}" || {
            echo "No se pudo instalar zenity con pkexec."
            echo "Instala manualmente con: sudo dpkg -i ${pkgs[*]##*/}"
            exit 1
        }
    else
        sudo dpkg -i "${pkgs[@]}" || {
            echo "No se pudo instalar zenity."
            echo "Instala manualmente con: sudo dpkg -i ${pkgs[*]##*/}"
            exit 1
        }
    fi

    command -v zenity >/dev/null 2>&1 || {
        echo "La instalacion de zenity no se completo correctamente."
        exit 1
    }
}

simulate_kernel_install() {
    (
        echo "10"
        echo "# Modo prueba: simulando instalacion de kernel..."
        sleep 1
        echo "40"
        echo "# Modo prueba: simulando configuracion de GRUB..."
        sleep 1
        echo "70"
        echo "# Modo prueba: simulando autostart..."
        sleep 1
        echo "100"
        echo "# Simulacion completada (no se reiniciara)"
    ) | zenity --progress --title="Simulacion kernel (sin cambios)" --percentage=0 --auto-close --no-cancel --width=420
}

check_tools() {
    for tool in sudo grub-reboot dpkg; do
        command -v "$tool" >/dev/null 2>&1 || error "No se encontro $tool. Instala/activa la herramienta y vuelve a intentar."
    done
}

check_files() {
    local missing=0
    for f in "$AFULNX_PATH" "$AFUWIN_ROM_PATH"; do
        [[ -f "$f" ]] || { missing=1; warnbox "Falta el archivo requerido: $f"; }
    done
    for pkg in "$SCRIPT_DIR"/linux-headers-3.19*.deb "$SCRIPT_DIR"/linux-image-3.19*.deb; do
        [[ -f "$pkg" ]] || { missing=1; warnbox "Falta el paquete de kernel: $pkg"; }
    done
    [[ "$missing" -eq 0 ]] || error "Coloca todos los archivos en la misma carpeta que el script y vuelve a intentar."
}

request_password() {
    local validated=1
    while [[ "$validated" -ne 0 ]]; do
        SUDO_PASS="$(zenity --password --width=420 --title="Desbloqueo BIOS" --text="Ingresa la contraseña de administrador\n(la misma que usas con sudo).")" || exit 1
        if echo "$SUDO_PASS" | sudo -S -v >/dev/null 2>&1; then
            validated=0
        else
            warnbox "Contraseña incorrecta. Intenta de nuevo."
        fi
    done
}

run_sudo() {
    echo "$SUDO_PASS" | sudo -S "$@" >>"$LOG_FILE" 2>&1
}

create_autostart() {
    mkdir -p "$AUTOSTART_DIR"
    cat <<EOF > "$AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Exec=/bin/bash -lc '"$SCRIPT_PATH"'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Update BIOS
Comment=Reanuda el script de BIOS despues del reinicio
EOF
}

remove_autostart() {
    [[ -f "$AUTOSTART_FILE" ]] && rm -f "$AUTOSTART_FILE"
}

install_kernel_and_reboot() {
    (
        echo "5"
        echo "# Instalando kernel $KERNEL_VERSION..."
        run_sudo dpkg -i "$SCRIPT_DIR"/linux-headers-3.19*.deb "$SCRIPT_DIR"/linux-image-3.19*.deb

        echo "60"
        echo "# Configurando arranque unico en GRUB..."
        run_sudo grub-reboot "$GRUB_ENTRY"

        echo "80"
        echo "# Creando autostart para continuar tras el reinicio..."
        create_autostart

        echo "100"
        echo "# Reiniciando..."
    ) | zenity --progress --title="Preparando kernel" --percentage=0 --auto-close --no-cancel --width=420

    info "El equipo se reiniciara ahora para arrancar con el kernel $KERNEL_VERSION.\n\nSe reanudara automaticamente al iniciar."
    run_sudo reboot
}

flash_bios() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        (
            echo "10"
            echo "# Modo prueba: simulando pasos..."
            sleep 1
            echo "40"
            echo "# Modo prueba: simulando creacion de driver..."
            sleep 1
            echo "70"
            echo "# Modo prueba: simulando flasheo..."
            sleep 1
            echo "100"
            echo "# Simulacion completada (no se escribio BIOS)"
        ) | zenity --progress --title="Simulacion (sin flashear)" --percentage=0 --auto-close --no-cancel --width=420
        return
    fi

    (
        echo "10"
        echo "# Preparando herramienta..."
        run_sudo chmod +x "$AFULNX_PATH"

        echo "35"
        echo "# Creando driver para flasheo..."
        run_sudo "$AFULNX_PATH" /MAKEDRV

        echo "55"
        echo "# Generando driver..."
        run_sudo "$AFULNX_PATH" /GENDRV

        echo "85"
        echo "# Flasheando BIOS (ROM)..."
        run_sudo "$AFULNX_PATH" "$AFUWIN_ROM_PATH" /p /b /n /x

        echo "100"
        echo "# Finalizado"
    ) | zenity --progress --title="Actualizando BIOS" --percentage=0 --auto-close --no-cancel --width=420
}

main() {
    : > "$LOG_FILE"
    ensure_zenity
    check_files
    check_tools

    info "Este asistente flasheara el BIOS del equipo (Ceibal / Positivo BGH 11CLE2Plus).\n\nNecesitas:\n- Energia estable y no apagar el equipo.\n- Entrada de GRUB en español: \"$GRUB_ENTRY\".\n\nSe pedira tu contraseña de administrador."

    ask "Quieres continuar?" || exit 0

    if ask "Quieres ejecutar en modo prueba (no flashea BIOS ni reinicia)?"; then
        DRY_RUN=1
    fi

    # En modo prueba tambien pedimos la contraseña para simular el flujo real
    request_password

    CURRENT_KERNEL="$(uname -r)"
    if [[ "$CURRENT_KERNEL" != "$KERNEL_VERSION" && "$DRY_RUN" -eq 0 ]]; then
        warnbox "Se necesita el kernel $KERNEL_VERSION para cargar el driver de flasheo.\n\nSe instalara el kernel incluido, se configurara un arranque unico en GRUB y el equipo se reiniciara."
        ask "Instalar kernel y reiniciar ahora?" || exit 0
        install_kernel_and_reboot
        exit 0
    elif [[ "$CURRENT_KERNEL" != "$KERNEL_VERSION" && "$DRY_RUN" -eq 1 ]]; then
        warnbox "Modo prueba: el kernel actual no es $KERNEL_VERSION.\nSe simulara la instalacion de kernel y configuracion de GRUB, sin aplicar cambios."
        simulate_kernel_install
    fi

    if [[ "$DRY_RUN" -eq 0 ]]; then
        warnbox "Estas listo para escribir el BIOS.\n\nNo desconectes energia ni cierres la tapa durante el proceso."
        ask "Confirmas flashear ahora?" || exit 0
    else
        warnbox "Modo prueba: se simularan los pasos sin instalar kernel, sin flashear y sin reiniciar."
    fi

    flash_bios
    remove_autostart

    if [[ "$DRY_RUN" -eq 0 ]]; then
        info "BIOS actualizado con exito.\n\nSe reiniciara para aplicar cambios."
        ask "Reiniciar ahora?" && run_sudo reboot
    else
        info "Simulacion completada. No se escribio BIOS ni se reinicio el equipo."
    fi
}

main "$@"
