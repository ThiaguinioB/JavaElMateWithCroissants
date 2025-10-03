#!/bin/sh

# 🛡️ Script de Validación de Umbrales de Vulnerabilidades para Horusec
#
# Este script procesa el reporte JSON generado por Horusec CLI y:
# 1. Valida que el archivo de reporte existe y contiene JSON válido
# 2. Cuenta vulnerabilidades por nivel de severidad
# 3. Muestra detalles completos de cada vulnerabilidad encontrada
# 4. Compara los resultados contra umbrales configurados
# 5. Falla el build si se exceden los límites permitidos
#
# Variables de entorno utilizadas:
# - HORUSEC_MAX_CRITICAL_VULNERABILITY: Máximo de vulnerabilidades críticas
# - HORUSEC_MAX_HIGH_VULNERABILITY: Máximo de vulnerabilidades altas
# - HORUSEC_MAX_MEDIUM_VULNERABILITY: Máximo de vulnerabilidades medias  
# - HORUSEC_MAX_LOW_VULNERABILITY: Máximo de vulnerabilidades bajas
#
# Códigos de salida:
# - 0: Éxito (vulnerabilidades dentro de los límites)
# - 1: Error (archivo inválido o umbrales excedidos)

# 📁 Archivo de reporte generado por Horusec CLI
FILE="/src/.horusec/output.json"

# ✅ Validación 1: Verificar que el archivo existe y no está vacío
if [ ! -s "$FILE" ]; then
  echo "❌ Output file is empty or missing: $FILE"
  exit 1
fi

# ✅ Validación 2: Verificar que el archivo contiene JSON válido
if ! jq empty "$FILE" > /dev/null 2>&1; then
  echo "❌ Invalid JSON in $FILE"
  cat "$FILE"
  exit 1
fi

# ✅ Validación 3: Verificar si existen vulnerabilidades para analizar
if [ "$(jq -r '.analysisVulnerabilities == null' "$FILE")" = "true" ]; then
  echo "ℹ️ No analysisVulnerabilities found (null). Assuming no issues."
  exit 0
fi

# 🎯 Configuración de umbrales desde variables de entorno
# Si no están definidas, se usan valores por defecto estrictos
MAX_CRITICAL="${HORUSEC_MAX_CRITICAL_VULNERABILITY:-1}"
MAX_HIGH="${HORUSEC_MAX_HIGH_VULNERABILITY:-0}"
MAX_MEDIUM="${HORUSEC_MAX_MEDIUM_VULNERABILITY:-6}"
MAX_LOW="${HORUSEC_MAX_LOW_VULNERABILITY:-10}"

# 📊 Conteo de vulnerabilidades por severidad usando jq
CRITICAL=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "CRITICAL")] | length' "$FILE")
HIGH=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "HIGH")] | length' "$FILE")
MEDIUM=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "MEDIUM")] | length' "$FILE")
LOW=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "LOW")] | length' "$FILE")
TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

# 📋 Mostrar detalles completos de cada vulnerabilidad encontrada
echo "🔍 DETALLES DE VULNERABILIDADES ENCONTRADAS:"
jq -c '.analysisVulnerabilities[]' "$FILE" | while read -r vuln; do
  echo "==============================================="
  echo "📁 File: $(echo "$vuln" | jq -r '.vulnerabilities.file')"
  echo "📍 Line: $(echo "$vuln" | jq -r '.vulnerabilities.line')"
  echo "🚨 Severity: $(echo "$vuln" | jq -r '.vulnerabilities.severity')"
  echo "🎯 Confidence: $(echo "$vuln" | jq -r '.vulnerabilities.confidence')"
  echo "🔑 Rule ID: $(echo "$vuln" | jq -r '.vulnerabilities.rule_id')"
  echo "🛠️ Security Tool: $(echo "$vuln" | jq -r '.vulnerabilities.securityTool')"
  echo "💻 Language: $(echo "$vuln" | jq -r '.vulnerabilities.language')"
  echo "📝 Code: $(echo "$vuln" | jq -r '.vulnerabilities.code')"
  echo "📖 Details: $(echo "$vuln" | jq -r '.vulnerabilities.details')"
  echo "==============================================="
done

# 📈 Resumen formateado de vulnerabilidades
echo "==============================================="
echo "📊 RESUMEN DEL ANÁLISIS DE SEGURIDAD"
echo "==============================================="
echo "En este análisis se encontraron $TOTAL posibles vulnerabilidades clasificadas como:"
echo
echo "🔴 Total de Vulnerabilidades CRÍTICAS: $CRITICAL"
echo "🟠 Total de Vulnerabilidades ALTAS: $HIGH"
echo "🟡 Total de Vulnerabilidades MEDIAS: $MEDIUM"
echo "🟢 Total de Vulnerabilidades BAJAS: $LOW"
echo "==============================================="

# 🎯 Mostrar umbrales configurados vs resultados
echo "🎯 VALIDACIÓN DE UMBRALES:"
echo "🔴 CRÍTICAS: $CRITICAL / $MAX_CRITICAL (máximo permitido)"
echo "🟠 ALTAS: $HIGH / $MAX_HIGH (máximo permitido)"
echo "🟡 MEDIAS: $MEDIUM / $MAX_MEDIUM (máximo permitido)"
echo "🟢 BAJAS: $LOW / $MAX_LOW (máximo permitido)"
echo "==============================================="

# 🚦 Validación final: Comparar contra umbrales y determinar éxito/fallo
if [ "$CRITICAL" -gt "$MAX_CRITICAL" ] || [ "$HIGH" -gt "$MAX_HIGH" ] || [ "$MEDIUM" -gt "$MAX_MEDIUM" ] || [ "$LOW" -gt "$MAX_LOW" ]; then
  echo "❌ ¡UMBRALES DE VULNERABILIDAD EXCEDIDOS!"
  echo "   El análisis de seguridad falló debido a que se encontraron más"
  echo "   vulnerabilidades de las permitidas por la política de seguridad."
  echo "   Por favor, revisa y corrige las vulnerabilidades antes de continuar."
  exit 1
else
  echo "✅ ANÁLISIS DE SEGURIDAD EXITOSO"
  echo "   Todas las vulnerabilidades están dentro de los límites permitidos."
  echo "   El código cumple con los estándares de seguridad configurados."
  exit 0
fi