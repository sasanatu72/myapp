# MyApp - 生活管理アプリ

カレンダー、Todo、Noteをまとめて管理できる生活管理アプリです。  
Flutter Web と FastAPI を用いて、認証付きのフルスタックアプリとして開発しました。

## 公開URL

- Frontend: https://myapp-frontend-042i.onrender.com/
- API Docs: https://myapp-backend-5axl.onrender.com/docs

## Demo Account

Email: demo@example.com  
Password: example

## 主な機能

- ユーザー登録
- ログイン
- ログアウト
- カレンダーイベントの作成・編集・削除
- Todoの作成・完了状態変更・削除
- Noteの作成・編集・削除
- ユーザーごとの表示タブ設定
- JWT認証
- PostgreSQLによるデータ永続化

## 使用技術

### Frontend

- Flutter
- Dart
- Provider
- SharedPreferences
- Flutter Web

### Backend

- Python
- FastAPI
- SQLAlchemy
- PostgreSQL
- Alembic
- JWT Authentication

### Deployment

- Render
- Render PostgreSQL

## アーキテクチャ

```text
Flutter Web
   ↓ HTTP / REST API
FastAPI Backend
   ↓ SQLAlchemy
PostgreSQL
```

## ディレクトリ構成

```text
.
├── backend
│   ├── app
│   ├── alembic
│   ├── alembic.ini
│   ├── requirements.txt
│   └── README.md
├── frontend
│   ├── lib
│   ├── assets
│   ├── web
│   ├── android
│   ├── ios
│   ├── pubspec.yaml
│   └── README.md
├── .gitignore
└── README.md
```

## 開発目的

就職活動用のポートフォリオとして、画面実装だけでなく、認証、API設計、DB設計、CRUD処理、マイグレーション、デプロイまで一通り経験することを目的に開発しました。

## Development Points

このアプリでは、以下を意識して開発しました。

- フロントエンドとバックエンドを分離した構成
- JWTを用いた認証処理
- ユーザーごとのデータ分離
- SQLAlchemyによるDB操作
- Alembicによるマイグレーション管理
- Renderを用いたWebアプリ公開
- Flutter WebでのUI実装

## 今後の改善予定

- テストコードの追加
- UI/UXの改善
- エラーハンドリングの強化
- CI/CDの導入
- スマートフォン向け表示の最適化