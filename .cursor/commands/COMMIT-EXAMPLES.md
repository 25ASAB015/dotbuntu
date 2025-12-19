# Ejemplos de Organización de Commits

Este documento muestra cómo `/git-pr-merge` organiza cambios en **múltiples commits lógicos**.

## ⚠️ REGLA FUNDAMENTAL

**NUNCA un solo commit gigante. SIEMPRE múltiples commits organizados.**

---

## 📊 Ejemplo Real: Migración NIX

### Cambios (18 archivos modificados)

```bash
$ git status --short

M  docs/NIX_SETUP.md
M  helper/utils.sh
M  openspec/changes/migrate-to-nix-package-management/tasks.md
M  scripts/core/fupdate
M  scripts/core/fzsh
M  scripts/extras/legacy/fcargo
M  scripts/extras/legacy/fgithub
M  scripts/extras/legacy/fnpm
M  scripts/extras/legacy/fpython
M  scripts/extras/legacy/fruby
M  scripts/legacy/faur
M  scripts/legacy/fchaotic
M  scripts/legacy/fchaotic-deps
M  scripts/legacy/fdeps
A  scripts/post-dotbare-pull.sh
A  .implementation-summary.md
```

### ❌ INCORRECTO (1 commit)

```bash
git add .
git commit -m "Update files for NIX migration"
```

**Problemas:**
- No se puede entender qué cambió
- Imposible revertir partes específicas
- Difícil de revisar en PR
- Mala práctica profesional

### ✅ CORRECTO (5 commits)

```bash
# Commit 1: Nueva funcionalidad
git add scripts/post-dotbare-pull.sh docs/NIX_SETUP.md
git commit -m "feat(nix): implement auto-sync hook for packages.nix changes

- Add post-dotbare-pull.sh script (267 lines)
- Auto-detects packages.nix modifications after dotbare pull
- Shows colorized diff (diff-so-fancy/delta support)
- Interactive mode with user confirmation
- --auto-sync flag for non-interactive workflows
- Update docs/NIX_SETUP.md with auto-sync section"

# Commit 2: Deprecaciones
git add scripts/legacy/* scripts/extras/legacy/*
git commit -m "refactor(legacy): add deprecation warnings to all legacy scripts

Add deprecation headers to 9 legacy package management scripts:
- scripts/legacy/: fdeps, faur, fchaotic, fchaotic-deps
- scripts/extras/legacy/: fcargo, fnpm, fpython, fruby, fgithub

Each header includes:
- Clear deprecation warning
- Removal date (v3.0.0 - 2026-03-01)
- Migration instructions (use NIX instead)
- Link to migration guide"

# Commit 3: Corrección de imports
git add scripts/core/fzsh scripts/core/fupdate helper/utils.sh
git commit -m "fix(imports): update package_manager.sh import paths

Fix broken imports after package_manager.sh was moved to deprecated:
- scripts/core/fzsh: Update to ../scripts/deprecated/package_manager.sh
- scripts/core/fupdate: Update to ../scripts/deprecated/package_manager.sh
- helper/utils.sh: Update path with \"(LEGACY MODE)\" comment

Ensures legacy package management still works with --legacy flag."

# Commit 4: Documentación OpenSpec
git add openspec/changes/migrate-to-nix-package-management/tasks.md
git commit -m "docs(openspec): mark implementation tasks complete in tasks.md

Update tasks.md marking all implementation tasks as complete:
- Phase 1: All core NIX infrastructure [x]
- Phase 2: All integration tasks [x] (including 2.3.x auto-sync)
- Phase 3: All transition tasks [x] (including 3.2.3 legacy cleanup)
- Phase 4: All code polish tasks [x]

Remaining tasks clearly marked as TEST: or USER: prefixes.
Implementation is 100% complete. Ready for manual testing phase."

# Commit 5: Resumen
git add .implementation-summary.md
git commit -m "docs: add comprehensive implementation summary

Add .implementation-summary.md documenting:
- Complete implementation status (100% code, 0% testing)
- All changes made (new files, modifications)
- Code quality metrics (A+ grade, 100% standards compliance)
- Testing checklist for manual validation
- Next steps for user"
```

**Resultado:** 5 commits claros, cada uno con un propósito específico.

---

## 📊 Ejemplo: Feature Nueva + Tests + Docs

### Cambios (12 archivos)

```bash
$ git status --short

A  src/auth/jwt.js
A  src/auth/middleware.js
M  src/routes/api.js
A  tests/auth/jwt.test.js
A  tests/auth/middleware.test.js
M  tests/routes/api.test.js
M  docs/API.md
M  docs/authentication.md
M  README.md
M  CHANGELOG.md
M  package.json
M  .env.example
```

### ✅ CORRECTO (4 commits)

```bash
# Commit 1: Core feature
git add src/auth/jwt.js src/auth/middleware.js src/routes/api.js
git commit -m "feat(auth): implement JWT authentication middleware

- Add JWT token generation and validation (jwt.js)
- Create authentication middleware (middleware.js)
- Integrate auth middleware in API routes
- Support for Bearer token format
- Token expiration handling (24h default)
- Refresh token mechanism"

# Commit 2: Tests
git add tests/auth/* tests/routes/api.test.js
git commit -m "test(auth): add comprehensive JWT authentication tests

- Test JWT token generation and validation
- Test authentication middleware behavior
- Test protected route access
- Test token expiration scenarios
- Test invalid token handling
- Update API route tests with auth"

# Commit 3: Documentation
git add docs/API.md docs/authentication.md README.md CHANGELOG.md
git commit -m "docs: document JWT authentication implementation

- Add authentication guide (docs/authentication.md)
- Update API documentation with auth endpoints
- Add authentication section to README
- Document Bearer token usage
- Update CHANGELOG for v2.1.0"

# Commit 4: Configuration
git add package.json .env.example
git commit -m "chore: add JWT dependencies and configuration

- Add jsonwebtoken package
- Add express-jwt middleware
- Add JWT_SECRET to .env.example
- Add JWT_EXPIRES_IN configuration"
```

