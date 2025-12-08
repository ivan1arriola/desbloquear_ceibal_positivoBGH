# Desbloqueo/actualizacion BIOS (Ceibal Positivo BGH)

Script y binarios para flashear el BIOS de un equipo Ceibal/Positivo BGH usando la herramienta de AMI en Linux. El flujo obliga a arrancar con el kernel 3.19.0-33-generic (incluido en los .deb) porque el driver que usa `afulnx_64` fue probado con ese kernel.

## Contenido
- `desbloquear.sh`: orquesta todo el proceso.
- `afulnx_64`: utilidad AMI Firmware Update para Linux.
- `afuwin.rom`: imagen de BIOS que se va a escribir.
- `linux-headers-3.19.0-33-*.deb` y `linux-image-3.19.0-33-*.deb`: paquetes del kernel requerido.
- `zenity*.deb`: paquete(s) para la interfaz grafica (incluye `zenity` y `zenity-common`), para instalarlo offline.
- `lubuntu-24.04.3-desktop-amd64.iso`: ISO opcional para levantar un live USB.

## Como funciona el script
1. Interfaz grafica (zenity): si falta zenity intenta instalarlo desde un `zenity*.deb` que debes dejar en la misma carpeta; valida que existan `sudo`, `grub-reboot`, `dpkg` y todos los archivos necesarios. Pide tu contraseña con un cuadro de dialogo.
2. Comprueba el kernel actual (`uname -r`):
   - Si no es `3.19.0-33-generic`, instala los .deb incluidos, crea un autostart `~/.config/autostart/update_bios.desktop` para reejecutarse tras el reinicio y programa el siguiente arranque en GRUB (cadena en espanol): `Opciones avanzadas para Ubuntu>Ubuntu, con Linux 3.19.0-33-generic`. Luego reinicia.
   - Si ya estas en ese kernel, sigue al siguiente paso.
3. Con el kernel adecuado, pide confirmacion final, hace ejecutable `afulnx_64`, crea y genera el driver (`/MAKEDRV` y `/GENDRV`) y flashea `afuwin.rom` con `/p /b /n /x`.
4. Borra el autostart y ofrece reiniciar.

## Uso rapido
1. Arranca un Linux con GRUB (mejor desde el ISO incluido o un sistema instalado).
2. Copia esta carpeta.
3. Doble clic en `DesbloquearBIOS.desktop` y elige "Ejecutar" (no hace falta terminal). El lanzador se encarga de dar permisos de ejecucion al script y llamarlo desde la misma carpeta.
5. Ingresa la contraseña cuando se pida y sigue los dialogos; no cortes la alimentacion mientras flashea el BIOS.
6. Modo prueba opcional: simula todos los pasos (pide contraseña, muestra barras de progreso de kernel y flasheo) pero no instala kernel, no escribe BIOS y no reinicia.

## Notas y advertencias
- Ejecuta solo en el hardware para el que esta pensada la ROM; flashear BIOS es riesgoso.
- El `grub-reboot` depende de que la entrada de menu exista y este en espanol. Si tu GRUB muestra otro idioma/orden, ajusta `GRUB_ENTRY` en el script antes de correrlo.
- Necesitas `zenity` para la interfaz grafica. Si no esta instalado, deja un `zenity*.deb` junto al script y este lo instalara automaticamente (usa `pkexec` o `sudo dpkg -i`).
- El autostart se guarda en `~/.config/autostart/update_bios.desktop` y se borra tras flashear; si interrumpes el proceso y no lo necesitas, elimina ese archivo.
- Asegura bateria/corriente estable durante todo el proceso.
