# MyApp Frontend

MyAppのフロントエンドです。  
Flutter Webで実装し、FastAPIバックエンドとREST APIで通信します。

## Overview

カレンダー、Todo、Noteをまとめて管理する生活管理アプリの画面部分です。

## Main Features

- ログイン
- サインアップ
- カレンダー表示
- イベント作成・編集・削除
- Todo作成・完了状態変更・削除
- Note作成・編集・削除
- ユーザー設定
- JWTトークンを用いた認証付きAPI通信

## Tech Stack

- Flutter
- Dart
- Provider
- SharedPreferences
- Table Calendar
- HTTP package
- Noto Sans JP

## Project Structure

```text
frontend/
├── lib
│   ├── config
│   ├── controllers
│   ├── models
│   ├── screens
│   ├── services
│   ├── widgets
│   └── main.dart
├── assets
│   └── fonts
├── web
├── android
├── ios
├── pubspec.yaml
└── README.md
```

## Environment

バックエンドAPIのURLは `API_BASE_URL` で指定します。

### Local

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

### Production Build

```bash
flutter build web --release --dart-define=API_BASE_URL=<BACKEND_URL>
```

## Local Setup

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Deployment

Render Static Siteへのデプロイを想定しています。

### Build Command

```bash
./render-build.sh
```

または、

```bash
flutter build web --release --dart-define=API_BASE_URL=<BACKEND_URL>
```

### Publish Directory

```text
build/web
```

## Notes

日本語表示のためにNoto Sans JPを使用しています。  
APIの接続先はビルド時に `--dart-define=API_BASE_URL=...` で指定します。

## Future Improvements

- UI/UXの改善
- スマートフォン表示の最適化
- エラーメッセージの改善
- テストコードの追加