#!/bin/bash

infoFile=$(pwd)/info.txt
echo "" > $infoFile

interval=6
resolution=4096x2304
workPath=$(pwd)/example
outPath=$(pwd)/out


overwrite=0

## Parámetros de entrada:
## -i <interval> -r <resolution> -p <path> -o <outPath> -y <overwrite> -h <help>

for param in $*; do
    order=$(echo $param | cut -d"=" -f1)
    value=$(echo $param | cut -d"=" -f2)

    if [[ $order = "-i" ]]; then
        if [[ $value -lt 1 ]]; then
            echo "Error: Interval must be greater than 0"
            exit 1
        fi

        interval=$value
    elif [[ $order = "-r" ]]; then
        resolution=$value
    elif [[ $order = "-p" ]]; then
        if [[ ! -d $value ]]; then
            echo "Error: Path not found ($value)"
            exit 1
        fi

        workPath=$value
    elif [[ $order = "-o" ]]; then
        if [[ ! -d $value ]]; then
            echo "Error: Path not found"
            exit 1
        fi

        outPath=$value
    elif [[ $order = "-y" ]]; then
        overwrite=1
    elif [[ $order = "-h" ]]; then
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
    fi
done

width=$(echo $resolution | cut -d"x" -f1)
height=$(echo $resolution | cut -d"x" -f2)

existFfmpeg=$(which ffmpeg > /dev/null; echo $?)

## Compruebo si está instalada la herramienta ffmpeg
if [[ $existFfmpeg -eq 1 ]]; then
    echo "Ffmpeg not found, install it and try again"
    exit 1
fi

if [[ ! -d $outPath ]]; then
    mkdir -p $outPath
fi

titleFile=$(ls $workPath | grep -i "title.png")

if [[ -z $titleFile ]]; then
    titleFile=$(ls $workPath | grep -i "title.jpg")
fi

#images=$(ls $workPath | grep -e "\.jpg" -e "\.png" | grep -v -i "title\.[png|jpg]")
imagesFullPath=$(ls $workPath | grep -e "\.jpg" -e "\.png" | grep -v -i "title\.[png|jpg]" | sed "s:^:$workPath/:g")


allImages=""
counter=0
transitions=""
concat=""

# Preparamos el título si existiera (Es Opcional)
if [[ ! -z $titleFile ]]; then
    transitions+="[0:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=4:d=1[v0];"
    concat="[v0]"

    echo "file $workPath/$titleFile" >> $infoFile
    echo "duration 2" >> $infoFile

    allImages="-loop 1 -t 2 -i $workPath/$titleFile"

    counter=1
fi

# Cantidad de imágenes a procesar
nImagesFullPath=$(echo $imagesFullPath | wc -w)

for image in $imagesFullPath; do

    if [[ $counter -eq 0 ]]; then
        transitions+="[0:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=4:d=1[v0];"
        concat="[v0]"
    elif [[ $counter -eq $nImagesFullPath ]]; then
        transitions+="[$counter:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1[v$counter];"
        concat+="[v$counter]"
    else
        transitions+="[$counter:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v$counter];"
        concat+="[v$counter]"
    fi

    echo "file $image" >> $infoFile
    echo "duration $interval" >> $infoFile

    counter=$((counter+1))

    allImages+=" -loop 1 -t $interval -i $image"
done

concat+="concat=n=$counter:v=1:a=0,format=yuv420p[v]"

echo "Directorio de entrada: $workPath"
echo "Directorio de Salida: $outPath/out.mp4"

sleep 1

if [[ $overwrite -eq 1 ]] && [[ -f $outPath/out.mp4 ]]; then
    rm -f $outPath/out.mp4
fi

ffmpeg $allImages -filter_complex "$transitions$concat" -map "[v]" -shortest $outPath/out.mp4

## El parámetro -map $counter:a es para que no de error al no encontrar audio
#ffmpeg -r $fps $allImages -filter_complex "$transitions$concat" -map "[v]" -map $counter:a -shortest $outPath/out.mp4
