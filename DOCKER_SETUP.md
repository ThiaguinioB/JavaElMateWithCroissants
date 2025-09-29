# 🐳 Docker Setup - Horusec Security Analysis Integration

## 📋 Descripción General

Este proyecto integra **Horusec CLI**, una herramienta de análisis de seguridad SAST (Static Application Security Testing), en el flujo de CI/CD usando Docker y GitHub Actions. Horusec escanea el código fuente en busca de vulnerabilidades de seguridad y proporciona reportes detallados.

## 🏗️ Arquitectura del Sistema

El setup incluye dos configuraciones principales:

1. **Análisis CI/CD** - Para integración continua con GitHub Actions
2. **Plataforma Completa** - Para desarrollo local con interfaz web

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions CI/CD                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   Trigger   │───▶│  Horusec CLI    │───▶│   Report    │  │
│  │ Push/PR     │    │  Docker         │    │ Validation  │  │
│  └─────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 Plataforma Local (Opcional)                 │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL ◄─┬─► Horusec Auth ◄─┬─► RabbitMQ              │
│               │                   │                         │
│  Horusec API ◄┘        Horusec Core ◄┘                     │
│      ▲                                                      │
│      │                                                      │
│  Horusec Manager (Web UI)                                   │
└─────────────────────────────────────────────────────────────┘
```

## 🗂️ Estructura de Archivos

```
├── .github/workflows/
│   └── horusec.yml                    # GitHub Actions workflow
├── docker-compose.horusec.yml         # Docker Compose para CI/CD
├── docker-compose.horusec-platform.yml # Docker Compose plataforma completa
├── Dockerfile.horusec                 # Dockerfile personalizado para Horusec
├── horusec-config.json               # Configuración de Horusec CLI
├── validate_thresholds.sh            # Script de validación de umbrales
└── init-databases.sql                # Script de inicialización de BD
```

## 🚀 Configuración Rápida

### 1. Análisis CI/CD Básico

Para habilitar el análisis de seguridad en tu pipeline:

```bash
# El workflow se ejecuta automáticamente en:
# - Push a la rama 'docker-compose/horusec'
# - Pull requests a 'main'

# Para ejecutar manualmente:
docker-compose -f docker-compose.horusec.yml up --build
```

### 2. Plataforma Completa (Desarrollo Local)

```bash
# Configurar variables de entorno
export HORUSEC_JWT_SECRET="tu-secret-jwt-super-seguro"
export HORUSEC_MANAGER_URL="http://localhost:8043"

# Levantar todos los servicios
docker-compose -f docker-compose.horusec-platform.yml up -d

# Acceder a la interfaz web
open http://localhost:8043
```

## ⚙️ Configuración Detallada

### Variables de Entorno

#### Para CI/CD (`docker-compose.horusec.yml`)
```bash
# Umbrales de vulnerabilidades (opcional)
HORUSEC_MAX_CRITICAL_VULNERABILITY=0    # Máximo críticas permitidas
HORUSEC_MAX_HIGH_VULNERABILITY=5        # Máximo altas permitidas  
HORUSEC_MAX_MEDIUM_VULNERABILITY=10     # Máximo medias permitidas
HORUSEC_MAX_LOW_VULNERABILITY=20        # Máximo bajas permitidas
```

#### Para Plataforma Completa (`docker-compose.horusec-platform.yml`)
```bash
# Base de datos
POSTGRES_USER=horusec
POSTGRES_PASSWORD=horusec
POSTGRES_DB=horusec_db

# Horusec
HORUSEC_TAG=v2.17.3                    # Versión de Horusec
HORUSEC_JWT_SECRET=tu-secret-jwt       # Secret para JWT
HORUSEC_MANAGER_URL=http://localhost:8043

# Usuario default (desarrollo)
# Username: dev
# Email: dev@example.com  
# Password: Devpass0*
```

### Configuración de Horusec (`horusec-config.json`)

```json
{
    "horusecCliWorkDir": "./",
    "horusecCliSeveritiesToIgnore": ["LOW", "MEDIUM"],
    "horusecCliEnableGitHistory": false
}
```

**Parámetros explicados:**
- `horusecCliWorkDir`: Directorio de trabajo para el análisis
- `horusecCliSeveritiesToIgnore`: Severidades a ignorar en el reporte
- `horusecCliEnableGitHistory`: Habilitar análisis del historial de Git

## 🔧 Comandos Útiles

### Análisis Local
```bash
# Ejecutar análisis único
docker-compose -f docker-compose.horusec.yml up --build

