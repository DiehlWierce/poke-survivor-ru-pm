#!/bin/zsh
# Сборка порта для PortMaster: Linux arm64 (движок + .pck) и сценарий запуска → build/PokemonSurvivors-<версия>-PortMaster.zip
# Нужны Godot 4.7.x, шаблоны экспорта Linux arm64 (linux_release.arm64), file, zip и unzip.
#   zsh tools/portmaster/build.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_DIR"

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		print -u2 -- "Не найдена обязательная команда: $1"
		exit 1
	fi
}

for command_name in godot file zip unzip; do
	require_command "$command_name"
done

if [[ ! -f "$PROJECT_DIR/project.godot" ]]; then
	print -u2 -- "Не найден project.godot в $PROJECT_DIR"
	exit 1
fi

VER="$(sed -n 's/^config\/version="\([^"]*\)"$/\1/p' "$PROJECT_DIR/project.godot")"
if [[ -z "$VER" ]]; then
	print -u2 -- "Не удалось прочитать application/config/version из project.godot"
	exit 1
fi

for required_file in \
	"$PROJECT_DIR/portmaster/Pokemon Survivors.sh" \
	"$PROJECT_DIR/portmaster/pokesurvivors/port.json" \
	"$PROJECT_DIR/portmaster/pokesurvivors/gameinfo.xml" \
	"$PROJECT_DIR/LICENSE" \
	"$PROJECT_DIR/CREDITS.md"; do
	if [[ ! -f "$required_file" ]]; then
		print -u2 -- "Не найден обязательный файл: $required_file"
		exit 1
	fi
done

BUILD_DIR="$PROJECT_DIR/build"
OUT="$BUILD_DIR/portmaster"
RELEASE_DIR="$BUILD_DIR/release"
EXPORT_DIR="$OUT/pokesurvivors"
BINARY="$EXPORT_DIR/pokesurvivors.aarch64"
PCK="$EXPORT_DIR/pokesurvivors.pck"
ARCHIVE="$RELEASE_DIR/PokemonSurvivors-$VER-PortMaster.zip"
ARCHIVE_TMP="$ARCHIVE.tmp"

mkdir -p "$RELEASE_DIR"
rm -rf "$OUT"
mkdir -p "$EXPORT_DIR"

godot --headless --path "$PROJECT_DIR" --import
godot --headless --path "$PROJECT_DIR" --export-release "PortMaster" "$BINARY"

if [[ ! -s "$BINARY" ]]; then
	print -u2 -- "Экспорт не создал исполняемый файл: $BINARY"
	exit 1
fi
if [[ ! -s "$PCK" ]]; then
	print -u2 -- "Экспорт не создал PCK или он пуст: $PCK"
	exit 1
fi

BINARY_INFO="$(file "$BINARY")"
if [[ "$BINARY_INFO" != *aarch64* ]]; then
	print -u2 -- "Ожидался Linux arm64-бинарник, получено: $BINARY_INFO"
	exit 1
fi

cp "$PROJECT_DIR/portmaster/Pokemon Survivors.sh" "$OUT/"
cp -R "$PROJECT_DIR/portmaster/pokesurvivors/." "$EXPORT_DIR/"
cp "$PROJECT_DIR/LICENSE" "$PROJECT_DIR/CREDITS.md" "$EXPORT_DIR/licenses/"

for required_file in \
	"$OUT/Pokemon Survivors.sh" \
	"$EXPORT_DIR/port.json" \
	"$EXPORT_DIR/gameinfo.xml" \
	"$EXPORT_DIR/pokesurvivors.gptk" \
	"$EXPORT_DIR/licenses/LICENSE" \
	"$EXPORT_DIR/licenses/CREDITS.md"; do
	if [[ ! -s "$required_file" ]]; then
		print -u2 -- "После копирования отсутствует обязательный файл: $required_file"
		exit 1
	fi
done

find "$OUT" -type f \( -name '*.import' -o -name '.gdignore' \) -delete
chmod +x "$OUT/Pokemon Survivors.sh" "$BINARY"

rm -f "$ARCHIVE_TMP"
trap 'rm -f "$ARCHIVE_TMP"' EXIT
(cd "$OUT" && zip -qr "$ARCHIVE_TMP" .)
if [[ ! -s "$ARCHIVE_TMP" ]]; then
	print -u2 -- "Архив не создан или пуст: $ARCHIVE_TMP"
	exit 1
fi
unzip -tq "$ARCHIVE_TMP"
mv -f "$ARCHIVE_TMP" "$ARCHIVE"
trap - EXIT

print -- "Сборка готова: $ARCHIVE"
