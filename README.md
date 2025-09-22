<div align = "center">

<h1>dorbuntu — Dotfiles en Ubuntu/WSL/Codespaces</h1>

<br/>
<br/>

<img src="images/screenshot.png" alt="Dotfiles en acción" width="720" />

</div>

### ¿Qué es dorbuntu?

`dorbuntu` es un único script que instala lo necesario y configura tus dotfiles de forma segura y guiada usando `dotbare`. Está pensado para Ubuntu/Debian, WSL y GitHub Codespaces.

- **Seguro**: validaciones antes de actuar (conexión, entorno compatible, no ejecuta como root).
- **Claro**: mensajes explicativos y pasos ordenados.
- **Sencillo**: puedes indicar la URL de tu repositorio de dotfiles como parámetro.

---

### Tabla de contenidos

- [Requisitos](#requisitos)
- [Instalación rápida](#instalación-rápida)
- [Uso básico](#uso-básico)
- [Opciones disponibles](#opciones-disponibles)
- [Paso a paso: ¿Qué hace exactamente?](#qué-hace-exactamente)
- [Qué cambia y qué NO cambia](#qué-cambia-y-qué-no-cambia)
- [Ejemplos prácticos](#ejemplos-prácticos)
- [Variables de entorno útiles](#variables-de-entorno-útiles)
- [Solución de problemas (en lenguaje claro)](#solución-de-problemas-en-lenguaje-claro)
- [FAQ](#faq)
- [Desinstalación (manual)](#desinstalación-manual)
- [Créditos](#créditos)

### Requisitos

- Ubuntu/Debian (o WSL/Codespaces con base Ubuntu) con `apt`.
- Acceso a `sudo` para instalar paquetes.
- Conexión a internet.

### Instalación rápida

```bash
git clone https://github.com/25ASAB015/dotmarchy "$HOME/.local/share/dotmarchy"
bash "$HOME/.local/share/dotmarchy/dorbuntu"
```

Sugerencia: ejecuta el script desde tu carpeta personal. Si no estás en `~`, ejecuta primero:

```bash
cd ~
```

### Uso básico

```bash
# Ejecutar con el repositorio por defecto incluido en el script
bash dorbuntu

# O indicando tu repositorio (HTTPS o SSH)
bash dorbuntu https://github.com/usuario/mis-dotfiles.git
bash dorbuntu git@github.com:usuario/mis-dotfiles.git
```

El script instalará lo necesario y configurará `dotbare` apuntando al repositorio que indiques (o al predeterminado del script si no pasas ninguno).

### Opciones disponibles

- **--repo URL**: URL del repo de dotfiles para `dotbare` (equivalente a pasarlo como argumento posicional).
- **-h, --help**: muestra ayuda y ejemplos de uso.

Notas:
- Si indicas tanto `--repo URL` como un argumento posicional, el último leído tiene prioridad.
- El script puede solicitar tu contraseña de `sudo` para instalar paquetes.

### ¿Qué hace exactamente?

1. Verifica que estás en Ubuntu/Debian (requiere `apt`) y que no lo ejecutas como `root`.
2. Sugiere ejecutar desde tu `HOME` y detecta si estás en WSL o Codespaces (solo informativo).
3. Comprueba conexión a internet (intentando acceder a `github.com`).
4. Instala paquetes desde repos oficiales con `apt` (ej.: `git`, `curl`, `tree`, `highlight`, `ruby-full`, `git-delta`, `diff-so-fancy`).
5. Ajusta compatibilidad `bat`/`batcat` (crea alias `bat` si solo existe `batcat`).
6. Instala `dotbare` vía script oficial si no está presente.
7. Configura `dotbare` de forma segura e idempotente:
   - Usa `DOTBARE_DIR` (por defecto `~/.cfg`) y `DOTBARE_TREE` (por defecto `~`).
   - Si `~/.cfg` ya existe como repo bare, respeta el remoto actual (no lo sobrescribe automáticamente).
   - Si `~/.cfg` existe pero no es un repo bare, se detiene con un mensaje claro para que decidas cómo proceder.

Tiempo estimado: 2-10 minutos (según tu conexión y paquetes ya instalados).

Al finalizar, verás un mensaje de resumen indicando que todo salió bien.

---

### Qué cambia y qué NO cambia

- **Sí cambia**
  - Instala paquetes del sistema (con `apt`).
  - Configura `dotbare` para gestionar tu repo de dotfiles.
- **No cambia**
  - No modifica archivos críticos del sistema.
  - No reemplaza un remoto existente de `dotbare` si ya apunta a otro repo.

### Ejemplos prácticos

```bash
# Ejecutar con el repo por defecto
bash dorbuntu

# Elegir un repositorio distinto
bash dorbuntu --repo https://github.com/usuario/mis-dotfiles.git
bash dorbuntu git@github.com:usuario/mis-dotfiles.git

# Ejecutar desde cualquier ubicación (asegúrate de estar en ~)
cd ~ && bash ~/.local/share/dotmarchy/dorbuntu --repo https://github.com/usuario/mis-dotfiles.git
```

### Variables de entorno útiles

- `DOTBARE_DIR`: ruta al repositorio bare de dotbare (defecto: `~/.cfg`).
- `DOTBARE_TREE`: directorio de trabajo para dotfiles (defecto: `~`).

Ejemplo:

```bash
DOTBARE_DIR="$HOME/.dotfiles.git" DOTBARE_TREE="$HOME" bash dorbuntu --repo https://github.com/usuario/mis-dotfiles.git
```

### Solución de problemas (en lenguaje claro)

- «Este script está pensado para Ubuntu/Debian»: tu sistema no tiene `apt`.
- Error al instalar paquetes: revisa tu conexión a internet y vuelve a ejecutar.
- Ya tengo `~/.cfg` con mis dotfiles: dorbuntu respetará tu configuración actual y no la sobrescribirá.
- Permisos de `sudo`: puede pedir tu contraseña para instalar paquetes; es normal.

Si algo falla, revisa el archivo de registro:

```bash
cat "$HOME/.local/share/dorbuntu/install_errors.log"
```

---

### FAQ

**¿Dónde se guardan mis dotfiles?**  
En un repo bare (sin working tree propio) en `~/.cfg`, gestionado por `dotbare`. Tu `$HOME` es el working tree.

**¿Puedo cambiar el repositorio de dotfiles más tarde?**  
Sí. Ejecuta de nuevo el script con otra URL. Si ya tenías un remoto distinto configurado, el script te avisará y no lo cambiará automáticamente.

**¿Necesito usar Git/SSH?**  
No. Puedes usar una URL HTTPS. Si eliges SSH (`git@github.com:...`), necesitarás tener tus llaves configuradas.

**¿Debo ejecutar el script como root?**  
No. El script te lo impedirá. Usa tu usuario normal y proporciona `sudo` cuando se requiera.

### Desinstalación (manual)

dorbuntu instala paquetes del sistema y configura `dotbare`. Para revertir cambios:

```bash
# Quitar dotbare (opcional)
sudo apt-get remove -y dotbare || true  # Si lo instalaste como paquete; si fue via script, omitir

# Respaldar/eliminar el repositorio bare (¡cuidado!)
mv "$HOME/.cfg" "$HOME/.cfg.backup"
```

### Créditos

- Basado en `dotbare` para la gestión de dotfiles.
- Diseñado con cariño para una experiencia clara y segura en terminal.


