#!/bin/bash

save_ifs=$IFS

scriptPath=$(dirname $(realpath $0))
galleryPath=$1
outPath=$2

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
    "${scriptPath}/main.sh" -i=8 -p="${dir}" -o="${outPath}" -n="${dirName}.mp4" -f=60 -c=hevc_videotoolbox -q=23 -y

    if [[ $? -ne 0 ]]; then
        ((errors++))
    fi

    ((counter++))

done

IFS="$save_ifs"

echo "Videos generados: $(($counter - $errors)) de $counter."
echo "Errores: $errors"

exit 0
