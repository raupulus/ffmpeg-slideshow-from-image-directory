# ffmpeg-slideshow-from-image-directory

## Script Global (Opciones Linux/MacOS)

Puedes enlazar el script a tu PATH para poder ejecutarlo desde cualquier directorio.

Tambié puedes crear un alias en tu .bashrc o .zshrc

```bash
alias imageToSlide="$HOME/git/ffmpeg-slideshow-from-image-directory/main.sh"
```

Según lo que necesites puedes elegir una de las opciones anteriores.

## Música

Puedes añadir música a los vídeos.

Para tener música, crea un directorio en la raíz del proyecto llamado `music` y añade ahí los archivos de música.

Los formatos admitidos son **mp3** **wav** y **ogg**.

La música será seleccionada de forma aleatoria para cada vídeo.

## Uso

```bash
imageToSlide -p <directorio de imágenes> -o <directorio de salida> -n <nombre de salida>
```

## Errores conocidos o cosas aún no implementadas

- Los archivos de música no pueden tener espacios en el nombre ni carácteres extraños.
- Los archivos de imágenes no pueden tener espacios en el nombre ni carácteres extraños.
