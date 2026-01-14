# Nota Version Management

## Текущая версия

Версия хранится в файле `VERSION`:

```bash
cat VERSION
# 2.1.0
```

## Управление версиями

### Просмотр текущей версии

```bash
./version.sh get
# 2.1.0
```

### Установка конкретной версии

```bash
./version.sh set 2.2.0
```

Это обновит:
- `VERSION` файл
- `create_app_bundle.sh` (Info.plist)
- `create_dmg.sh` (DMG имя)

### Автоматическое увеличение версии

```bash
# Patch: 2.1.0 → 2.1.1 (bug fixes)
./version.sh bump patch

# Minor: 2.1.0 → 2.2.0 (new features)
./version.sh bump minor

# Major: 2.1.0 → 3.0.0 (breaking changes)
./version.sh bump major
```

## Semantic Versioning

Мы используем [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
  │     │     │
  │     │     └─ Bug fixes, small improvements
  │     └─────── New features, backward compatible
  └───────────── Breaking changes, major updates
```

### Примеры

**Patch (2.1.0 → 2.1.1)**
- Исправление багов
- Улучшение производительности
- Обновление документации
- Мелкие UI улучшения

```bash
./version.sh bump patch
```

**Minor (2.1.0 → 2.2.0)**
- Новые функции
- Новые настройки
- Улучшения UI/UX
- Обратная совместимость

```bash
./version.sh bump minor
```

**Major (2.1.0 → 3.0.0)**
- Полная переработка
- Несовместимые изменения
- Новая архитектура
- Удаление старых функций

```bash
./version.sh bump major
```

## Workflow для релиза

### 1. Обновить версию

```bash
cd Nota-Swift

# Выбрать тип обновления
./version.sh bump minor  # или patch/major
```

### 2. Обновить CHANGELOG

```bash
# Добавить в CHANGELOG.md
vim CHANGELOG.md
```

Пример:
```markdown
## [2.2.0] - 2026-01-15

### Added
- New feature X
- New setting Y

### Fixed
- Bug with audio device
- UI glitch in Dashboard

### Changed
- Improved transcription accuracy
- Updated GPT-5 prompts
```

### 3. Собрать приложение

```bash
# Полная сборка
./build.sh

# Или по шагам:
swift build -c release
./create_app_bundle.sh
./create_dmg.sh
```

### 4. Протестировать

```bash
# Локально
open Nota.app

# На другом Mac
./install_nota.sh
```

### 5. Создать git tag

```bash
# Получить версию
VERSION=$(cat VERSION)

# Создать tag
git add .
git commit -m "Release v${VERSION}"
git tag -a "v${VERSION}" -m "Release v${VERSION}"

# Отправить на GitHub
git push origin main
git push origin "v${VERSION}"
```

### 6. Создать GitHub Release

1. Перейти на GitHub → Releases → New Release
2. Выбрать tag: `v2.2.0`
3. Заголовок: `Nota v2.2.0`
4. Описание: скопировать из CHANGELOG.md
5. Прикрепить файл: `Nota-v2.2-SmartTranscription.dmg`
6. Опубликовать

## Автоматизация

### Скрипт полного релиза

Создайте `release.sh`:

```bash
#!/bin/bash

set -e

# 1. Проверить что нет uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo "❌ Uncommitted changes found. Commit first."
    exit 1
fi

# 2. Спросить тип релиза
echo "Release type:"
echo "  1) patch (bug fixes)"
echo "  2) minor (new features)"
echo "  3) major (breaking changes)"
read -p "Choose (1-3): " choice

case $choice in
    1) TYPE="patch" ;;
    2) TYPE="minor" ;;
    3) TYPE="major" ;;
    *) echo "Invalid choice"; exit 1 ;;
esac

# 3. Обновить версию
./version.sh bump $TYPE
VERSION=$(cat VERSION)

echo "📌 New version: $VERSION"

# 4. Собрать
echo "🔨 Building..."
./build.sh

# 5. Создать commit и tag
git add .
git commit -m "Release v${VERSION}"
git tag -a "v${VERSION}" -m "Release v${VERSION}"

echo "✅ Release v${VERSION} ready!"
echo ""
echo "Next steps:"
echo "  1. git push origin main"
echo "  2. git push origin v${VERSION}"
echo "  3. Create GitHub Release"
echo "  4. Upload Nota-v${VERSION%.*}-SmartTranscription.dmg"
```

## Version в коде

### Info.plist

Версия автоматически подставляется в `Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>2.2.0</string>
<key>CFBundleVersion</key>
<string>220</string>
```

- `CFBundleShortVersionString` - отображаемая версия (2.2.0)
- `CFBundleVersion` - build number (220)

### DMG имя

DMG автоматически называется по версии:

```
Nota-v2.2-SmartTranscription.dmg
```

### В приложении

Чтобы показать версию в UI, добавьте в SwiftUI:

```swift
// В DashboardWindow.swift
Text("Nota v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
    .font(.caption)
    .foregroundColor(.secondary)
```

## Проверка версии

### Из командной строки

```bash
# Версия из VERSION файла
cat VERSION

# Версия из Info.plist (после сборки)
defaults read "$(pwd)/Nota.app/Contents/Info.plist" CFBundleShortVersionString

# Версия из DMG имени
ls -1 *.dmg | grep -oP 'v\K[0-9]+\.[0-9]+'
```

### Из приложения

```bash
# После установки
defaults read /Applications/Nota.app/Contents/Info.plist CFBundleShortVersionString
```

## История версий

### v2.1.0 (January 14, 2026)
- GPT-5 Nano/Mini support
- Smart transcription system
- Recording history
- Liquid Glass 2026 design

### v2.0.0 (January 2026)
- Complete Swift rewrite
- Native macOS performance

### v1.0.0 (December 2025)
- Initial release

## Best Practices

1. **Всегда обновляйте CHANGELOG.md** перед релизом
2. **Тестируйте на другом Mac** перед публикацией
3. **Используйте semantic versioning** правильно
4. **Создавайте git tags** для каждого релиза
5. **Документируйте breaking changes** в CHANGELOG
6. **Проверяйте DMG** перед распространением

## Troubleshooting

### Версия не обновилась в Info.plist

```bash
# Пересобрать app bundle
./create_app_bundle.sh
```

### Версия не обновилась в DMG

```bash
# Пересоздать DMG
./create_dmg.sh
```

### Git tag уже существует

```bash
# Удалить локальный tag
git tag -d v2.2.0

# Удалить remote tag
git push origin :refs/tags/v2.2.0

# Создать заново
git tag -a v2.2.0 -m "Release v2.2.0"
git push origin v2.2.0
```

---

**Обновлено:** 14 января 2026  
**Текущая версия:** 2.1.0
