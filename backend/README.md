# MyApp Backend

MyAppのバックエンドAPIです。  
FastAPI / SQLAlchemy / PostgreSQL を用いて実装し、JWT認証によってユーザーごとにデータを管理しています。

## Overview

このAPIは、Flutterフロントエンドから利用されることを想定しています。

主な機能は以下です。

- ユーザー登録
- ログイン
- JWT認証
- カレンダーイベント管理
- Todo管理
- Note管理
- ユーザー設定管理
- ヘルスチェック
- AlembicによるDBマイグレーション

## Tech Stack

- Python
- FastAPI
- Uvicorn
- SQLAlchemy
- PostgreSQL
- Alembic
- Passlib
- Python-Jose
- JWT

## Project Structure

```text
backend/
├── app
│   ├── core
│   ├── models
│   ├── routers
│   ├── schemas
│   ├── services
│   ├── db.py
│   └── main.py
├── alembic
├── alembic.ini
├── requirements.txt
└── README.md
```

## Environment Variables

このプロジェクトでは以下の環境変数を使用します。

```env
DATABASE_URL=postgresql://user:password@host:5432/dbname
SECRET_KEY=your-secret-key
ACCESS_TOKEN_EXPIRE_MINUTES=60
CORS_ORIGINS=https://your-frontend-url.onrender.com
```

## Local Setup

```bash
git clone https://github.com/sasanatu72/myapp.git
cd myapp/backend
pip install -r requirements.txt
```

環境変数を設定します。

### Windows PowerShell

```powershell
$env:DATABASE_URL="postgresql://user:password@host:5432/dbname"
$env:SECRET_KEY="your-secret-key"
$env:ACCESS_TOKEN_EXPIRE_MINUTES="60"
$env:CORS_ORIGINS="http://localhost:3000,http://localhost:5000"
```

### macOS / Linux

```bash
export DATABASE_URL="postgresql://user:password@host:5432/dbname"
export SECRET_KEY="your-secret-key"
export ACCESS_TOKEN_EXPIRE_MINUTES="60"
export CORS_ORIGINS="http://localhost:3000,http://localhost:5000"
```

DBマイグレーションを実行します。

```bash
alembic upgrade head
```

サーバーを起動します。

```bash
uvicorn app.main:app --reload
```

## API Docs

ローカル起動後、以下でSwagger UIを確認できます。

```text
http://localhost:8000/docs
```

## Main Endpoints

- `/auth`
- `/users`
- `/events`
- `/todos`
- `/notes`
- `/preferences`
- `/health`

## Deployment

Renderへのデプロイを想定しています。

### Build Command

```bash
pip install -r requirements.txt
```

### Start Command

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### Health Check Path

```text
/health
```

## Notes

本番環境では、`SECRET_KEY`、`DATABASE_URL`、`CORS_ORIGINS` をRenderのEnvironment Variablesに設定します。  
本物の環境変数や認証情報はGitHubに公開しません。

## Future Improvements

- テストコードの追加
- バリデーション強化
- ログ改善
- CI/CD導入
- 権限管理の整理