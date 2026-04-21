# Hermes Agent Docker セットアップ

公式 Docker イメージ `nousresearch/hermes-agent:latest` をベースにした、ローカル向けの Hermes Agent 環境です。

状態や設定、認証情報は `hermes-data/` に保存します。この repo で通常編集するのはルート配下の Docker / 設定ファイルです。

## クイックスタート

```bash
docker compose up -d --build
docker compose logs -f hermes
```

初回起動時に `hermes-data/.env` が自動生成されます。最低限次の値を設定してから再起動します。

```bash
# hermes-data/.env を編集
OPENROUTER_API_KEY=sk-...
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
SLACK_ALLOWED_USERS=U...
SLACK_HOME_CHANNEL=C...
SLACK_HOME_CHANNEL_NAME=general
GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/opt/data/google_client_secret.json

docker compose restart hermes
```

`gcloud`、`gws`、`agent-browser`、`uv` は Docker build 時にイメージへ同梱されます。バージョンは Dockerfile の `ARG` で管理します。

## アクセス

Gateway と Dashboard は Docker ホストの loopback にのみ公開されます。

- Gateway: `http://127.0.0.1:8642`
- Dashboard: `http://127.0.0.1:9119`

Dashboard をリモートのブラウザから使う場合:

```bash
tailscale serve --bg --https 9119 http://127.0.0.1:9119
```

## Slack 連携

Slack App の作成時に以下を設定します。

### Bot Token Scopes (OAuth & Permissions)

`chat:write`, `app_mentions:read`, `channels:history`, `channels:read`, `groups:history`, `im:history`, `im:read`, `im:write`, `users:read`, `files:read`, `files:write`

### App-Level Token Scope

`connections:write` (Socket Mode 用)

### Event Subscriptions

`message.im`, `message.channels`, `message.groups`, `app_mention`

### App Home

Messages Tab を有効にします。

ボットをチャンネルに招待するには `/invite @Hermes Agent` を使います。

## よく使うコマンド

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f hermes
docker compose logs -f hermes-dashboard
docker compose exec hermes hermes doctor
docker compose exec hermes hermes status
docker compose exec hermes sh
docker compose restart hermes
docker compose down
```

## アップデート

```bash
docker compose pull           # ベースイメージを最新に更新
docker compose up -d --build  # リビルド＆起動
```

`hermes-data/` 配下の設定やデータはボリュームマウントのため保持されます。

## 永続化と変更時の注意

- `hermes-data/` は git 管理しません。状態、秘密情報の保存先です。
- `gcloud`、`gws`、`agent-browser` とブラウザバイナリはイメージに焼き込まれています。コンテナ再作成でも再ダウンロードは発生しません（イメージ再ビルド時のみ）。
- `config.defaults.yaml` は初回 seed 用です。既存の `hermes-data/config.yaml` がある場合は上書きしません。`.env` は公式テンプレートから初回起動時に自動生成されます。
- 追加の apt / Python パッケージは Dockerfile の専用セクションで管理します。変更後は `docker compose up -d --build` で再ビルドします。
