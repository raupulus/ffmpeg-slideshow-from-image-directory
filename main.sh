#!/bin/bash

infoFile=$(pwd)/info.txt
echo "" > $infoFile

interval=6
fps=30
#resolution=1920x1080
resolution=4096x2304
workPath=$(pwd)/example
outPath=$(pwd)/out

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


## TODO: Aceptar parámetros de entrada al ejecutar el comando:
## -i <interval> -f <fps> -r <resolution> -p <path> -o <outPath> -h <help>


images=$(ls $workPath | grep -e "\.jpg" -e "\.png" | grep -v -i "title\.[png|jpg]")


echo ""
echo ""
echo "Imagen de título: $titleFile"
echo ""
echo "Imagenes a procesar:"
echo "$images"
echo "width: $width"
echo "height: $height"

imagesFullPath=$(ls $workPath | grep -e "\.jpg" -e "\.png" | grep -v -i "title\.[png|jpg]" | sed "s:^:$workPath/:g")

counter=0
transitions=""
concat=""

if [[ ! -z $titleFile ]]; then
    transitions+="[0:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=4:d=1[v0];"
    concat="[v0]"

    echo "file $workPath/$titleFile" >> $infoFile
    echo "duration 2" >> $infoFile

    counter=1
fi



for image in $imagesFullPath; do

    if [[ $counter -eq 0 ]]; then
        transitions+="[0:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=4:d=1[v0];"
        concat="[v0]"
    else
        transitions+="[$counter:v]scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v$counter];"
        concat+="[v$counter]"
    fi

    echo "file $image" >> $infoFile
    echo "duration $interval" >> $infoFile

    counter=$((counter+1))
done

concat+="concat=n=$counter:v=1:a=0,format=yuv420p[v]"


## TODO: Procesar parámetros, transiciones, etc

echo "Entrada: $workPath"
echo "Salida: $outPath/out.mp4"

#$(command $outPath/out.mp4)


echo "counter: $counter"
echo "transitions: $transitions"
echo "concat: $concat"


ffmpeg -f concat -safe 0 -i $infoFile  -c:v libx264 -r 30 -pix_fmt yuv420p $outPath/out.mp4


#ffmpeg -framerate 1/5 -f concat -i $infoFile vsync vfr -c:v libx264 -r 30 -pix_fmt yuv420p $outPath/out.mp4


#ffmpeg -framerate 1/5 -i img%03d.png -c:v libx264 -r 30 -pix_fmt yuv420p out.mp4


#[0:v]scale=4096:2304:force_original_aspect_ratio=decrease,pad=4096:2304:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=out:st=4:d=1[v0];

#[1:v]scale=4096:2304:force_original_aspect_ratio=decrease,pad=4096:2304:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v1];

#[2:v]scale=4096:2304:force_original_aspect_ratio=decrease,pad=4096:2304:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v2];[3:v]scale=4096:2304:force_original_aspect_ratio=decrease,pad=4096:2304:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v3];[4:v]scale=4096:2304:force_original_aspect_ratio=decrease,pad=4096:2304:(ow-iw)/2:(oh-ih)/2,setsar=1,fade=t=in:st=0:d=1,fade=t=out:st=4:d=1[v4];

#[v0][v1][v2][v3][v4]concat=n=5:v=1:a=0,format=yuv420p[v]
