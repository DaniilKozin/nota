# Release Checklist for Nota

Используйте этот чеклист перед каждым релизом.

## Pre-Release

### 1. Code Quality
- [ ] Все тесты проходят
- [ ] Нет compiler warnings
- [ ] Код отформатирован
- [ ] Нет TODO/FIXME в критичных местах
- [ ] Документация обновлена

### 2. Security Check
- [ ] Нет API ключей в коде
- [ ] Нет персональных данных
- [ ] Нет хардкоженных паролей
- [ ] UserDefaults используется правильно
- [ ] Проверен SECURITY_CHECK.md

### 3. Version Management
- [ ] Обновлена версия: `./version.sh bump <type>`
- [ ] Обновлен CHANGELOG.md
- [ ] Версия соответствует изменениям (semantic versioning)

## Build Process

### 4. Clean Build
```bash
cd Nota-Swift

# Очистить предыдущие сборки
rm -rf .build/
rm -rf Nota.app
rm -f *.dmg

# Полная пересборка
swift build -c release
```

- [ ] Build успешен без ошибок
- [ ] Нет warnings

### 5. Create App Bundle
```bash
./create_app_bundle.sh
```

- [ ] Nota.app создан
- [ ] Версия в Info.plist правильная
- [ ] Иконки скопированы
- [ ] Приложение подписано (ad-hoc)
- [ ] Signature verified

### 6. Local Testing
```bash
open Nota.app
```

- [ ] Приложение запускается
- [ ] Иконка в menu bar появляется
- [ ] Mini window открывается
- [ ] Dashboard открывается
- [ ] Settings работают
- [ ] Запись работает
- [ ] Транскрипция работает
- [ ] AI insights работают
- [ ] История сохраняется

### 7. Create DMG
```bash
./create_dmg.sh
```

- [ ] DMG создан успешно
- [ ] Имя DMG правильное (с версией)
- [ ] Размер DMG разумный (~2-3 MB)
- [ ] README.txt включен
- [ ] install_nota.sh включен

### 8. DMG Testing
```bash
# Открыть DMG
open Nota-v2.1-SmartTranscription.dmg

# Проверить содержимое
ls -la /Volumes/Nota\ v2.1/
```

- [ ] Nota.app присутствует
- [ ] Applications symlink работает
- [ ] README.txt читается
- [ ] install_nota.sh исполняемый
- [ ] Окно DMG выглядит правильно

## Distribution Testing

### 9. Test on Another Mac (Critical!)

**На другом Mac или в чистой VM:**

```bash
# Method 1: Automatic installer
./install_nota.sh

# Method 2: Manual
cp -R Nota.app /Applications/
xattr -cr /Applications/Nota.app
open /Applications/Nota.app
```

- [ ] DMG монтируется без ошибок
- [ ] install_nota.sh работает
- [ ] Приложение устанавливается
- [ ] Gatekeeper не блокирует (после xattr)
- [ ] Приложение запускается
- [ ] Все функции работают
- [ ] Нет "damaged" ошибки

### 10. Fresh User Experience

**Как новый пользователь:**

- [ ] Первый запуск работает
- [ ] Permissions запрашиваются правильно
- [ ] Settings пустые (нет старых ключей)
- [ ] Можно ввести API ключ
- [ ] Можно начать запись
- [ ] Транскрипция работает
- [ ] Dashboard показывает данные

## Documentation

### 11. Update Documentation
- [ ] README.md актуален
- [ ] CHANGELOG.md обновлен
- [ ] AUDIO_SETUP_GUIDE.md актуален
- [ ] docs/GATEKEEPER_FIX.md актуален
- [ ] Nota-Swift/README.md актуален
- [ ] Все ссылки работают

### 12. GitHub Preparation
- [ ] Все изменения закоммичены
- [ ] Commit message понятный
- [ ] Нет uncommitted changes
- [ ] .gitignore правильный

## Release

### 13. Git Tag
```bash
VERSION=$(cat VERSION)
git add .
git commit -m "Release v${VERSION}"
git tag -a "v${VERSION}" -m "Release v${VERSION}"
```

- [ ] Commit создан
- [ ] Tag создан
- [ ] Tag message правильный

### 14. Push to GitHub
```bash
git push origin main
git push origin "v${VERSION}"
```

