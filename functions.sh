#!/bin/bash

##
## Busca en el directorio de música un archivo de audio.
##
## @param $1 Directorio de música
##
## @return Ruta del archivo de audio
##
function searchMusic() {
    if [[ -z $1 ]]; then
        #echo 'Error: No se especificó el directorio de música.'
        return 1
    fi

    if [[ ! -d $1 ]]; then
        #echo 'Warning: El directorio de música no existe.'
        return 1
    fi

    local randomFile=$(find $1 -type f -name '*.mp3' -o -name '*.wav' -o -name '*.ogg' | shuf -n 1 2> /dev/null)

    if [[ -z $randomFile ]]; then
        #echo 'Error: No se encontró ningún archivo de audio en el directorio de música.'
        return 1
    fi

    echo $randomFile
}

##
## Imprime la ayuda del script.
## -i <interval> -r <resolution> -p <path> -o <outPath> -y <overwrite> -h <help>
##
function printMenuHelp() {
    echo ""
    echo ""
    echo "Usage: ./main.sh [options]"
    echo ""
    echo "Options:"
    echo "  -i=<interval>       Interval between images in seconds"
    echo "  -r=<resolution>     Resolution of the output video (Default 4096x2304)"
    echo "  -p=<path>           Path of the images (Default current path)"
    echo "  -o=<outPath>        Path of the output video (Default current path + /out/out.mp4)"
    echo "  -y                  Overwrite output video if exists"
    echo "  -h                  Show this help"
    echo ""
    exit 0
}
