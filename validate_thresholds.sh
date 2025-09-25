#!/bin/sh

FILE="/src/.horusec/output.json"

# Check if the file exists and is not empty
if [ ! -s "$FILE" ]; then
  echo "❌ Output file is empty or missing: $FILE"
  exit 1
fi

# Check if the file contains valid JSON
if ! jq empty "$FILE" > /dev/null 2>&1; then
  echo "❌ Invalid JSON in $FILE"
  cat "$FILE"
  exit 1
fi

# Check if analysisVulnerabilities exists and is not null
if [ "$(jq -r '.analysisVulnerabilities == null' "$FILE")" = "true" ]; then
  echo "ℹ️ No analysisVulnerabilities found (null). Assuming no issues."
  exit 0
fi

# Threshold configuration
MAX_CRITICAL="${HORUSEC_MAX_CRITICAL_VULNERABILITY}"
MAX_HIGH="${HORUSEC_MAX_HIGH_VULNERABILITY}"
MAX_MEDIUM="${HORUSEC_MAX_MEDIUM_VULNERABILITY}"
MAX_LOW="${HORUSEC_MAX_LOW_VULNERABILITY}"

# Count vulnerabilities by severity
CRITICAL=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "CRITICAL")] | length' "$FILE")
HIGH=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "HIGH")] | length' "$FILE")
MEDIUM=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "MEDIUM")] | length' "$FILE")
LOW=$(jq '[.analysisVulnerabilities[] | select(.vulnerabilities.severity == "LOW")] | length' "$FILE")
TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

# Print each vulnerability with full details
jq -c '.analysisVulnerabilities[]' "$FILE" | while read -r vuln; do
  echo "==============================================="
  echo "File: $(echo "$vuln" | jq -r '.vulnerabilities.file')"
  echo "Line: $(echo "$vuln" | jq -r '.vulnerabilities.line')"
  echo "Severity: $(echo "$vuln" | jq -r '.vulnerabilities.severity')"
  echo "Confidence: $(echo "$vuln" | jq -r '.vulnerabilities.confidence')"
  echo "Rule ID: $(echo "$vuln" | jq -r '.vulnerabilities.rule_id')"
  echo "Security Tool: $(echo "$vuln" | jq -r '.vulnerabilities.securityTool')"
  echo "Language: $(echo "$vuln" | jq -r '.vulnerabilities.language')"
  echo "Code: $(echo "$vuln" | jq -r '.vulnerabilities.code')"
  echo "Details: $(echo "$vuln" | jq -r '.vulnerabilities.details')"
  echo "==============================================="
done

# Print formatted vulnerability summary
echo "==============================================="
echo "In this analysis, a total of $TOTAL possible vulnerabilities were found and we classified them as:"
echo
echo "Total of Vulnerability CRITICAL is: $CRITICAL"
echo "Total of Vulnerability HIGH is: $HIGH"
echo "Total of Vulnerability MEDIUM is: $MEDIUM"
echo "Total of Vulnerability LOW is: $LOW"
echo "==============================================="

# Print thresholds
echo "CRITICAL: $CRITICAL (max $MAX_CRITICAL)"
echo "HIGH: $HIGH (max $MAX_HIGH)"
echo "MEDIUM: $MEDIUM (max $MAX_MEDIUM)"
echo "LOW: $LOW (max $MAX_LOW)"

# Check thresholds
if [ "$CRITICAL" -gt "$MAX_CRITICAL" ] || [ "$HIGH" -gt "$MAX_HIGH" ] || [ "$MEDIUM" -gt "$MAX_MEDIUM" ] || [ "$LOW" -gt "$MAX_LOW" ]; then
  echo "❌ Vulnerability threshold exceeded!"
  exit 1
else
  echo "✅ Vulnerabilities within allowed limits."
  exit 0
fi