#!/bin/bash

save_ifs=$IFS

scriptPath=$(dirname $(realpath $0))
galleryPath=$1
outPath=$2
interval=$3
resolution=$4
CODEC=hevc_videotoolbox
THREADS=0
FRAMERATE=60
QUALITY=23

if [[ -z "${interval}" ]]; then
    interval=8
fi

## Resolución del vídeo
if [[ -z "${resolution}" ]]; then
    resolution="3840x2160" # 4k por defecto
fi

if [[ -f "${scriptPath}/.env" ]]; then
    source "${scriptPath}/.env"
fi

if [[ -z "${galleryPath}" ]]; then
    echo 'Error: No se especificó el directorio de la galería.'
    exit 1
fi

if [[ ! -d "${galleryPath}" ]]; then
    echo 'Warning: El directorio de la galería no existe.'
    exit 1
fi

if [[ -z "${outPath}" ]]; then
    echo 'Error: No se especificó el directorio de salida.'
    exit 1
fi

if [[ ! -d "${outPath}" ]]; then
    echo 'Warning: El directorio de salida no existe.'
    exit 1
fi

## Busco todos los directorios de la galería
galleryDirs=$(find "${galleryPath}" -type d)

counter=0
errors=0

IFS="
"

## Recorro los directorios de la galería y genero un video por cada uno
for dir in $galleryDirs; do

    if [[ "${dir}" == "${galleryPath}" ]]; then
        continue
    fi

    ## Busco todas las imágenes del directorio
    images=$(find "${dir}" -type f -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' | sort)

    ## Si no hay imágenes, sigo con el siguiente directorio
    if [[ -z "${images}" ]]; then
        continue
    fi

    ## Si existe un archivo llamado ".processed" en el directorio, sigo con el siguiente directorio
    if [[ -f "${dir}/.processed" ]]; then
        continue
    fi

    ## Obtengo el nombre del directorio
    dirName=$(basename "${dir}")

    echo ""
    echo ""
    echo "Generando video de ${dirName}..."
    echo ""
    echo "Imágenes: ${images}"
    echo ""

    ## Genero el video
    "${scriptPath}/main.sh" -i="${interval}" -p="${dir}" -o="${outPath}" -n="${dirName}" -r="${resolution}" -f="${FRAMERATE}" -c="${CODEC}" -t="${THREADS}" -q="${QUALITY}" -y

    if [[ $? -ne 0 ]]; then
        ((errors++))
    fi

    ((counter++))

done

IFS="$save_ifs"

echo "Videos generados: $(($counter - $errors)) de $counter."
echo "Errores: $errors"

exit 0