- [ ] Main branch pushed
- [ ] Tag pushed
- [ ] GitHub показывает новый tag

### 15. Create GitHub Release

На GitHub → Releases → New Release:

- [ ] Tag выбран правильный
- [ ] Title: "Nota v2.X.X"
- [ ] Description из CHANGELOG.md
- [ ] DMG файл прикреплен
- [ ] Release notes понятные
- [ ] Инструкции по установке включены

### 16. Release Notes Template

```markdown
# Nota v2.X.X

## 🎉 What's New

- Feature 1
- Feature 2
- Improvement 3

## 🐛 Bug Fixes

- Fixed issue with X
- Fixed crash when Y

## 📦 Installation

**Important:** To avoid "damaged app" error, use one of these methods:

### Method 1: Automatic (Recommended)
1. Mount DMG
2. Run `install_nota.sh` in Terminal

### Method 2: Manual
1. Copy Nota.app to Applications
2. Run: `xattr -cr /Applications/Nota.app`
3. Open Nota

See [GATEKEEPER_FIX.md](docs/GATEKEEPER_FIX.md) for details.

## 📋 Requirements

- macOS 13.0 (Ventura) or later
- OpenAI API key (for AI features)

## 🔗 Links

- [Full Changelog](CHANGELOG.md)
- [Documentation](README.md)
- [Audio Setup Guide](AUDIO_SETUP_GUIDE.md)

## 📥 Download

- [Nota-v2.X-SmartTranscription.dmg](link)
```

## Post-Release

### 17. Verify Release
- [ ] Release появился на GitHub
- [ ] DMG скачивается
- [ ] DMG работает на чистом Mac
- [ ] Все ссылки в release notes работают

### 18. Announce
- [ ] Обновить README.md с новой версией
- [ ] Создать announcement (если нужно)
- [ ] Обновить документацию (если нужно)

### 19. Monitor
- [ ] Проверить GitHub Issues на баги
- [ ] Ответить на вопросы пользователей
- [ ] Собрать feedback

## Rollback Plan

Если что-то пошло не так:

### Delete Release
```bash
# Delete GitHub release (через UI)

# Delete tag
git tag -d v2.X.X
git push origin :refs/tags/v2.X.X

# Revert commit
git revert HEAD
git push origin main
```

### Fix and Re-release
```bash
# Fix the issue
# ...

# Bump patch version
./version.sh bump patch

# Rebuild and release again
./build.sh
# ... follow checklist again
```

## Version-Specific Checks

### Patch Release (2.1.0 → 2.1.1)
- [ ] Только bug fixes
- [ ] Нет новых features
- [ ] Обратная совместимость 100%

### Minor Release (2.1.0 → 2.2.0)
- [ ] Новые features работают
- [ ] Старые features не сломаны
- [ ] Обратная совместимость
- [ ] Документация обновлена

### Major Release (2.1.0 → 3.0.0)
- [ ] Breaking changes документированы
- [ ] Migration guide создан
- [ ] Пользователи предупреждены
- [ ] Старая версия доступна

## Emergency Hotfix

Если критический баг в production:

1. **Создать hotfix branch**
   ```bash
   git checkout -b hotfix/critical-bug
   ```

2. **Исправить баг**
   ```bash
   # Fix the bug
   # Test thoroughly
   ```

3. **Bump patch version**
   ```bash
   ./version.sh bump patch
   ```

4. **Quick release**
   ```bash
   ./build.sh
   git add .
   git commit -m "Hotfix: critical bug description"
   git tag -a "v2.1.2" -m "Hotfix v2.1.2"
   git push origin hotfix/critical-bug
   git push origin v2.1.2
   ```

5. **Merge to main**
   ```bash
   git checkout main
   git merge hotfix/critical-bug
   git push origin main
   ```

## Automation Ideas

### Future: CI/CD Pipeline

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build
        run: |
          cd Nota-Swift
          swift build -c release
          ./create_app_bundle.sh
          ./create_dmg.sh
      - name: Create Release
        uses: actions/create-release@v1
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false
      - name: Upload DMG
        uses: actions/upload-release-asset@v1
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./Nota-Swift/*.dmg
          asset_name: Nota-SmartTranscription.dmg
          asset_content_type: application/x-apple-diskimage
```

---

**Last Updated:** January 14, 2026  
**Current Version:** 2.1.0  
**Next Release:** TBD