---

## 📊 Ejemplo: Bug Fix + Mejoras

### Cambios (8 archivos)

```bash
$ git status --short

M  src/database/connection.js
M  src/database/pool.js
M  src/utils/retry.js
A  tests/database/connection.test.js
M  docs/troubleshooting.md
M  README.md
M  config/database.js
M  CHANGELOG.md
```

### ✅ CORRECTO (3 commits)

```bash
# Commit 1: Bug fix
git add src/database/connection.js src/database/pool.js src/utils/retry.js config/database.js
git commit -m "fix(database): resolve connection timeout and retry logic

- Fix connection pool timeout handling
- Implement exponential backoff for retries
- Add connection health checks
- Increase default connection timeout to 30s
- Add retry configuration options

Fixes: Connection timeouts under high load
Closes: #123"

# Commit 2: Tests
git add tests/database/connection.test.js
git commit -m "test(database): add connection timeout tests

- Test connection timeout scenarios
- Test retry mechanism with exponential backoff
- Test connection pool behavior under load
- Test health check functionality"

# Commit 3: Documentation
git add docs/troubleshooting.md README.md CHANGELOG.md
git commit -m "docs: document database connection improvements

- Add troubleshooting section for connection issues
- Document retry configuration options
- Update README with connection best practices
- Add CHANGELOG entry for v1.2.1"
```

---

## 📊 Ejemplo: Refactor Grande

### Cambios (20+ archivos)

```bash
$ git status --short

M  src/services/user.js
M  src/services/order.js
M  src/services/payment.js
D  src/utils/old-validator.js
A  src/utils/validator.js
M  src/controllers/user.js
M  src/controllers/order.js
M  tests/services/user.test.js
M  tests/services/order.test.js
M  docs/architecture.md
# ... más archivos
```

### ✅ CORRECTO (6+ commits)

```bash
# Commit 1: New validation system
git add src/utils/validator.js
git commit -m "refactor(utils): implement new validation system

- Create centralized validator with schema support
- Add common validation rules (email, phone, etc.)
- Support for custom validation functions
- Better error messages with field context
- Replace old-validator.js"

# Commit 2: Update services
git add src/services/user.js src/services/order.js src/services/payment.js
git commit -m "refactor(services): migrate to new validation system

- Update user service to use new validator
- Update order service validation rules
- Update payment service validation
- Remove old validation imports
- Standardize error handling"

# Commit 3: Update controllers
git add src/controllers/user.js src/controllers/order.js
git commit -m "refactor(controllers): update validation error handling

- Use new validation error format
- Improve error responses to clients
- Add field-specific error messages"

# Commit 4: Remove old code
git add src/utils/old-validator.js
git commit -m "refactor(utils): remove deprecated validator

- Delete old-validator.js (replaced by validator.js)
- All services migrated to new system"

# Commit 5: Update tests
git add tests/services/*
git commit -m "test: update tests for new validation system

- Update user service tests
- Update order service tests
- Add tests for new validation rules
- Update error assertion patterns"

# Commit 6: Documentation
git add docs/architecture.md
git commit -m "docs: document new validation architecture

- Add validation system documentation
- Update architecture diagrams
- Add migration guide from old validator"
```

---

## 🎯 Reglas de Oro

### ✅ HACER

1. **Separar por tipo**:
   - feat, fix, docs, refactor, test → Commits separados

2. **Separar por scope**:
   - auth, database, api, ui → Commits separados si no relacionados

3. **3-7 commits típicamente**:
   - Para PR de tamaño medio

4. **Commits auto-contenidos**:
   - Cada commit debe dejar el código funcional

5. **Mensajes descriptivos**:
   - Subject + body detallado con bullets

### ❌ NO HACER

1. **Un commit gigante**:
   ```bash
   git add .
   git commit -m "Update stuff"  # ❌ NUNCA
   ```

2. **Mezclar feat + fix**:
   ```bash
   git commit -m "feat: add auth and fix database bug"  # ❌ Separar
   ```

3. **Commits sin detalle**:
   ```bash
   git commit -m "refactor"  # ❌ Muy vago
   ```

4. **Demasiados commits pequeños**:
   ```bash
   git commit -m "fix typo"  # 20 veces ❌
   ```

---

## 💡 Verificación Rápida

Antes de hacer push, verifica:

```bash
# ¿Cuántos commits?
git log --oneline origin/master..HEAD

# ¿Qué tiene cada commit?
git log --stat origin/master..HEAD

# ¿Los mensajes son claros?
git log --pretty=format:"%s" origin/master..HEAD
```

**Preguntas:**
- ✅ ¿Son 2+ commits?
- ✅ ¿Cada commit tiene un propósito claro?
- ✅ ¿Los mensajes siguen Conventional Commits?
- ✅ ¿Se pueden revisar independientemente?

Si todas son ✅, ¡perfecto para push!

---

## 🎓 El Comando Lo Hace Automáticamente

Cuando usas `/git-pr-merge`, el AI:

1. **Analiza** todos los archivos cambiados
2. **Agrupa** por tipo, scope, y relación
3. **Crea** múltiples commits (típicamente 3-7)
4. **Verifica** que no haya un solo commit gigante
5. **Muestra** resumen antes de push

**Tú solo invocas:**
```
/git-pr-merge feat/my-feature
```

**El AI hace todo el trabajo de organización profesional.** 🚀