# Ver logs del análisis
docker-compose -f docker-compose.horusec.yml logs -f

# Limpiar contenedores y volúmenes
docker-compose -f docker-compose.horusec.yml down -v
```

### Plataforma Completa
```bash
# Iniciar servicios en background
docker-compose -f docker-compose.horusec-platform.yml up -d

# Ver estado de servicios
docker-compose -f docker-compose.horusec-platform.yml ps

# Ver logs de un servicio específico
docker-compose -f docker-compose.horusec-platform.yml logs horusec-api

# Parar todos los servicios
docker-compose -f docker-compose.horusec-platform.yml down
```

### Debugging
```bash
# Acceder al contenedor de Horusec CLI
docker run -it --rm -v $(pwd):/src horuszup/horusec-cli:v2.9.0-beta.3 sh

# Ejecutar Horusec manualmente
docker run --rm -v $(pwd):/src horuszup/horusec-cli:v2.9.0-beta.3 \
  horusec start -p /src --output-format json
```

## 📊 Interpretación de Resultados

### Niveles de Severidad
- **CRITICAL** 🔴: Vulnerabilidades críticas que requieren atención inmediata
- **HIGH** 🟠: Vulnerabilidades importantes que deben corregirse pronto  
- **MEDIUM** 🟡: Vulnerabilidades moderadas para revisar
- **LOW** 🟢: Vulnerabilidades menores o informativas

### Formato del Reporte
```json
{
  "analysisVulnerabilities": [
    {
      "vulnerabilities": {
        "file": "src/main/java/Example.java",
        "line": "42",
        "severity": "HIGH", 
        "confidence": "HIGH",
        "rule_id": "HS-JAVA-1",
        "details": "Descripción de la vulnerabilidad",
        "code": "código problemático"
      }
    }
  ]
}
```

## 🚨 Resolución de Problemas

### Problemas Comunes

#### 1. Error "Invalid JSON in output file"
```bash
# Verificar que el contenedor tenga permisos de escritura
chmod 755 .horusec/
```

#### 2. "Vulnerability threshold exceeded"
```bash
# Ajustar los umbrales en variables de entorno o
# Revisar y corregir las vulnerabilidades encontradas
```

#### 3. Servicios no pueden conectarse (plataforma completa)
```bash
# Verificar que todos los servicios estén corriendo
docker-compose -f docker-compose.horusec-platform.yml ps

# Reiniciar servicios con dependencias
docker-compose -f docker-compose.horusec-platform.yml restart
```

#### 4. Puerto ya en uso
```bash
# Cambiar puertos en docker-compose.yml o
# Liberar puertos ocupados
sudo lsof -ti:8043 | xargs kill -9
```

### Logs de Debugging
```bash
# CI/CD
docker-compose -f docker-compose.horusec.yml logs

# Plataforma completa  
docker-compose -f docker-compose.horusec-platform.yml logs [servicio]
```

## 🔐 Consideraciones de Seguridad

1. **Secretos**: Nunca commitear secretos reales en el repositorio
2. **Umbrales**: Configurar umbrales apropiados según el contexto del proyecto
3. **Acceso**: Restringir acceso a la plataforma web en producción
4. **Actualizaciones**: Mantener Horusec actualizado regularmente

## 📚 Referencias

- [Horusec Documentation](https://horusec.io/docs/)
- [Horusec CLI](https://github.com/ZupIT/horusec)
- [Docker Compose](https://docs.docker.com/compose/)
- [GitHub Actions](https://docs.github.com/en/actions)

## 🤝 Contribuir

Para contribuir al setup de seguridad:

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/security-improvement`)
3. Commit tus cambios (`git commit -am 'Add security improvement'`)
4. Push a la rama (`git push origin feature/security-improvement`)  
5. Crea un Pull Request

---

💡 **Tip**: Para una configuración más avanzada, revisa la documentación individual de cada archivo en este directorio.
