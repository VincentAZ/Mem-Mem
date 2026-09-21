#!/usr/bin/env bash
# Reproduce the shipped CC0 crowd edits. Requires curl and FFmpeg; not a build dependency.
set -euo pipefail
cd "$(dirname -- "$0")/.."
mkdir -p .tools/audio-source
curl -fL --retry 2 https://opengameart.org/sites/default/files/cheers_1.ogg -o .tools/audio-source/cheers.ogg
curl -fL --retry 2 https://opengameart.org/sites/default/files/applause-clapping-church-crowd-immersive.wav -o .tools/audio-source/applause.wav
ffmpeg -y -v error -i .tools/audio-source/cheers.ogg -t 2.2 -af 'afade=t=in:d=0.03,afade=t=out:st=1.6:d=0.6,loudnorm=I=-23:TP=-5:LRA=7' -ar 44100 -ac 1 game/assets/audio/crowd-1.ogg
ffmpeg -y -v error -ss 2 -i .tools/audio-source/applause.wav -t 2.2 -af 'afade=t=in:d=0.08,afade=t=out:st=1.5:d=0.7,loudnorm=I=-23:TP=-5:LRA=7' -ar 44100 -ac 1 game/assets/audio/crowd-2.ogg
ffmpeg -y -v error -i .tools/audio-source/cheers.ogg -ss 0.3 -t 2.0 -af 'asetrate=42336,aresample=44100,afade=t=in:d=0.04,afade=t=out:st=1.4:d=0.6,loudnorm=I=-23:TP=-5:LRA=7' -ac 1 game/assets/audio/crowd-3.ogg
