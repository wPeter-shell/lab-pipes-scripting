#!/usr/bin/env bash
# resumen_log.sh - Genera un informe resumido de un log de acceso web.
# Uso: ./resumen_log.sh <ruta_log> [top_n]
# Autor: 10159172 - Wagner Peter
set -euo pipefail

echo "Matricula: 10159172 - Nombre: Wagner Peter"

if [ $# -lt 1 ]; then
    echo "Error: debe indicar la ruta del log. Uso: $0 <ruta_log> [top_n]" >&2
    exit 1
fi

LOG="$1"
TOP_N="${2:-5}"

if [ ! -e "$LOG" ]; then
    echo "Error: el archivo '$LOG' no existe." >&2
    exit 2
fi

if [ ! -r "$LOG" ]; then
    echo "Error: el archivo '$LOG' existe pero no es legible." >&2
    exit 3
fi

TOTAL=$(wc -l < "$LOG")
IPS_DISTINTAS=$(awk '{print $1}' "$LOG" | sort -u | wc -l)
ERRORES=$(awk '$9 >= 400' "$LOG" | wc -l)
PORCENTAJE=$(awk -v e="$ERRORES" -v t="$TOTAL" 'BEGIN{printf "%.2f", (e/t)*100}')
TRAFICO_MB=$(awk '{suma+=$10} END{printf "%.2f", suma/1024/1024}' "$LOG")

echo "Total de peticiones: $TOTAL"
echo "IPs distintas: $IPS_DISTINTAS"
echo "Respuestas >=400: $ERRORES ($PORCENTAJE%)"
echo "Trafico total: ${TRAFICO_MB} MB"
echo ""
echo "Ranking de las $TOP_N IPs mas activas:"
awk '{print $1}' "$LOG" | sort | uniq -c | sort -rn | head -n "$TOP_N"
echo ""
echo "Distribucion completa de codigos de estado:"
awk '{print $9}' "$LOG" | sort | uniq -c | sort -rn

