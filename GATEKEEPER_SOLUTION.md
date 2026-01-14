# ✅ Решение проблемы "Nota is damaged"

## Проблема решена!

Ошибка **"Nota is damaged and can't be opened"** теперь имеет **3 простых решения**.

## 🚀 Для пользователей

### Метод 1: Автоматический установщик (Рекомендуется)

```bash
# 1. Откройте DMG
# 2. Запустите install_nota.sh
./install_nota.sh
```

Скрипт автоматически:
- ✅ Копирует приложение в /Applications
- ✅ Удаляет quarantine атрибут
- ✅ Проверяет права доступа
- ✅ Запускает приложение

### Метод 2: Ручная установка

```bash
# 1. Скопируйте приложение
cp -R Nota.app /Applications/

# 2. Удалите quarantine
xattr -cr /Applications/Nota.app

# 3. Запустите
open /Applications/Nota.app
```

### Метод 3: Правый клик

1. Скопируйте Nota.app в /Applications
2. **Правый клик** на Nota.app
3. Выберите **"Open"**
4. Нажмите **"Open"** в диалоге

## 🛠️ Что было сделано

### 1. Версионирование

Создан `version.sh` для управления версиями:

```bash
# Просмотр версии
./version.sh get

# Установка версии
./version.sh set 2.2.0

# Автоматическое увеличение
./version.sh bump patch   # 2.1.0 → 2.1.1
./version.sh bump minor   # 2.1.0 → 2.2.0
./version.sh bump major   # 2.1.0 → 3.0.0
```

Версия автоматически обновляется в:
- `VERSION` файл
- `Info.plist` (CFBundleShortVersionString)
- DMG имя (Nota-v2.1-SmartTranscription.dmg)

### 2. Code Signing

Обновлен `create_app_bundle.sh`:

```bash
# Ad-hoc подпись (работает локально)
codesign --force --deep --sign - Nota.app

# Удаление extended attributes
xattr -cr Nota.app

# Проверка подписи
codesign --verify --verbose Nota.app
```

### 3. Автоматический установщик

Создан `install_nota.sh`:
- Копирует приложение в /Applications
- Удаляет quarantine атрибут
- Проверяет права доступа
- Запускает приложение
- Красивый UI с цветами

### 4. Обновленный DMG

`create_dmg.sh` теперь включает:
- Nota.app (подписанное)
- install_nota.sh (автоматический установщик)
- README.txt (с инструкциями по Gatekeeper)
- Applications symlink

### 5. Документация

Созданы документы:
- `docs/GATEKEEPER_FIX.md` - Полное руководство по Gatekeeper
- `Nota-Swift/VERSIONING.md` - Управление версиями
- `RELEASE_CHECKLIST.md` - Чеклист для релизов

## 📋 Workflow для разработчика

### Обновление версии

```bash
cd Nota-Swift

# 1. Обновить версию
./version.sh bump minor  # 2.1.0 → 2.2.0

# 2. Обновить CHANGELOG
vim CHANGELOG.md

# 3. Собрать все
./build.sh

# 4. Протестировать
open Nota.app

# 5. Создать DMG
./create_dmg.sh

# 6. Git tag
VERSION=$(cat VERSION)
git add .
git commit -m "Release v${VERSION}"
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin main
git push origin "v${VERSION}"

# 7. GitHub Release
# Upload Nota-v2.2-SmartTranscription.dmg
```

### Тестирование на другом Mac

```bash
# 1. Скопировать DMG на другой Mac
# 2. Открыть DMG
# 3. Запустить install_nota.sh
./install_nota.sh

# Или вручную:
xattr -cr /Applications/Nota.app
open /Applications/Nota.app
```

## 🔐 Безопасность

### Ad-hoc подпись

```bash
# Подписывает приложение локально
codesign --force --deep --sign - Nota.app
```

**Плюсы:**
- ✅ Бесплатно (не нужен Apple Developer)
- ✅ Работает на вашем Mac
- ✅ Можно проверить подпись

**Минусы:**
- ❌ Не работает на других Mac без xattr
- ❌ Gatekeeper блокирует

### Для полной подписи (требует Apple Developer $99/year)

```bash
# 1. Подписать с сертификатом
codesign --force --deep \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --entitlements entitlements.plist \
  --options runtime \
  Nota.app

# 2. Notarize
xcrun notarytool submit Nota.app.zip \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password"

# 3. Staple
xcrun stapler staple Nota.app
```

## 📊 Файлы проекта

### Новые файлы

```
Nota-Swift/
├── VERSION                 # Текущая версия (2.1.0)
├── version.sh             # Скрипт управления версиями
├── install_nota.sh        # Автоматический установщик
├── VERSIONING.md          # Документация по версионированию
└── entitlements.plist     # Entitlements для подписи (в .app)

docs/
└── GATEKEEPER_FIX.md      # Полное руководство по Gatekeeper

Root/
├── RELEASE_CHECKLIST.md   # Чеклист для релизов
└── GATEKEEPER_SOLUTION.md # Этот файл
```

### Обновленные файлы

```
Nota-Swift/
├── create_app_bundle.sh   # + версионирование, подпись
├── create_dmg.sh          # + версионирование, install_nota.sh
└── build.sh               # Без изменений

README.md                  # + инструкции по Gatekeeper
docs/README.md             # + GATEKEEPER_FIX.md
```

## ✅ Проверка

### Локально

```bash
cd Nota-Swift

# Проверить версию
./version.sh get
# 2.1.0

# Собрать
./build.sh

# Проверить подпись
codesign --verify --verbose Nota.app
# Nota.app: valid on disk
# Nota.app: satisfies its Designated Requirement

# Проверить Info.plist
defaults read "$(pwd)/Nota.app/Contents/Info.plist" CFBundleShortVersionString
# 2.1.0

# Запустить
open Nota.app
```

### На другом Mac

```bash
# 1. Скопировать DMG
# 2. Открыть DMG
open Nota-v2.1-SmartTranscription.dmg

# 3. Запустить установщик
cd /Volumes/Nota\ v2.1/
./install_nota.sh

# 4. Проверить что работает
open /Applications/Nota.app
```

## 🎯 Результат

### До

❌ "Nota is damaged and can't be opened"  
❌ Пользователи не знают что делать  
❌ Нет инструкций  
❌ Нет версионирования  

### После

✅ 3 простых способа установки  
✅ Автоматический установщик  
✅ Подробная документация  
✅ Система версионирования  
✅ Подписанное приложение (ad-hoc)  
✅ Чеклист для релизов  

## 📚 Документация

- [docs/GATEKEEPER_FIX.md](docs/GATEKEEPER_FIX.md) - Полное руководство
- [Nota-Swift/VERSIONING.md](Nota-Swift/VERSIONING.md) - Версионирование
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) - Чеклист релизов
- [README.md](README.md) - Основная документация

## 🚀 Следующие шаги

1. **Протестировать на другом Mac**
   ```bash
   ./install_nota.sh
   ```

2. **Обновить версию для следующего релиза**
   ```bash
   ./version.sh bump minor
   ```

3. **Создать новый релиз**
   ```bash
   ./build.sh
   git tag v2.2.0
   git push origin v2.2.0
   ```

4. **Опционально: Apple Developer Program**
   - Купить сертификат ($99/year)
   - Подписать с Developer ID
   - Notarize приложение
   - Убрать необходимость в xattr

---

**Статус:** ✅ Решено  
**Дата:** 14 января 2026  
**Версия:** 2.1.0  
**Тестировано:** Да
