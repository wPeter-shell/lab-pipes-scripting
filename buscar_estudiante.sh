#!/usr/bin/env bash
# buscar_estudiante.sh - Menu interactivo de consulta sobre estudiantes.csv
# Uso: ./buscar_estudiante.sh
# Autor: 10159172 - Wagner Peter
# Nota: no se usa 'set -e' porque el script debe tolerar opciones invalidas
# y busquedas vacias sin terminar abruptamente.
set -uo pipefail

echo "Matricula: 10159172 - Nombre: Wagner Peter"

CSV="$HOME/lab-so/datos/estudiantes.csv"

buscar_por_nombre() {
    read -rp "Texto a buscar en el nombre: " texto
    if [ -z "$texto" ]; then
        echo "Busqueda vacia, no se aplico ningun filtro." >&2
        return
    fi
    awk -F',' -v t="$texto" 'NR>1 && tolower($2) ~ tolower(t) {print $1, $2, $3, $5}' "$CSV"
}

listar_por_carrera() {
    read -rp "Carrera (ICC/ISC/ITT): " carrera
    awk -F',' -v c="$carrera" 'NR>1 && $3==c {print $1, $2, $5}' "$CSV" | sort -k3 -rn
}

estadisticas_por_carrera() {
    awk -F',' 'NR>1 {
        suma[$3]+=$5; cuenta[$3]++
        if ($5+0 > max[$3]+0) { max[$3]=$5; nombre_max[$3]=$2 }
    } END {
        for (c in suma)
            printf "%s: promedio=%.3f cantidad=%d mejor=%s (%.2f)\n", c, suma[c]/cuenta[c], cuenta[c], nombre_max[c], max[c]
    }' "$CSV"
}

while true; do
    echo ""
    echo "1) Buscar por nombre"
    echo "2) Listar por carrera"
    echo "3) Estadisticas por carrera"
    echo "4) Salir"
    read -rp "Elija una opcion: " opcion
    case "$opcion" in
        1) buscar_por_nombre ;;
        2) listar_por_carrera ;;
        3) estadisticas_por_carrera ;;
        4) echo "Saliendo."; exit 0 ;;
        *) echo "Opcion invalida, intente de nuevo." >&2 ;;
    esac
done
