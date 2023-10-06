# ffmpeg-slideshow-from-image-directory

## Descrición

Script para crear vídeos de imágenes con ffmpeg incluyendo transiciones y música.

Esta herramienta está enfocada para linux y macos.

## Requisitos

La mayoría vienen por defecto en linux excepto ffmpeg, que se puede instalar con el gestor de paquetes de tu distribución. (sudo apt install ffmpeg)

En macos se puede instalar con brew, en este caso también es necesario instalar _coreutils_. (brew install coreutils ffmpeg)

- ffmpeg
- bash
- find
- bc
- coreutils
- sed
- wc
- grep
- cut

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

### Ejemplo con x265

```bash
imageToSlide -p=example -n=nombre-final -f=30 -y -c=libx265
```

### Ejemplo en macos por hardware con x265

```bash
imageToSlide -p=example -n=nombre-final -f=30 -y -c=hevc_videotoolbox
```

### Ejemplo en macos por hardware con x264

```bash
imageToSlide -p=example -n=nombre-final -f=30 -y -c=h264_videotoolbox
```

## Metadatos de salida

Estos metadatos se añaden en un archivo llamado igual que el vídeo pero con extensión `.txt`

Si en el directorio de las imágenes hay un archivo llamado `info.txt` o `info.md` se añadirá al archivo de metadatos de salida.

Si en el directorio para la música (music) hay un archivo llamado con el mismo nombre que la canción pero con extensión `.txt` se añadirá al archivo de metadatos de salida. Esto se hace para poder añadir información sobre la música como el autor o el título pero sobre todo para reconocer la autoría al subir el vídeo a cualquier plataforma.

También se añadirán al final de este archivo todas las imágenes utilizadas, esto es por que al usar Stable Diffusion las imágenes pueden llevar en el nombre tanto el número como información de las palabras clave para generarla y así poder buscarlas en el directorio de imágenes o usarlo para generar otras en el futuro como para cubrir información si se sube el vídeo a una plataforma.

## Procesado por lotes (Adicional Script)

El script **batch.sh** permite procesar todos los directorios de imágenes que contiene como primer nivel y crear los vídeos en el directorio de salida.

Este script recibe dos parámetros obligatorios en orden:

- Directorio que contiene los directorios de imágenes.
- Directorio de salida para todos los vídeos.

```bash
./batch.sh <directorio de imágenes> <directorio de salida>
```

Básicamente lo que hace es ejecutar el script principal por cada directorio de imágenes que encuentre en el directorio de imágenes.

Esto es útil para procesar por lotes todos los vídeos que tengas en un directorio fácilmente.

Se ignorarán los directorios que no contengan imágenes y los directorios que contengan el archivo oculto **.processed**.

## Ejemplo de salida

```bash
./batch.sh '/Users/fryntiz/Movies/Slides/galleries' '/Users/fryntiz/Movies/Slides/output'
```

## TODO

- [] Poner información externa primero
- [] Metadatos en inglés
-
- [ ] Mirar si es viable suavizar vídeo con denoise nlmeans
