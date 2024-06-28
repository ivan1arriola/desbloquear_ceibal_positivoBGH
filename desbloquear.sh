#!/bin/bash

# Obtener la ruta absoluta de este script
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Variables del sistema para las ubicaciones de afulnx_64 y afuwin.rom
AFULNX_PATH="$SCRIPT_DIR/afulnx_64"
AFUWIN_ROM_PATH="$SCRIPT_DIR/afuwin.rom"

# Function to restart with specified kernel
reiniciar_con_kernel() {
    echo "========================================================="
    echo "       Kernel $KERNEL_VERSION está instalado"
    echo "========================================================="
    echo "Reiniciando en el kernel $KERNEL_VERSION..."
    sudo grub-reboot "Opciones avanzadas para Ubuntu>Ubuntu, con Linux $KERNEL_VERSION"
    echo "Reiniciando el sistema en 10 segundos..."
    echo "Para cancelar el reinicio, presiona Ctrl + C."
    echo "========================================================="
    sleep 10
    sudo reboot
}

instalar_kernel() {
    echo "========================================================="
    echo "     Kernel $KERNEL_VERSION no está instalado"
    echo "========================================================="
    echo "Instalando el kernel $KERNEL_VERSION..."
    sudo dpkg -i linux-headers-3.19*.deb linux-image-3.19*.deb
    echo "Instalación completada."
}

# Crear un archivo .desktop en ~/.config/autostart/
crear_archivo_reinicio() {
    mkdir -p ~/.config/autostart
    cat <<EOF > ~/.config/autostart/update_bios.desktop
[Desktop Entry]
Type=Application
Exec=gnome-terminal -- $SCRIPT_PATH
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Update BIOS
Comment=Run the BIOS update script
EOF
}

# Verificar el kernel
KERNEL_VERSION="3.19.0-33-generic"
CURRENT_KERNEL=$(uname -r)

# Da 10 segundos para cancelar el script
echo "========================================================="
echo "Este script actualizará el BIOS y reiniciará el sistema."
echo "========================================================="
echo "Para cancelar, presiona Ctrl + C en los próximos 10 segundos."
echo "========================================================="
sleep 10

# Verificar si el kernel actual es diferente al kernel requerido

if [[ "$CURRENT_KERNEL" != "$KERNEL_VERSION" ]]; then
    echo "========================================================="
    echo "             Kernel Verificación"
    echo "========================================================="
    echo "El kernel actual es $CURRENT_KERNEL."

    crear_archivo_reinicio

    # Verificar si el kernel está instalado
    if dpkg --list | grep -q "$KERNEL_VERSION"; then
        reiniciar_con_kernel
    else
        instalar_kernel
        reiniciar_con_kernel
    fi

    # Salir del script ya que se reiniciará el sistema
    exit 0
fi

echo "========================================================="
echo "       El kernel $KERNEL_VERSION ya está en uso"
echo "========================================================="
sleep 2

echo "Haciendo ejecutable afulnx_64..."
sudo chmod +x "$AFULNX_PATH"
sleep 2

echo "Creando el controlador de actualización del BIOS..."
sudo "$AFULNX_PATH" /MAKEDRV
sleep 2

echo "Generando el controlador de actualización del BIOS..."
sudo "$AFULNX_PATH" /GENDRV
sleep 2

echo "Actualizando el BIOS con afuwin.rom..."
sudo "$AFULNX_PATH" "$AFUWIN_ROM_PATH" /p /b /n /x
sleep 2

echo "========================================================="
echo "BIOS actualizado con éxito."
echo "========================================================="

echo "El sistema se reiniciará para aplicar los cambios."
echo "Para cancelar el reinicio, presiona Ctrl + C."
echo "========================================================="
sleep 10

sudo reboot

