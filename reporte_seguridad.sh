#!/usr/bin/env bash
# reporte_seguridad.sh - Correlaciona web+SSH+inventario y genera informe Markdown.
# Uso: ./reporte_seguridad.sh [umbral]
# Autor: 10159172 - Wagner Peter
set -uo pipefail

echo "Matricula: 10159172 - Nombre: Wagner Peter"

UMBRAL="${1:-4}"
ACCESO="$HOME/lab-so/registros/acceso.log"
AUTH="$HOME/lab-so/registros/auth.log"
INVENTARIO="$HOME/lab-so/datos/inventario.json"
SALIDAS="$HOME/lab-so/salidas"

for f in "$ACCESO" "$AUTH" "$INVENTARIO"; do
    if [ ! -r "$f" ]; then
        echo "Error: no se puede leer la fuente de datos '$f'." >&2
        exit 2
    fi
done

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq no esta instalado." >&2
    exit 4
fi

mkdir -p "$SALIDAS"
INFORME="$SALIDAS/informe-$(date +%Y%m%d).md"

# --- Fuente 1: trafico web ---
TOTAL=$(wc -l < "$ACCESO")
IPS_DISTINTAS=$(awk '{print $1}' "$ACCESO" | sort -u | wc -l)
ERR4XX=$(awk '$9>=400 && $9<500' "$ACCESO" | wc -l)
ERR5XX=$(awk '$9>=500 && $9<600' "$ACCESO" | wc -l)
TRAFICO_MB=$(awk '{s+=$10} END{printf "%.2f", s/1024/1024}' "$ACCESO")

# --- Fuente 2: fuerza bruta SSH ---
SSH_CONTEO=$(grep "Failed password" "$AUTH" | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | sort | uniq -c | sort -rn)

# --- IPs con fuerza bruta (superan umbral en auth.log) ---
mapfile -t IPS_SSH < <(echo "$SSH_CONTEO" | awk -v u="$UMBRAL" '$1>u {print $2}')

# --- IPs con muchos 4xx/5xx en acceso.log (superan umbral) ---
mapfile -t IPS_WEB < <(awk '$9>=400' "$ACCESO" | awk '{print $1}' | sort | uniq -c | awk -v u="$UMBRAL" '$1>u {print $2}')

# --- Interseccion: concatenar, ordenar, y uniq -d deja solo lo repetido en ambas listas ---
IPS_CORRELACIONADAS=$( (printf "%s\n" "${IPS_SSH[@]}"; printf "%s\n" "${IPS_WEB[@]}") | sort | uniq -d)

{
    echo "# Informe de seguridad - $(date +%Y-%m-%d)"
    echo ""
    echo "Matricula: 10159172 - Nombre: Wagner Peter"
    echo "Umbral de eventos: $UMBRAL"
    echo ""
    echo "## 1. Resumen del trafico web"
    echo ""
    echo "| Peticiones totales | IPs distintas | Respuestas 4xx | Respuestas 5xx | Trafico (MB) |"
    echo "|---|---|---|---|---|"
    echo "| $TOTAL | $IPS_DISTINTAS | $ERR4XX | $ERR5XX | $TRAFICO_MB |"
    echo ""
    echo "## 2. Fuerza bruta SSH"
    echo ""
    echo '```'
    echo "$SSH_CONTEO"
    echo '```'
    echo ""
    echo "## 3. IPs correlacionadas"
    echo ""
    if [ -z "$IPS_CORRELACIONADAS" ]; then
        echo "No se detectaron IPs que superen el umbral simultaneamente en ambas fuentes."
    else
        echo "$IPS_CORRELACIONADAS" | while read -r ip; do
            USUARIOS=$(grep "Failed password" "$AUTH" | grep "$ip" | awk '{for(i=1;i<=NF;i++) if($i=="user") print $(i+1)}' | sort -u | tr '\n' ',' | sed 's/,$//')
            RUTAS=$(awk -v ip="$ip" '$1==ip && $9>=400 {print $7}' "$ACCESO" | sort -u | tr '\n' ',' | sed 's/,$//')
            echo "- **$ip**: usuarios SSH probados: $USUARIOS | rutas web rechazadas: $RUTAS"
        done
    fi
    echo ""
    echo "## 4. Activos potencialmente expuestos"
    echo ""
    echo "| Servidor | IP | Servicios |"
    echo "|---|---|---|"
    jq -r '.servidores[] | select(.activo==true) | "| \(.nombre) | \(.ip) | \(.servicios | join(", ")) |"' "$INVENTARIO"
} > "$INFORME"

echo "Informe generado en: $INFORME"

if [ -n "$IPS_CORRELACIONADAS" ] || [ "${#IPS_SSH[@]}" -gt 0 ]; then
    exit 1
fi
exit 0
