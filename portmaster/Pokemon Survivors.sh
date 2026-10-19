#!/bin/bash
# Pokémon Survivors — запуск на приставках через PortMaster (muOS, ArkOS, Knulli и т.д.).
# Игра собрана Godot 4.7 под Linux arm64 и лежит рядом: pokesurvivors/pokesurvivors.aarch64 + .pck.
# Кнопки идут через gptokeyb -> клавиши (pokesurvivors.gptk); выход по Select+Start.

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR=/$directory/ports/pokesurvivors
CONFDIR="$GAMEDIR/conf/"
BINARY="pokesurvivors.aarch64"

mkdir -p "$GAMEDIR/conf"
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# сохранения и настройки — в папке порта (conf/godot/app_userdata/…)
export XDG_DATA_HOME="$CONFDIR"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export GODOT_SILENCE_ROOT_WARNING=1

$ESUDO chmod +x "$GAMEDIR/$BINARY"

# Wayland-обёртка PortMaster для Godot 4 (westonpack): монтируем; если рантайма нет — скачает PortMaster
weston_dir=/tmp/weston
weston_runtime="weston_pkg_0.2"
$ESUDO mkdir -p "${weston_dir}"
if [ ! -f "$controlfolder/libs/${weston_runtime}.squashfs" ]; then
  if [ ! -f "$controlfolder/harbourmaster" ]; then
    pm_message "This port requires the latest PortMaster to run, please go to https://portmaster.games/ for more info."
    sleep 5
    exit 1
  fi
  $ESUDO $controlfolder/harbourmaster --quiet --no-check runtime_check "${weston_runtime}.squashfs"
fi
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
  $ESUDO umount "${weston_dir}"
fi
$ESUDO mount "$controlfolder/libs/${weston_runtime}.squashfs" "${weston_dir}"

# gptokeyb превращает кнопки в клавиши по pokesurvivors.gptk (нативный джойстик Godot в игре отключён)
$GPTOKEYB "$BINARY" -c "$GAMEDIR/pokesurvivors.gptk" &
pm_platform_helper "$GAMEDIR/$BINARY"

# Проект собран под рендерер Mobile (Vulkan), которого на Mali нет — принудительно OpenGL ES (Compatibility)
$ESUDO env $weston_dir/westonwrap.sh headless noop kiosk crusty_x11egl \
XDG_DATA_HOME=$CONFDIR SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" \
$GAMEDIR/$BINARY --resolution ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} -f \
--rendering-method gl_compatibility --rendering-driver opengl3_es --audio-driver ALSA -- --keys-only

$ESUDO $weston_dir/westonwrap.sh cleanup
if [[ "$PM_CAN_MOUNT" != "N" ]]; then
  $ESUDO umount "${weston_dir}"
fi
pm_finish
