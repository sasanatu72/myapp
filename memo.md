# アプリケーション開発
## backend
- INTERNAL_DATABASE_URL
  ```
  postgresql://app_user:txm9l2g4lBUXqoJZVPeFcLXw24szWpDH@dpg-d7k2oet7vvec739387lg-a/app_db_64o8
  ```
- EXTERNAL_DATABASE_URL
  ```
  postgresql://app_user:txm9l2g4lBUXqoJZVPeFcLXw24szWpDH@dpg-d7k2oet7vvec739387lg-a.singapore-postgres.render.com/app_db_64o8
  ```
- SECRET_KEY
  ```
  zxkxxcf8ndga0km2t39jw4rzpg1vkd1rmrcaect6g7589a9746umke4gpxlv
  ```
- Build Command
  ```
  pip install -r reqirement.txt
  ```
- Start Commond
  ```
  uvicorn app.main:app --host 0.0.0.0 --port $PORT
  ```



## frontend

## 完了タスク
### 認証
- 新規登録
- ログイン
- ログアウト
- トークン保持
- 401時の共通ログアウト処理

### カレンダー
- 一覧取得
- 作成
- 編集
- 削除

### todo
- 一覧取得
- 作成
- 完了切替
- 削除

### note
- 一覧取得
- 作成
- 編集
- 削除

### 設定
- 表示タブ
- タブ順処
- 初期タブ
- テーマカラー
- ログアウト

## 未完タスク
- JWT認証理解
- API baseURL本番用に変更


- マイグレーション管理
Base.metadata.create_all(bind=engine) でテーブルを作っている。
開発初期はこれでもよいが、デプロイ後にスキーマ変更が入るとつらい。
  - 今回は個人開発なので一旦 create_all で押し切る
  - できれば Alembic 導入



## 優先順位をつけるとこうである
### 最優先
- baseUrl を本番切替可能にする
### 次
### 余裕があれば
- 入力バリデーション
- health check / logging

## 就活に向けると
1. baseUrl の本番切替
7. README とデモ準備

