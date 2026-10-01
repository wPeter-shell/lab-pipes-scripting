#!/usr/bin/env bash
# respaldo.sh - Empaqueta un directorio y gestiona la rotacion de copias.
# Uso: ./respaldo.sh <directorio_origen> [destino] [copias_a_conservar]
# Autor: 10159172 - Wagner Peter
set -uo pipefail

echo "Matricula: 10159172 - Nombre: Wagner Peter"

if [ $# -lt 1 ]; then
    echo "Error: debe indicar el directorio de origen. Uso: $0 <origen> [destino] [copias]" >&2
    exit 1
fi

ORIGEN="$1"
DESTINO="${2:-$HOME/lab-so/salidas/respaldos}"
COPIAS="${3:-3}"

if [ ! -d "$ORIGEN" ]; then
    echo "Error: el directorio '$ORIGEN' no existe." >&2
    exit 2
fi

mkdir -p "$DESTINO"

NOMBRE_DIR=$(basename "$ORIGEN")
MARCA=$(date +%Y%m%d-%H%M%S)
PAQUETE="$DESTINO/${NOMBRE_DIR}-${MARCA}.tar.gz"

tar -czf "$PAQUETE" -C "$(dirname "$ORIGEN")" "$NOMBRE_DIR"

if ! tar -tzf "$PAQUETE" >/dev/null 2>&1; then
    echo "Error: el paquete generado no se puede leer, eliminando." >&2
    rm -f "$PAQUETE"
    exit 3
fi

sha256sum "$PAQUETE" > "${PAQUETE}.sha256"

NUM_ARCHIVOS=$(tar -tzf "$PAQUETE" | wc -l)
TAMANO=$(du -h "$PAQUETE" | cut -f1)

echo "Paquete creado: $PAQUETE"
echo "Archivos incluidos: $NUM_ARCHIVOS"
echo "Tamano: $TAMANO"
echo "Suma de verificacion: ${PAQUETE}.sha256"

TOTAL_PAQUETES=$(ls -1t "$DESTINO/${NOMBRE_DIR}"-*.tar.gz 2>/dev/null | wc -l)
if [ "$TOTAL_PAQUETES" -gt "$COPIAS" ]; then
    ANTIGUOS=$(ls -1t "$DESTINO/${NOMBRE_DIR}"-*.tar.gz | tail -n +"$((COPIAS + 1))")
    echo "Eliminando paquetes antiguos (conservando $COPIAS):"
    echo "$ANTIGUOS" | while read -r f; do
        echo "  $f"
        rm -f "$f" "${f}.sha256"
    done
fi
