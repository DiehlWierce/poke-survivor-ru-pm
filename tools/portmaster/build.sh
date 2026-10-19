#!/bin/zsh
# Сборка порта для PortMaster: Linux arm64 (движок + .pck) и сценарий запуска → build/PokemonSurvivors-<версия>-PortMaster.zip
# Нужны Godot 4.7.x и шаблоны экспорта Linux arm64 (linux_release.arm64).
#   zsh tools/portmaster/build.sh
set -e
cd "$(dirname "$0")/../.."
VER=$(grep '^config/version' project.godot | cut -d'"' -f2)
OUT=build/portmaster
rm -rf $OUT
mkdir -p $OUT/pokesurvivors build/release
godot --headless --path . --import
godot --headless --path . --export-release "PortMaster" $OUT/pokesurvivors/pokesurvivors.aarch64
[ -f $OUT/pokesurvivors/pokesurvivors.pck ] || { echo "нет pokesurvivors.pck"; exit 1; }
file $OUT/pokesurvivors/pokesurvivors.aarch64 | grep -q "aarch64" || { echo "движок не под arm64"; exit 1; }
cp "portmaster/Pokemon Survivors.sh" $OUT/
cp -R portmaster/pokesurvivors/. $OUT/pokesurvivors/
cp LICENSE CREDITS.md $OUT/pokesurvivors/licenses/ 2>/dev/null || true
find $OUT -name "*.import" -delete
find $OUT -name ".gdignore" -delete
chmod +x "$OUT/Pokemon Survivors.sh" $OUT/pokesurvivors/pokesurvivors.aarch64
rm -f "build/release/PokemonSurvivors-$VER-PortMaster.zip"
(cd $OUT && zip -qr "../release/PokemonSurvivors-$VER-PortMaster.zip" .)
ls -la build/release
