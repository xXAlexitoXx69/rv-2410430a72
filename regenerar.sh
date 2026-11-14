#!/bin/bash
# Regenera TODOS los recursos del recorrido desde el vídeo original (sin ningún retoque de IA).
set -e
SRC="$1"; cd "$(dirname "$0")"
FF=$(python -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())")
LOOK="deshake=rx=48:ry=48,crop=iw*0.96:ih*0.96,colortemperature=temperature=8200:mix=0.55,eq=gamma=1.12:saturation=1.06:contrast=1.04"
rm -rf assets/frames assets/framesd assets/img assets/vid
mkdir -p assets/vid assets/img
echo "entrada 0 14.5
cocina 14.5 30.5
despacho 30.5 41
bano 41 52
bano2 52 63
principal 63 68
dormitorio2 68 75.2" | while read id a b; do
  d=$(python -c "print($b-$a)")
  mkdir -p assets/frames/$id assets/framesd/$id
  "$FF" -nostdin -v error -y -ss "$a" -t "$d" -i "$SRC" -an -vf "$LOOK,scale=720:-2,unsharp=5:5:0.5" \
    -c:v libx264 -preset slow -crf 23 -pix_fmt yuv420p -r 24 -g 4 -keyint_min 4 -sc_threshold 0 -movflags +faststart assets/vid/$id-m.mp4
  "$FF" -nostdin -v error -y -ss "$a" -t "$d" -i "$SRC" -an -filter_complex \
    "[0:v]$LOOK,split[f][g];[g]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=40:2,eq=brightness=-0.12[bg];[f]scale=-2:1080,unsharp=5:5:0.6[fg];[bg][fg]overlay=(W-w)/2:0" \
    -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -r 24 -g 8 -keyint_min 8 -sc_threshold 0 -movflags +faststart assets/vid/$id.mp4
  "$FF" -nostdin -v error -y -i assets/vid/$id-m.mp4 -vf "fps=12,scale=540:-2" -q:v 5 assets/frames/$id/f%04d.jpg
  "$FF" -nostdin -v error -y -ss "$a" -t "$d" -i "$SRC" -vf "$LOOK,fps=12,scale=1080:-2,unsharp=5:5:0.5" -q:v 4 assets/framesd/$id/f%04d.jpg
  "$FF" -nostdin -v error -y -i assets/vid/$id.mp4 -frames:v 1 -q:v 3 assets/img/$id.jpg
  "$FF" -nostdin -v error -y -i assets/vid/$id-m.mp4 -frames:v 1 -q:v 3 assets/img/$id-m.jpg
  echo "$id m=$(ls assets/frames/$id | wc -l) d=$(ls assets/framesd/$id | wc -l)"
done
