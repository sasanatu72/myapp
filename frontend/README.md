# Life Custom - Frontend

Life Customのフロントエンドです。  
Flutter Webで実装し、FastAPIバックエンドとREST APIで通信します。

## 概要

カレンダー、Todo、Noteをまとめて管理する生活管理アプリの画面部分です。

## 主な機能

- ログイン
- サインアップ
- カレンダー表示
- イベント作成・編集・削除
- Todo作成・完了状態変更・削除
- Note作成・編集・削除
- ユーザー設定
- JWTトークンを用いた認証付きAPI通信

## 使用技術

- Flutter
- Dart
- Provider
- SharedPreferences
- Table Calendar
- HTTP package
- Noto Sans JP

## ディレクトリ構成

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

## 環境

バックエンドAPIのURLは `API_BASE_URL` で指定します。

### ローカル

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

### 本番ビルド

```bash
flutter build web --release --dart-define=API_BASE_URL=<BACKEND_URL>
```

## ローカル環境環境

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

## 注記

日本語表示のためにNoto Sans JPを使用しています。  
APIの接続先はビルド時に `--dart-define=API_BASE_URL=...` で指定します。

## 今後の改善予定

- UI/UXの改善
- スマートフォン表示の最適化
- エラーメッセージの改善
- テストコードの追加