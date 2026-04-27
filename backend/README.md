# MyApp Backend

カレンダー・Todo・Note をまとめた日常生活管理アプリのバックエンドです。  
FastAPI / SQLAlchemy / PostgreSQL を用いて実装し、JWT認証付きでユーザーごとにデータを管理しています。  
就職活動用のポートフォリオとして、認証、CRUD、DB、マイグレーション、デプロイまで一通り扱うことを目的に作成しました。

---

## Overview

このプロジェクトは、生活管理アプリのバックエンド API です。  
フロントエンドアプリから利用することを想定し、以下の機能を提供しています。

- ユーザー登録 / ログイン
- カレンダーイベント管理
- Todo 管理
- Note 管理
- ユーザー設定管理
- ヘルスチェック
- PostgreSQL 対応
- Alembic によるマイグレーション管理

---

## Motivation

このアプリは、作成者自身が日常で使用しているツールを一つのアプリにまとめたいという想いと、就職活動で自分の開発経験を具体的に示すために作成しました。  
単なる画面実装だけでなく、以下を含めて一通り経験することを意識しています。

- 認証機能の実装
- REST API 設計
- db 設計
- ユーザーごとのデータ分離
- マイグレーション管理
- Render へのデプロイ

---

## Tech Stack

- **Language**: Python
- **Framework**: FastAPI
- **Server**: Uvicorn
- **ORM**: SQLAlchemy
- **Database**: PostgreSQL
- **Migration**: Alembic
- **Authentication**: JWT
- **Password Hashing**: Passlib / Argon2
- **Deployment**: Render

---

## Main Features

### 1. Authentication
- ユーザー登録
- ログイン
- JWT アクセストークン発行
- 認証ユーザー取得

### 2. Events
- イベント作成
- イベント一覧取得
- イベント編集
- イベント削除

### 3. Todos
- Todo 作成
- Todo 一覧取得
- Todo 完了状態更新
- Todo 削除

### 4. Notes
- Note 作成
- Note 一覧取得
- Note 編集
- Note 削除

### 5. User Preferences
- 表示タブ設定
- 初期タブ設定
- ユーザーごとの設定保存

### 6. Health Check
- API の起動確認用エンドポイント

---

## API Endpoints

主なエンドポイントは以下です。

- `/auth`
- `/users`
- `/events`
- `/todos`
- `/notes`
- `/preferences`
- `/health`

詳細は Swagger UI で確認できます。

---

## Project Structure

```text
.
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

## Enviroment Variables

このプロジェクトでは環境変数を使用します。

### Required
- `DATABASE_URL`
- `SECRET_KEY`

## Local Setup

### 1. Clone
``` bash
git clone https://github.com/sasanatu72/myapp-backend
cd myapp-backend
```

### 2. Install dependencies
``` bash
pip install -r requiments.txt
```

### 3. Setenviroment variables
#### Windows PowerShell
``` PowerShell
$env:DATABASE_URL="postgresql://user:password@host:5432/dbname"
$env:SECRET_KEY="your-very-long-random-secret-key"
```

#### macOS / Linux
``` bash
export DATABASE_URL="postgresql://user:password@host:5432/dbname"
export SECRET_KEY="your-very-long-random-secret-key"
export ACCESS_TOKEN_EXPIRE_MINUTES="60"
export CORS_ORIGINS="*"
```

### 4. Run migration
``` bash
alembic upgrade head
```

### 5. Start server
``` bash 
uvicorn app.main:app --reload
```
---

### Deployment
このバックエンドはRenderへのデプロイを想定しています。

#### Build Command
``` bash
pip install -r requiments.txt
```

#### Start Command
``` bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

#### Health Check Path
``` bash
/health
```

#### Enviroment Variables on Render 
- `DATABASE_URL`
- `SECRET_KEY`
---

### API Check
デプロイ後は以下を確認します。
- `/health`
- `/docs`
- サインアップ
- ログイン
- events / todos / notes/ preferences の取得


### Future Improvements
- テストコードの追加
- バリデーション強化
- ログ改善
- CI/CD 導入
- 権限管理の整理
- API設計の改善
