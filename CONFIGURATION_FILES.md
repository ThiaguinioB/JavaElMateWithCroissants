# 📋 Documentación de Archivos de Configuración - Horusec

Esta documentación explica cada archivo de configuración del sistema de análisis de seguridad integrado con Horusec CLI.

## 📁 Índice de Archivos

| Archivo | Propósito | Uso |
|---------|-----------|-----|
| [`.github/workflows/horusec.yml`](#github-workflow) | GitHub Actions CI/CD | Automatización |
| [`docker-compose.horusec.yml`](#docker-compose-cicd) | Análisis CI/CD | Desarrollo/CI |
| [`docker-compose.horusec-platform.yml`](#docker-compose-platform) | Plataforma completa | Desarrollo local |
| [`Dockerfile.horusec`](#dockerfile) | Imagen personalizada | Construcción |
| [`horusec-config.json`](#configuracion-horusec) | Configuración CLI | Análisis |
| [`validate_thresholds.sh`](#script-validacion) | Validación umbrales | Post-análisis |
| [`init-databases.sql`](#base-datos) | Inicialización BD | Setup inicial |

---

## 🔄 GitHub Workflow {#github-workflow}

**Archivo**: `.github/workflows/horusec.yml`

### Propósito
Automatiza el análisis de seguridad en el pipeline de CI/CD usando GitHub Actions.

### Flujo de Ejecución
1. **Trigger**: Se ejecuta en push a `docker-compose/horusec` o PR a `main`
2. **Checkout**: Descarga el código del repositorio
3. **Análisis**: Ejecuta Horusec CLI en Docker container
4. **Reporte**: Sube el reporte JSON como artifact

### Configuración Clave
```yaml
# Parámetros importantes del análisis
--disable-docker          # Evita análisis recursivo de Docker
--return-error            # Falla el pipeline si hay vulnerabilidades críticas
--output-format json      # Formato estructurado para procesamiento
```

### Acceso a Reportes
Los reportes se almacenan como artifacts de GitHub, accesibles desde:
`Actions > [Run específico] > Artifacts > horusec-report`

### 🔬 Evolución del Workflow (Caso de Estudio Real)

**Contexto**: Este workflow pasó por muchas horas de debugging intenso. Documentamos todo el proceso para ayudar a futuros desarrolladores.

#### **Iteración 1 - Fallo de Instalación**
```yaml
# ❌ PROBLEMA: Instalación duplicada
- name: Download and install Horusec CLI
  run: |
    curl -fsSL "https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh" | bash -s latest
    sudo mv ./horusec /usr/local/bin/horusec  # ← Causaba error
    horusec start --json-output-file=".horusec/horusec-report.json"
```
**Error**: `mv: cannot stat './horusec': No such file or directory`  
**Causa**: El script oficial ya instala Horusec en `/usr/local/bin/horusec`

#### **Iteración 2 - Permisos de Directorio **
```yaml
# ❌ PROBLEMA: Permisos insuficientes
- name: Run Horusec
  run: |
    mkdir -p .horusec
    horusec start --json-output-file=".horusec/horusec-report.json"
```
**Error**: `error creating and/or writing to the specified file`  
**Causa**: Problemas de permisos en GitHub Actions

#### **Iteración 3 - Directorio Desaparece**
```yaml
# ❌ PROBLEMA: Horusec elimina directorio automáticamente
- name: Run Horusec
  run: |
    mkdir -p .horusec
    chmod 755 .horusec
    horusec start --json-output-file=".horusec/horusec-report.json"
```
**Error**: `Directory .horusec does not exist`  
**Causa**: Horusec limpia automáticamente el directorio `.horusec` después del análisis

#### **Solución Final - Directorio Persistente**
```yaml
# ✅ SOLUCIÓN: Usar directorio que persiste
- name: Run Horusec security analysis
  run: |
    mkdir -p reports  # Directorio que NO elimina Horusec
    chmod 755 reports
    
    horusec start \
      --json-output-file="reports/horusec-report.json"
    
    # Copiar a .horusec para compatibilidad con scripts
    mkdir -p .horusec
    cp reports/horusec-report.json .horusec/horusec-report.json
```

#### **Lecciones Críticas Aprendidas**

1. **📖 RTFM (Read The F*cking Manual)**: Horusec tiene comportamientos no documentados claramente
2. **🧪 Test Locally First**: `docker run` localmente reprodujo el problema
3. **📋 Full Context Matters**: Los logs completos revelan más que el error final
4. **🔄 Systematic Debugging**: Un problema a la vez, documentar cada intento
5. **💾 Persistence Strategy**: Entender qué directorios persisten vs. se eliminan

---

## 🐳 Docker Compose CI/CD {#docker-compose-cicd}

**Archivo**: `docker-compose.horusec.yml`

### Propósito
Configuración simplificada para análisis de seguridad en entornos CI/CD.

### Características
- Construye imagen personalizada con validación de umbrales
- Monta código fuente como volumen read-only
- Persiste reportes en el sistema de archivos del host
- Configurable via variables de entorno

### Variables de Entorno
```bash
# Configurar antes de ejecutar
export HORUSEC_MAX_CRITICAL_VULNERABILITY=0
export HORUSEC_MAX_HIGH_VULNERABILITY=5  
export HORUSEC_MAX_MEDIUM_VULNERABILITY=10
export HORUSEC_MAX_LOW_VULNERABILITY=20
```

### Ejecución
```bash
# Análisis único
docker-compose -f docker-compose.horusec.yml up --build

# Con variables personalizadas
HORUSEC_MAX_CRITICAL_VULNERABILITY=0 \
HORUSEC_MAX_HIGH_VULNERABILITY=3 \
docker-compose -f docker-compose.horusec.yml up --build
```

---

## 🏢 Docker Compose Platform {#docker-compose-platform}

**Archivo**: `docker-compose.horusec-platform.yml`

### Propósito
Infraestructura completa para desarrollo local con interfaz web.

### Servicios Incluidos
```
PostgreSQL (5432)     ←→ Base de datos principal
RabbitMQ (5672/15672) ←→ Sistema de mensajería  
Horusec Auth (8006/8007) ←→ Autenticación
Horusec API (8000)    ←→ API REST principal
Horusec Core          ←→ Motor de análisis (interno)
Horusec Manager (8043) ←→ Interfaz web
```

### Configuración Inicial
```bash
# Variables obligatorias
export HORUSEC_JWT_SECRET="mi-secret-super-seguro-de-32-caracteres"
export HORUSEC_MANAGER_URL="http://localhost:8043"

# Opcional: personalizar base de datos
export POSTGRES_USER="horusec"
export POSTGRES_PASSWORD="password_seguro"
export POSTGRES_DB="horusec_db"
```

### Acceso Web
- **URL**: http://localhost:8043
- **Usuario**: `dev`
- **Email**: `dev@example.com`
- **Password**: `Devpass0*`

### Healthchecks
Todos los servicios incluyen verificaciones de salud que aseguran:
- PostgreSQL responde a consultas
- RabbitMQ acepta conexiones
- Servicios Horusec están listos antes de iniciar dependientes

---

## 🛠️ Dockerfile Personalizado {#dockerfile}

**Archivo**: `Dockerfile.horusec`

### Propósito
Extiende la imagen oficial de Horusec CLI con funcionalidades adicionales.

### Mejoras Añadidas
- **Docker CLI**: Para análisis de contenedores
- **jq**: Para procesamiento de JSON
- **Script personalizado**: Validación automática de umbrales
- **Configuración automatizada**: Análisis + validación en un comando

### Construcción
```bash
# Construir imagen personalizada
docker build -f Dockerfile.horusec -t mi-horusec-custom .

# Usar directamente
docker run --rm -v $(pwd):/src mi-horusec-custom
```

### Flujo Interno
1. Ejecuta `horusec start` con configuración optimizada
2. Genera reporte JSON en `/src/.horusec/output.json`
3. Ejecuta `validate_thresholds.sh` automáticamente
4. Retorna código de salida apropiado (0=éxito, 1=fallo)

---

## ⚙️ Configuración Horusec {#configuracion-horusec}

**Archivo**: `horusec-config.json`

### Propósito
Define configuración personalizada para el comportamiento de Horusec CLI.

### Parámetros Principales
```json
{
  "horusecCliWorkDir": "./",                    // Directorio base de análisis
  "horusecCliSeveritiesToIgnore": ["LOW", "MEDIUM"], // Filtros de severidad
  "horusecCliEnableGitHistory": false,          // Análisis histórico Git
  "horusecCliAuthorization": "00000000..."      // Token de autorización
}
```

### Personalización por Proyecto
```json
{
  // Para proyectos con muchos falsos positivos
  "horusecCliSeveritiesToIgnore": ["LOW"],
  
  // Para análisis exhaustivo (puede ser lento)
  "horusecCliEnableGitHistory": true,
  
  // Para integrar con Horusec Platform
  "horusecCliAuthorization": "tu-token-real-aqui"
}
```

---

## 📊 Script de Validación {#script-validacion}

**Archivo**: `validate_thresholds.sh`

### Propósito
Procesa reportes de Horusec y valida contra umbrales de seguridad configurados.

### Funcionalidades
1. **Validación de archivo**: Verifica existencia y formato JSON válido
2. **Conteo por severidad**: Clasifica vulnerabilidades encontradas  
3. **Reporte detallado**: Muestra información completa de cada issue
4. **Validación de umbrales**: Compara contra límites configurados
5. **Exit codes**: Retorna estado apropiado para CI/CD

### Configuración de Umbrales
```bash
# Estricto (recomendado para producción)
export HORUSEC_MAX_CRITICAL_VULNERABILITY=0
export HORUSEC_MAX_HIGH_VULNERABILITY=0
export HORUSEC_MAX_MEDIUM_VULNERABILITY=2
export HORUSEC_MAX_LOW_VULNERABILITY=5

# Permisivo (para desarrollo inicial)
export HORUSEC_MAX_CRITICAL_VULNERABILITY=1
export HORUSEC_MAX_HIGH_VULNERABILITY=5
export HORUSEC_MAX_MEDIUM_VULNERABILITY=10
export HORUSEC_MAX_LOW_VULNERABILITY=20
```

### Formato de Salida
```
🔍 DETALLES DE VULNERABILIDADES ENCONTRADAS:
===============================================
📁 File: src/main/java/Example.java
📍 Line: 42
🚨 Severity: HIGH
🎯 Confidence: HIGH
🔑 Rule ID: HS-JAVA-1
📖 Details: Potential SQL injection vulnerability
===============================================

📊 RESUMEN DEL ANÁLISIS DE SEGURIDAD
🔴 Total de Vulnerabilidades CRÍTICAS: 0
🟠 Total de Vulnerabilidades ALTAS: 1
🟡 Total de Vulnerabilidades MEDIAS: 3
🟢 Total de Vulnerabilidades BAJAS: 5

🎯 VALIDACIÓN DE UMBRALES:
🔴 CRÍTICAS: 0 / 0 (máximo permitido)
🟠 ALTAS: 1 / 2 (máximo permitido)  
🟡 MEDIAS: 3 / 5 (máximo permitido)
🟢 BAJAS: 5 / 10 (máximo permitido)

✅ ANÁLISIS DE SEGURIDAD EXITOSO
```

---

## 🗄️ Inicialización de Base de Datos {#base-datos}

**Archivo**: `init-databases.sql`

### Propósito
Script SQL para crear las bases de datos necesarias para Horusec Platform.

### Bases de Datos Creadas
- `horusec_api`: Datos de proyectos y análisis
- `horusec_auth`: Usuarios y autenticación
- `horusec_core`: Configuraciones del motor
- `horusec_analytic`: Métricas y reportes
- `horusec_messages`: Cola de mensajes

### Estado Actual
⚠️ **Nota**: Este script actualmente NO se usa automáticamente en el docker-compose, ya que Horusec maneja la creación de esquemas internamente.

### Uso Manual
```bash
# Si necesitas ejecutarlo manualmente
psql -U horusec -d postgres -f init-databases.sql
```

---

## 🔧 Tips de Configuración

### Para Desarrollo
```bash
# Configuración permisiva para desarrollo inicial
export HORUSEC_MAX_CRITICAL_VULNERABILITY=2
export HORUSEC_MAX_HIGH_VULNERABILITY=10
export HORUSEC_MAX_MEDIUM_VULNERABILITY=20
export HORUSEC_MAX_LOW_VULNERABILITY=50
```

### Para Staging
```bash
# Configuración balanceada para testing
export HORUSEC_MAX_CRITICAL_VULNERABILITY=0
export HORUSEC_MAX_HIGH_VULNERABILITY=3
export HORUSEC_MAX_MEDIUM_VULNERABILITY=10
export HORUSEC_MAX_LOW_VULNERABILITY=20
```

### Para Producción
```bash
# Configuración estricta para producción
export HORUSEC_MAX_CRITICAL_VULNERABILITY=0
export HORUSEC_MAX_HIGH_VULNERABILITY=0
export HORUSEC_MAX_MEDIUM_VULNERABILITY=2
export HORUSEC_MAX_LOW_VULNERABILITY=5
```

---

## 🚨 Troubleshooting

### Problemas Comunes en GitHub Actions (Experiencia Real de 4 Horas de Debugging)

Durante la implementación del workflow de Horusec, encontramos varios problemas críticos que documentamos aquí para futuras referencias:

#### 🔥 **Problema 1: Error de Instalación Duplicada**
**Error**: `mv: cannot stat './horusec': No such file or directory`

**Causa**: El script oficial de instalación de Horusec ya instala el binario en `/usr/local/bin/horusec`, pero nuestro workflow intentaba moverlo nuevamente.

**Solución**:
```yaml
# ❌ INCORRECTO - Causaba error
- name: Download and install Horusec CLI
  run: |
    curl -fsSL "https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh" | bash -s latest
    sudo mv ./horusec /usr/local/bin/horusec  # ← Esta línea causaba el fallo
    horusec version

# ✅ CORRECTO - Sin línea duplicada
- name: Download and install Horusec CLI
  run: |
    curl -fsSL "https://raw.githubusercontent.com/ZupIT/horusec/main/deployments/scripts/install.sh" | bash -s latest
    horusec version  # El script ya instala Horusec correctamente
```

**Lección**: Siempre revisar qué hace exactamente un script antes de agregar pasos adicionales.

---

#### 🔥 **Problema 2: Directorio de Salida Eliminado Automáticamente**
**Error**: `open /path/.horusec/horusec-report.json: no such file or directory`

**Causa**: Horusec **SIEMPRE** elimina el directorio `.horusec` después del análisis, como indica en sus logs:
> "Don't worry, we'll remove it after the analysis ends automatically!"

**Solución Fallida #1**: Crear el directorio antes del análisis
```yaml
# ❌ NO FUNCIONABA - El directorio se eliminaba
mkdir -p .horusec
chmod 755 .horusec
horusec start --json-output-file=".horusec/horusec-report.json"  # Se perdía
```

**Solución Fallida #2**: Crear el directorio con permisos especiales
```yaml
# ❌ TAMPOCO FUNCIONABA - Horusec lo eliminaba de todas formas
sudo mkdir -p .horusec
sudo chmod 755 .horusec
```

**Solución Final ✅**: Usar directorio separado que persista
```yaml
# ✅ FUNCIONA - Directorio que NO elimina Horusec
mkdir -p reports
horusec start --json-output-file="reports/horusec-report.json"
# Luego copiar para compatibilidad con scripts existentes
cp reports/horusec-report.json .horusec/horusec-report.json
```

**Lección**: Leer TODA la documentación y logs de las herramientas. Horusec tiene comportamientos específicos que no son obvios.

---

#### 🔥 **Problema 3: Permisos en GitHub Actions**
**Error**: `Permission denied` al crear directorios

**Causa**: Los runners de GitHub Actions tienen restricciones de permisos específicas.

**Solución**:
```yaml
# ✅ Permisos correctos para GitHub Actions
permissions:
  contents: read
  security-events: write  # Necesario para reportes de seguridad
  actions: read
```

**Lección**: GitHub Actions requiere permisos explícitos para ciertas operaciones.

---

### Proceso de Debugging Recomendado

Basado en nuestra experiencia de 4 horas, recomendamos este proceso:

1. **🔍 Leer logs completos** - No solo el error final, sino todo el contexto
2. **📋 Verificar comportamiento de herramientas** - Muchas eliminan archivos automáticamente
3. **🧪 Probar localmente primero** - `docker run` antes de GitHub Actions
4. **📝 Documentar cada intento** - Evita repetir soluciones fallidas
5. **🚀 Implementar en etapas** - Un problema a la vez

### Herramientas de Debugging para GitHub Actions

```yaml
# Mostrar estructura de directorios
- name: Debug - Show directory structure  
  run: |
    echo "=== Current directory ==="
    pwd
    echo "=== Directory contents ==="
    ls -la
    echo "=== .horusec directory ==="
    ls -la .horusec/ || echo "Directory doesn't exist"

# Verificar variables de entorno
- name: Debug - Show environment
  run: env | grep HORUSEC

# Verificar permisos
- name: Debug - Check permissions
  run: |
    whoami
    groups
    ls -la $(dirname $(which horusec))
```

### Otros Problemas Comunes

1. **Error "Invalid JSON"**
   - Verificar permisos de escritura en directorios de salida
   - Comprobar que el contenedor no se queda sin espacio

2. **Servicios no conectan (Docker Compose)**
   - Verificar que PostgreSQL y RabbitMQ están healthy
   - Revisar logs: `docker-compose logs [servicio]`

3. **Umbrales siempre fallan**  
   - Verificar variables de entorno están configuradas
   - Revisar sintaxis del script de validación

4. **Workflow no se ejecuta**
   - Verificar que la rama trigger es correcta
   - Comprobar permisos de Actions en el repositorio

### Logs Útiles
```bash
# CI/CD
docker-compose -f docker-compose.horusec.yml logs -f

# Plataforma completa
docker-compose -f docker-compose.horusec-platform.yml logs horusec-api
docker-compose -f docker-compose.horusec-platform.yml logs postgres
```

---

💡 **Para más información**, consulta el archivo principal [`DOCKER_SETUP.md`](./DOCKER_SETUP.md)
