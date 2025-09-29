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

### Problemas Comunes

1. **Error "Invalid JSON"**
   - Verificar permisos de escritura en `.horusec/`
   - Comprobar que el contenedor no se queda sin espacio

2. **Servicios no conectan**
   - Verificar que PostgreSQL y RabbitMQ están healthy
   - Revisar logs: `docker-compose logs [servicio]`

3. **Umbrales siempre fallan**  
   - Verificar variables de entorno están configuradas
   - Revisar sintaxis del script de validación

4. **GitHub Actions falla**
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
