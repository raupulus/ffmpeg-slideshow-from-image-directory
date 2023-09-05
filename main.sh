#!/bin/bash

## Directorio del script
scriptPath=$(dirname $(realpath $0))

## Importo funciones auxiliares
source $scriptPath/functions.sh

## Directorio de música (Opcional, crea el directorio "music" y añade pistas mp3/wav/ogg si quieres música)
musicFile=$(searchMusic $scriptPath/music)

if [[ ! -d $scriptPath/tmp ]]; then
    mkdir -p $scriptPath/tmp
fi

infoFile=$scriptPath/tmp/info.txt
echo "" > $infoFile

## Intervalo entre imágenes en segundos
interval=6

## Resolución del vídeo
resolution=3840x2160

## Ruta de las imágenes
workPath=$scriptPath/example

## Ruta del vídeo de salida
outPath=""

## Nombre del vídeo de salida
outputName="out"

## Frames por segundo
fps=25

## Indica si sobrescribir el archivo de salida si existiera
overwrite=0

## Almaceno si está instalada la herramienta ffmpeg
existFfmpeg=$(which ffmpeg > /dev/null; echo $?)

## Compruebo si está instalada la herramienta ffmpeg
if [[ $existFfmpeg -eq 1 ]]; then
    echo "Ffmpeg not found, install it and try again"
    exit 1
fi

## Parámetros de entrada:
## -i <interval> -r <resolution> -p <path> -o <outPath> -n <name> -y <overwrite> -h <help>

for param in $*; do
    order=$(echo $param | cut -d"=" -f1)
    value=$(echo $param | cut -d"=" -f2)

    if [[ $order = "-i" ]]; then
        if [[ $value -lt 1 ]]; then
            echo "Error: Interval must be greater than 0"
            exit 1
        fi

        interval=$value
    elif [[ $order = "-n" ]]; then
        if [[ -z $value ]]; then
            echo "Error: Nombre incorrecto"
            exit 1
        fi

        outputName=$value
    elif [[ $order = "-r" ]]; then
        resolution=$value
    elif [[ $order = "-p" ]]; then
        if [[ ! -d $value ]]; then
            echo "Error: Images Path not found ($value)"
            exit 1
        fi

        workPath=$value
    elif [[ $order = "-o" ]]; then
        if [[ ! -d $value ]]; then
            echo "Error: Output Path not found ($value)"
            exit 1
        fi

        outPath=$value
    elif [[ $order = "-y" ]]; then
        overwrite=1

    elif [[ $order = "-f" ]]; then
        if [[ $value -lt 1 ]]; then
            echo "Error: FPS must be greater than 0"
            exit 1
        fi

        fps=$value
    elif [[ $order = "-h" ]]; then
        printMenuHelp
    fi
done

if [[ $* = "" ]]; then
    printMenuHelp
fi

## Ruta del vídeo de salida, si no se especifica se crea en el directorio actual de las imágenes
if [[ -z $outPath ]]; then
    outPath=$workPath/out
fi

## Compruebo si existe el directorio de salida, si no existe lo creo
if [[ ! -d $outPath ]]; then
    mkdir -p $outPath
fi

width=$(echo $resolution | cut -d"x" -f1)
height=$(echo $resolution | cut -d"x" -f2)

titleFile=$(ls $workPath | grep -i "title.png")

if [[ -z $titleFile ]]; then
    titleFile=$(ls $workPath | grep -i "title.jpg")
fi

## Almaceno todas las imágenes del directorio de trabajo con la ruta completa
imagesFullPath=$(ls $workPath | grep -e "\.jpg" -e "\.png" | grep -v -i "title\.[png|jpg]" | sed "s:^:$workPath/:g")

## Almaceno todas las imágenes preparadas para el comando ffmpeg
allImages=""

## Contador de imágenes totales
counter=0

## Transiciones entre imágenes (fade in/out)
transitions=""

## Concatenación de las transiciones
concat=""

