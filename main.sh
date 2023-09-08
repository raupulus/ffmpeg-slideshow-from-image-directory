#!/bin/bash
saveIFS=$IFS

## Nombre aleatorio de la carpeta temporal
tmp=$(mktemp -d)

mkdir -p "${tmp}/music"
mkdir -p "${tmp}/images"

## Directorio del script
scriptPath=$(dirname $(realpath $0))

## Importo funciones auxiliares
source $scriptPath/functions.sh

## Directorio de música (Opcional, crea el directorio "music" y añade pistas mp3/wav/ogg si quieres música)
musicFile=$(searchMusic $scriptPath/music)
musicFileName=$(basename $musicFile)
musicFileInfo=$scriptPath/music/$(echo $musicFileName | sed "s:\.: :g" | awk '{print $1}').txt

infoFile=${tmp}/info.txt
echo "" > $infoFile

## Intervalo entre imágenes en segundos
interval=6

## Resolución del vídeo
resolution=3840x2160

## Codec
codec="libx264" # libx265, hevc_videotoolbox, h264_videotoolbox

## Calidad
quality=31

## Ruta de las imágenes
workPath=$scriptPath/example

## Ruta del vídeo de salida
outPath=""

## Nombre del vídeo de salida
outputName="out"

## Frames por segundo
fps=25

## Parámetros de denoise (Suavizar vídeo)
#denoiseParameters="nlmeans=h=6:range=3:temporal=1"

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
    elif [[ $order = "-c" ]]; then
        codec=$value
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
allInputs=""

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

    allInputs="-loop 1 -t 2 -i ${workPath}/${titleFile}"

    img="${workPath}/${titleFile}"

    cp "${img}" "${tmp}/images/${titleFile}"

    tmpTitleFile="${tmp}/images/${titleFile}"

    allInputs=" -loop 1 -t 2 -i ${tmpTitleFile}"

    counter=1
fi

# Cantidad de imágenes a procesar (Sin contar el título)
nImagesFullPath=$(echo ${imagesFullPath} | wc -w)

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

    echo "file ${image}" >> $infoFile
    echo "duration ${interval}" >> $infoFile

    img="${image}"

    if [[ ! -f "${img}" ]]; then
        echo "Error: No se encontró la imagen $img"
        exit 1
    fi

    extension=$(echo "${img}" | rev | cut -d"." -f1 | rev)

    tmpImage="${tmp}/images/${counter}.${extension}"

    cp "${img}" "${tmpImage}"

    if [[ ! -f "${tmpImage}" ]]; then
        echo "Error: No se pudo copiar la imagen $img"
        exit 1
    fi

    ## Añado la imagen al array de imágenes
    allInputs+=" -loop 1 -t ${interval} -i $tmpImage"

    counter=$((counter+1))

done

## Añado la música si existe
if [[ ! -z $musicFile ]] && [[ -f $musicFile ]]; then
    allInputs+=" -i ${musicFile}"
fi

concat+="concat=n=$counter:v=1:a=0,format=yuv420p[v]"

## Compruebo si existe el archivo de salida, si existe lo borro
if [[ $overwrite -eq 1 ]] && [[ -f "${outPath}/${outputName}.mp4" ]]; then
    rm -f "${outPath}/${outputName}.mp4"
fi

## Compruebo si existe el archivo de metadatos para la salida, si existe lo borro
if [[ $overwrite -eq 1 ]] && [[ -f "${outPath}/${outputName}.txt" ]]; then
    rm -f "${outPath}/${outputName}.txt"
fi

## Calculo la duración total del vídeo
totalLength=$(echo "$interval * $nImagesFullPath" | bc)

if [[ ! -z $musicFile ]] && [[ -f $musicFile ]]; then
    totalLength=$(echo "$totalLength + 2" | bc)
fi

## Creo el vídeo
if [[ ! -z $musicFile ]] && [[ -f $musicFile ]]; then
    ffmpeg ${allInputs} -c:v $codec -crf $quality -preset slow -c:a aac -b:a 224k -filter_complex "${transitions}${concat}" -map "[v]" -map ${counter}:a -r $fps -t $totalLength "${outPath}/${outputName}.mp4"
else
    ffmpeg ${allInputs} -c:v $codec -crf $quality -preset slow -filter_complex "${transitions}${concat}" -map "[v]" -r $fps "${outPath}/${outputName}.mp4"
fi

videoCreated=$?

if [[ $videoCreated -eq 0 ]]; then
    echo ""
    echo "Video created successfully"
    echo ""

    outputFileInfo="${outPath}/${outputName}.txt"

    echo "Información del vídeo:" > $outputFileInfo
    echo "" >> $outputFileInfo
    echo "Resolución: $resolution" >> $outputFileInfo
    echo "Duración: ${totalLength}s" >> $outputFileInfo
    echo "FPS: $fps" >> $outputFileInfo
    echo "Codec: $codec" >> $outputFileInfo
    echo "Calidad: $quality" >> $outputFileInfo
    echo "" >> $outputFileInfo

    echo "Información de las imágenes:" >> $outputFileInfo
    echo "" >> $outputFileInfo
    echo "Intervalo: ${interval}s" >> $outputFileInfo
    echo "Nombre del directorio de las imágenes: $workPath" >> $outputFileInfo
    echo "Número de imágenes: $nImagesFullPath" >> $outputFileInfo
    echo "" >> $outputFileInfo


    ## Copio archivo de metadatos al directorio de salida del vídeo
    if [[ -f $workPath/info.txt ]]; then
        echo "" >> $outputFileInfo
        echo "Información del directorio de imágenes:" >> $outputFileInfo
        cat $workPath/info.txt >> $outputFileInfo
    elif [[ -f $workPath/info.md ]]; then
        echo "" >> $outputFileInfo
        echo "Información del directorio de imágenes:" >> $outputFileInfo
        cat $workPath/info.md >> $outputFileInfo
    fi

    ## Añado metadata de la música
    if [[ -z $musicFileInfo ]] && [[ -f $musicFileInfo ]]; then
        echo "" > $musicFileInfo
        echo "" > $musicFileInfo
        echo "Información de la música:" >> $musicFileInfo
        echo "" >> $musicFileInfo
        cat $musicFileInfo >> $outputFileInfo
    fi

    ## Metadatos de todas las imágenes procesadas
    if [[ -f $infoFile ]]; then
        echo "" >> $outputFileInfo
        echo "Información de las imágenes:" >> $outputFileInfo
        cat $infoFile >> $outputFileInfo
    fi

    ## Añado marca al directorio de entrada para indicar que se ha procesado (.processed)
    if [[ ! -f $workPath/.processed ]]; then
        touch $workPath/.processed
    fi
else
    echo ""
    echo "Error creating video"
    echo ""
    exit 1
fi


## Borro el directorio temporal
echo "Borrando directorio temporal..."
echo "${tmp}"
ls "${tmp}"
#rm -rf "${tmp}"
