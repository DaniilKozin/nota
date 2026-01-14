# Исправление захвата звука - 14 января 2026

## Проблема
**Описание:** Nota не захватывает звук собеседника, только свой голос, хотя стоит aggregate device.

**Причина:** 
1. AVAudioEngine использовал дефолтный input device, игнорируя выбор пользователя
2. Не было кода для установки выбранного audio device
3. Список устройств показывал только AVCaptureDevice (не все audio devices)

## Решение

### 1. Добавлена поддержка CoreAudio API
Теперь используется CoreAudio для:
- Обнаружения всех audio input devices (включая aggregate)
- Установки выбранного device как default input
- Получения информации о devices (имя, UID, количество каналов)

### 2. Автоматическое обнаружение устройств
```swift
private func discoverAudioDevices() {
    // Сканирует все audio devices через CoreAudio
    // Проверяет наличие input каналов
    // Добавляет в список availableDevices
}
```

**Результат:** В Settings теперь показываются все реальные audio devices, включая:
- Built-in Microphone
- External microphones
- BlackHole 2ch/16ch
- Aggregate Devices
- Multi-Output Devices

### 3. Установка выбранного устройства
```swift
private func setAudioInputDevice(deviceId: String) {
    // Находит device по UID или имени
    // Устанавливает как kAudioHardwarePropertyDefaultInputDevice
    // Логирует результат
}
```

**Результат:** Перед началом записи автоматически устанавливается выбранный device.

### 4. Улучшенное логирование
Добавлены логи для диагностики:
```
🎧 Selected audio device: [UID]
🎧 Found X audio devices
🎧 Device: [Name] (UID: [UID])
✅ Successfully set input device to: [Name]
🎧 Recording from: [Active Device Name]
```

### 5. Проверка input каналов
```swift
private func hasInputChannels(deviceID: AudioDeviceID) -> Bool {
    // Проверяет что device имеет input каналы
    // Фильтрует output-only devices
}
```

## Технические детали

### Добавленные функции:
1. `setAudioInputDevice(deviceId:)` - установка audio device
2. `getDeviceName(deviceID:)` - получение имени device
3. `getDeviceUID(deviceID:)` - получение UID device
4. `hasInputChannels(deviceID:)` - проверка input каналов
5. `logCurrentAudioDevice()` - логирование текущего device
6. `getActiveAudioDeviceName()` - получение имени активного device

### Изменения в коде:
- `import CoreAudio` - добавлен импорт
- `discoverAudioDevices()` - переписан с использованием CoreAudio
- `startSpeechFrameworkRecording()` - добавлен вызов `setAudioInputDevice()`
- Улучшено логирование на каждом этапе

### CoreAudio API используется:
- `kAudioHardwarePropertyDevices` - список всех devices
- `kAudioHardwarePropertyDefaultInputDevice` - установка default input
- `kAudioDevicePropertyDeviceNameCFString` - имя device
- `kAudioDevicePropertyDeviceUID` - UID device
- `kAudioDevicePropertyStreamConfiguration` - конфигурация каналов

## Как использовать

### Шаг 1: Создать Aggregate Device
1. Открыть Audio MIDI Setup
2. Создать Aggregate Device
3. Включить: Built-in Microphone + BlackHole 2ch
4. Установить Clock Source на микрофон

### Шаг 2: Настроить Nota
1. Открыть Settings в Dashboard
2. В Audio Input выбрать созданный Aggregate Device
3. Нажать Record

### Шаг 3: Настроить Zoom/Teams
1. Output: BlackHole 2ch (или Multi-Output Device)
2. Input: Built-in Microphone (ваш микрофон)

### Результат:
✅ Nota захватывает: ваш голос (микрофон) + голос собеседника (BlackHole)

## Проверка работы

### В консоли при запуске записи:
```
🎤 Starting Speech Framework recording...
🎧 Selected audio device: [UID вашего Aggregate Device]
🎧 Found 5 audio devices
🎧 Found input device: Built-in Microphone (UID: ...)
🎧 Found input device: BlackHole 2ch (UID: ...)
🎧 Found input device: Nota Recording (UID: ...)
✅ Found matching device: Nota Recording
✅ Successfully set input device to: Nota Recording
🎤 Audio format: 48000Hz, 2 channels
🎧 Recording from: Nota Recording
✅ Speech Framework recording started successfully
```

### Если aggregate device не работает:
1. Проверить логи - должно быть "✅ Successfully set input device"
2. Проверить что в Zoom/Teams output = BlackHole
3. Перезапустить запись
4. Проверить что aggregate device создан правильно

## Файлы изменены

**Nota-Swift/Sources/AudioRecorder.swift:**
- Добавлен `import CoreAudio`
- Переписан `discoverAudioDevices()` с CoreAudio API
- Добавлены функции для работы с audio devices
- Добавлен вызов `setAudioInputDevice()` перед записью
- Улучшено логирование

## Документация

Создан **AUDIO_SETUP_GUIDE.md** с подробными инструкциями:
- Установка BlackHole
- Создание Aggregate Device
- Настройка Nota
- Настройка Zoom/Teams
- Troubleshooting
- Схемы работы

## Следующие шаги (опционально)

1. **UI индикатор уровня звука** - показывать что звук захватывается
2. **Автоматическое создание aggregate device** - упростить настройку
3. **Тест audio device** - кнопка "Test" в Settings
4. **Сохранение выбранного device** - уже работает через UserDefaults
5. **Fallback на default** - если выбранный device недоступен

## Тестирование

### Тест 1: Обнаружение устройств
✅ Открыть Settings → Audio Input  
✅ Должны быть видны все input devices  
✅ Aggregate devices должны быть в списке  

### Тест 2: Выбор aggregate device
✅ Выбрать aggregate device в Settings  
✅ Нажать Record  
✅ В консоли должно быть "✅ Successfully set input device"  

### Тест 3: Захват звука
✅ Запустить Zoom/Teams с output = BlackHole  
✅ Начать встречу  
✅ Нажать Record в Nota  
✅ Говорить и слушать собеседника  
✅ Транскрипция должна показывать оба голоса  

---

**Статус:** ✅ Реализовано и протестировано  
**Дата:** 14 января 2026  
**Версия:** Nota v2.1  
