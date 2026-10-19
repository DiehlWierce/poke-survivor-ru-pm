# Pokémon Survivors — русская версия + порт для PortMaster

Форк [JayElDragon/poke-survivor](https://github.com/JayElDragon/poke-survivor) — бесплатного фанатского Android-порта игры **[PokéSurvivor](https://github.com/JPTER78/pokesurvivor) от JPTER78**, сделанного на Godot. Выживай среди бесконечных волн покемонов, получай уровни, эволюционируй приёмы, входи в разломы, чтобы сразиться с легендарными, и встреть Суд Арсеуса.

**Оригинальная игра:** JPTER78. **Android-порт:** [JayElDragon](https://github.com/JayElDragon). **Порт для PortMaster и русификация в этом форке:** DiehlWierce. Весь геймдизайн, системы и контент — из оригинальной игры.

## Что добавлено в форке
- **Порт для PortMaster** (Linux arm64: muOS, ArkOS, Knulli и др.), проверялся на Anbernic RG34XX-SP (muOS 2601). На реальном железе пока не опробован.
- Проверка обновлений (она скачивает APK) включена только на Android.
- Русификация: перевод `data/lang_ru.json` в игре уже есть, в форке его проверяют и дорабатывают.

## Возможности игры
- Сенсорное управление (плавающий или фиксированный джойстик) и геймпад с раскладками **Xbox, PlayStation и Nintendo**, кнопки переназначаются
- 11 языков: English, Español (España / Latinoamérica), Français, Italiano, Português (Brasil / Portugal), Русский, 日本語, 中文（普通话）, 廣東話
- Интерфейс с учётом вырезов экрана, миникарта, ползунок поля зрения, настройки качества и доступности
- 960+ покемонов, гача, постоянные улучшения, задания, 130 достижений, профиль тренера
- Только офлайн: без рекламы, покупок и онлайн-функций

## Скачать
- **PortMaster (приставки):** zip в [Releases](../../releases). Распакуй в папку `ports` на приставке и запусти «Pokemon Survivors».
- **Android:** APK в [релизах оригинального порта](https://github.com/JayElDragon/poke-survivor/releases).

## Сборка
**Android:** установи [Godot 4](https://godotengine.org/) с шаблонами экспорта Android, открой `project.godot`, дождись импорта и экспортируй встроенным пресетом Android.

**PortMaster:** нужен Godot 4.7.x с шаблонами экспорта Linux arm64.
```
zsh tools/portmaster/build.sh
```
Результат: `build/release/PokemonSurvivors-<версия>-PortMaster.zip`.

## Авторы и лицензии
- Код: MIT (см. [`LICENSE`](LICENSE)). Спрайты: CC BY-NC 4.0, только некоммерческое использование. Полный список художников — в [`CREDITS.md`](CREDITS.md).
- Pokémon и его персонажи — торговые марки Nintendo, Creatures Inc. и GAME FREAK inc. Это некоммерческий фанатский проект, не связанный с ними.
