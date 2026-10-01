#!/usr/bin/env bash
# auditor_ssh.sh - Detecta IPs con intentos de fuerza bruta SSH en un log.
# Uso: ./auditor_ssh.sh [-u umbral] [-f ruta_log] [-b] [-h]
# Autor: 10159172 - Wagner Peter
set -uo pipefail

echo "Matricula: 10159172 - Nombre: Wagner Peter"

UMBRAL=5
LOG="$HOME/lab-so/registros/auth.log"
BLOQUEAR=0

mostrar_ayuda() {
    echo "Uso: $0 [-u umbral] [-f ruta_log] [-b] [-h]"
    echo "  -u N   Umbral de intentos fallidos (por defecto 5)"
    echo "  -f ruta  Archivo de log a analizar (por defecto ~/lab-so/registros/auth.log)"
    echo "  -b     Escribe la lista de IPs a bloquear en ~/lab-so/salidas/bloqueo.txt"
    echo "  -h     Muestra esta ayuda y termina"
}

while getopts "u:f:bh" opt; do
    case "$opt" in
        u) UMBRAL="$OPTARG" ;;
        f) LOG="$OPTARG" ;;
        b) BLOQUEAR=1 ;;
        h) mostrar_ayuda; exit 0 ;;
        *) echo "Opcion invalida." >&2; mostrar_ayuda >&2; exit 2 ;;
    esac
done

if [ ! -r "$LOG" ]; then
    echo "Error: no se puede leer el archivo '$LOG'." >&2
    exit 2
fi

mkdir -p "$HOME/lab-so/salidas"

RESULTADO=$(grep "Failed password" "$LOG" \
    | awk '{for(i=1;i<=NF;i++) if ($i=="from") print $(i+1)}' \
    | sort | uniq -c | sort -rn \
    | awk -v u="$UMBRAL" '$1 > u {print $2, $1}')

if [ -z "$RESULTADO" ]; then
    echo "No se encontraron IPs que superen el umbral de $UMBRAL intentos fallidos."
    exit 0
fi

echo "IPs que superan el umbral de $UMBRAL intentos fallidos:"
echo "$RESULTADO" | while read -r ip fallos; do
    usuarios=$(grep "Failed password" "$LOG" | grep "$ip" | awk '{for(i=1;i<=NF;i++) if ($i=="user") print $(i+1)}' | sort -u | tr '\n' ',' | sed 's/,$//')
    echo "  $ip -> $fallos intentos (usuarios probados: $usuarios)"
done

if [ "$BLOQUEAR" -eq 1 ]; then
    echo "$RESULTADO" | awk '{print $1}' > "$HOME/lab-so/salidas/bloqueo.txt"
    echo "Lista de IPs a bloquear escrita en ~/lab-so/salidas/bloqueo.txt"
fi

exit 1
