#!/usr/bin/env bash
# estado_sistema.sh - Panel de estado de la maquina (texto o JSON).
# Uso: ./estado_sistema.sh [--json]
# Autor: 10159172 - Wagner Peter
set -uo pipefail

MODO_JSON=0
if [ "${1:-}" = "--json" ]; then
    MODO_JSON=1
fi

ACTIVIDAD=$(uptime -p 2>/dev/null || uptime)
DISCO=$(df -h | awk 'NR==1 || ($5+0) > 70')
PROCESOS=$(ps aux --sort=-%mem | head -n 6 | tail -n 5 | awk '{print $11, $4"%"}')
USUARIOS=$(who | wc -l)
INTERFACES=$(ip -o -4 addr show | awk '{print $2, $4}')

if [ "$MODO_JSON" -eq 1 ]; then
    PROCESOS_JSON=$(echo "$PROCESOS" | awk '{printf "{\"comando\": \"%s\", \"memoria\": \"%s\"}\n", $1, $2}' | paste -sd, -)
    INTERFACES_JSON=$(echo "$INTERFACES" | awk '{printf "{\"interfaz\": \"%s\", \"ip\": \"%s\"}\n", $1, $2}' | paste -sd, -)
    echo "{"
    echo "  \"matricula\": \"10159172\","
    echo "  \"nombre\": \"Wagner Peter\","
    echo "  \"actividad\": \"$ACTIVIDAD\","
    echo "  \"usuarios_conectados\": $USUARIOS,"
    echo "  \"top_procesos\": [$PROCESOS_JSON],"
    echo "  \"interfaces\": [$INTERFACES_JSON]"
    echo "}"
else
    echo "Matricula: 10159172 - Nombre: Wagner Peter"
    echo "=== Estado del sistema ==="
    echo "Tiempo de actividad: $ACTIVIDAD"
    echo ""
    echo "Particiones con mas de 70% de uso:"
    echo "$DISCO"
    echo ""
    echo "Top 5 procesos por memoria:"
    echo "$PROCESOS"
    echo ""
    echo "Usuarios conectados: $USUARIOS"
    echo ""
    echo "Interfaces con direccion asignada:"
    echo "$INTERFACES"
fi