# Preparamos el título si existiera (Es Opcional)
if [[ ! -z $titleFile ]]; then
    transitions+="[0:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=1.7:d=0.3[v0];"
    concat="[v0]"

    echo "file $workPath/$titleFile" >> $infoFile
    echo "duration 2" >> $infoFile

    allImages="-loop 1 -t 2 -i $workPath/$titleFile"

    counter=1
fi

# Cantidad de imágenes a procesar (Sin contar el título)
nImagesFullPath=$(echo $imagesFullPath | wc -w)

## Duración de las transiciones
transitionDuration=0.4
durationWithoutTransitions=$(echo "$interval - $transitionDuration" | bc)

for image in $imagesFullPath; do


    if [[ $counter -eq 0 ]]; then
        transitions+="[0:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=${durationWithoutTransitions}:d=${transitionDuration}[v0];"
        concat="[v0]"
    elif [[ $counter -eq $nImagesFullPath ]]; then
        transitions+="[$counter:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=${transitionDuration}[v$counter];"
        concat+="[v$counter]"
    else
        transitions+="[$counter:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=0.4,fade=t=out:st=${durationWithoutTransitions}:d=${transitionDuration}[v$counter];"
        concat+="[v$counter]"
    fi

    echo "file $image" >> $infoFile
    echo "duration $interval" >> $infoFile

    counter=$((counter+1))

    allImages+=" -loop 1 -t $interval -i $image"
done

## Añado la música si existe
if [[ ! -z $musicFile ]] && [[ -f $musicFile ]]; then
    allImages+=" -i ${musicFile}"
fi

concat+="concat=n=$counter:v=1:a=0,format=yuv420p[v]"

echo "Directorio de entrada: $workPath"
echo "Directorio de Salida: $outPath/${outputName}.mp4"
echo "Archivo de música: $musicFile"

sleep 1

## Compruebo si existe el archivo de salida, si existe lo borro
if [[ $overwrite -eq 1 ]] && [[ -f "${outPath}/${outputName}.mp4" ]]; then
    rm -f "${outPath}/${outputName}.mp4"
fi

## Calculo la duración total del vídeo
totalLength=$(echo "$interval * $nImagesFullPath" | bc)

if [[ ! -z $musicFile ]] && [[ -f $musicFile ]]; then
    totalLength=$(echo "$totalLength + 2" | bc)
fi

echo "ffmpeg $allImages -filter_complex \"$transitions$concat\" -map \"[v]\" -shortest $outPath/${outputName}.mp4"
#exit 0
if [[ ! -z $musicFile ]] && [[ -f $musicFile ]]; then
    ffmpeg $allImages -filter_complex "$transitions$concat" -map "[v]" -map ${counter}:a -r $fps -t $totalLength $outPath/${outputName}.mp4
else
    ffmpeg $allImages -filter_complex "$transitions$concat" -map "[v]" -shortest -r $fps "${outPath}/${outputName}.mp4"
fi

#ffmpeg $allImages -filter_complex "$transitions$concat" -map "[v]" -shortest $outPath/${outputName}.mp4


## El parámetro -map $counter:a es para que no de error al no encontrar audio
#ffmpeg -r $fps $allImages -filter_complex "$transitions$concat" -map "[v]" -map $counter:a -shortest $outPath/out.mp4


## Añado metadata al vídeo


## TODO: Probar música
## TODO: Comprobar si la música tiene un archivo de metadatos para añadirlo en el directorio de salida
## TODO: Añadir nombre del directorio de entrada al título del vídeo si no se especifica título
## TODO: Añadir al archivo de metadatos el nombre del directorio de entrada
## TODO: Crear archivo en blanco dentro del directorio de imágenes para indicar que se ha procesador ".processed"
## TODO: Crear archivo de metadatos en el directorio de salida con el nombre del vídeo
## TODO: Crear el vídeo en formato x265

#musicInfo=$(split -l 1 $infoFile)
