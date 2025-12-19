# 📝 Guía de Plantilla para Pull Requests

Esta guía explica cómo usar la plantilla de Pull Request para crear PRs descriptivos y consistentes.

## 📍 Ubicación

La plantilla está ubicada en: `.github/pull_request_template.md`

GitHub automáticamente detecta esta plantilla cuando creas un nuevo PR.

## 🎯 Propósito

La plantilla ayuda a:
- ✅ Documentar cambios de manera consistente
- ✅ Facilitar la revisión de código
- ✅ Mantener un historial claro del proyecto
- ✅ Asegurar que no se olviden aspectos importantes

## 📋 Cómo Usar

### Opción 1: GitHub Web Interface (Recomendado)

1. **Crear el PR en GitHub:**
   - Ve a tu repositorio en GitHub
   - Haz clic en "Pull requests" → "New pull request"
   - Selecciona tu rama como "compare" y `master` como "base"

2. **La plantilla se carga automáticamente:**
   - GitHub detecta `.github/pull_request_template.md` automáticamente
   - El contenido de la plantilla aparecerá en el campo de descripción

3. **Completa la plantilla:**
   - Reemplaza los placeholders `[texto entre corchetes]` con información real
   - Completa cada sección según corresponda a tu cambio
   - Elimina las secciones que no apliquen (ej: "Archivos Eliminados" si no hay)

4. **Revisa y crea el PR:**
   - Verifica que toda la información sea precisa
   - Marca los items del checklist que apliquen
   - Haz clic en "Create pull request"

### Opción 2: GitHub CLI

```bash
# 1. Asegúrate de estar en tu rama de feature
git checkout tu-rama-de-feature

# 2. Crea el PR usando la plantilla directamente
gh pr create \
  --title "🧪 [Título Descriptivo del Cambio]" \
  --body-file .github/pull_request_template.md \
  --base master \
  --head tu-rama-de-feature

# 3. Edita el PR después si necesitas ajustar la descripción
gh pr edit <número-del-pr> --body-file .github/pull_request_template.md
```

**Ejemplo práctico:**
```bash
# Crear PR para una nueva feature
gh pr create \
  --title "✨ Add new feature X" \
  --body-file .github/pull_request_template.md \
  --base master \
  --head add-feature-x
```

### Opción 3: Manual (Editar antes de crear)

1. **Copia la plantilla:**
   ```bash
   cat .github/pull_request_template.md
   ```

2. **Edita el contenido:**
   - Abre tu editor de texto favorito
   - Reemplaza todos los placeholders con información real
   - Elimina secciones que no apliquen

3. **Guarda en un archivo temporal:**
   ```bash
   # Edita y guarda como pr_description.md
   nano pr_description.md
   ```

4. **Crea el PR con el archivo editado:**
   ```bash
   gh pr create --title "Título" --body-file pr_description.md --base master --head tu-rama
   ```

### Opción 4: Editar PR existente

Si ya creaste el PR pero quieres usar la plantilla:

```bash
# Editar un PR existente con la plantilla
gh pr edit <número-del-pr> --body-file .github/pull_request_template.md
```

## 📝 Secciones de la Plantilla

### Resumen
- **Qué incluir**: 2-3 líneas explicando el cambio principal
- **Ejemplo**: "Este PR implementa una suite de verificación que automatiza la validación de componentes configurados"

### Problema Resuelto
- **Qué incluir**: Contexto sobre por qué este cambio es necesario
- **Ejemplo**: "Los usuarios no tenían forma automatizada de verificar la configuración"

### Características Implementadas
- **Qué incluir**: Lista detallada de funcionalidades nuevas o mejoradas
- **Formato**: Usar viñetas con ✅, 🔧, 📚, 🎨 según el tipo de cambio

### Archivos Modificados
- **Qué incluir**: Lista organizada de archivos nuevos, modificados o eliminados
- **Formato**: Agrupar por tipo (Nuevos/Modificados/Eliminados)

### Testing
- **Qué incluir**: Descripción de cómo se probó el cambio
- **Formato**: Lista de casos de prueba ejecutados

### Ejemplo de Salida
- **Cuándo incluir**: Si el cambio afecta la salida del usuario
- **Formato**: Bloque de código con ejemplo real

### Relacionado
- **Qué incluir**: Referencias a OpenSpec changes, issues, o especificaciones relacionadas

### Checklist
- **Qué hacer**: Marcar todos los items que aplican antes de solicitar review

## 💡 Tips

1. **Sé específico**: En lugar de "Mejoré el código", di "Agregué validación de email y mejoré manejo de errores"

2. **Incluye ejemplos**: Si es posible, muestra ejemplos de salida o comportamiento

3. **Referencia OpenSpec**: Si el cambio tiene un OpenSpec change asociado, inclúyelo

4. **Elimina lo que no aplica**: No dejes secciones vacías o con placeholders

5. **Revisa antes de crear**: Asegúrate de que toda la información sea precisa

## 📚 Ejemplo Completo

Ver el PR #7 como ejemplo de uso completo de la plantilla:
- https://github.com/25ASAB015/github-config/pull/7

## 🔄 Actualización de la Plantilla

Si necesitas actualizar la plantilla:
1. Edita `.github/pull_request_template.md`
2. Considera crear un PR para actualizar la plantilla
3. Documenta cambios significativos en esta guía

## 🧹 Mantenimiento: Limpiar Ramas Locales

Después de mergear PRs, las ramas remotas se eliminan pero las locales pueden quedar. Para limpiar:

```bash
# 1. Actualizar referencias remotas
git remote prune origin

# 2. Ver ramas locales que ya no existen en remoto
git branch -vv | grep "gone"

# 3. Eliminar ramas locales obsoletas
git branch -d nombre-de-la-rama

# 4. Si la rama tiene cambios no mergeados (forzar eliminación)
git branch -D nombre-de-la-rama

# 5. Verificar que todo está limpio
git branch -vv
```

**Ejemplo completo:**
```bash
# Limpiar todas las ramas locales que ya no existen en GitHub
git remote prune origin
git branch -vv | grep "gone" | awk '{print $1}' | xargs -r git branch -d
```

**Nota:** El comando `git pull` puede fallar con "Cannot fast-forward to multiple branches" si hay ramas locales obsoletas. Limpia las ramas primero y luego haz `git pull origin master`.

