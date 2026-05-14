#!/bin/bash
APP_NAME="VPNClient"
APP_BUNDLE="$APP_NAME.app"

echo "Очистка старого билда..."
rm -rf "$APP_BUNDLE"

echo "Создание структуры бандла..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "Копирование Info.plist и бинарника sing-box..."
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp sing-box "$APP_BUNDLE/Contents/Resources/sing-box"
chmod +x "$APP_BUNDLE/Contents/Resources/sing-box"

echo "Компиляция Swift-кода под macOS 10.10..."
swiftc main.swift AppDelegate.swift ViewController.swift \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -target x86_64-apple-macosx10.10 \
    -sdk $(xcrun --show-sdk-path)

echo "Готово! Приложение собрано в $APP_BUNDLE"
