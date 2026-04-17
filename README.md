# Hermes Agent Docker セットアップ

公式 Docker イメージ `nousresearch/hermes-agent:latest` をベースにした、ローカル向けの Hermes Agent 環境です。

状態や設定、認証情報は `hermes-data/` に保存します。この repo で通常編集するのはルート配下の Docker / 設定ファイルです。

## クイックスタート

```bash
cp .env.example .env
```

`.env` では最低限次を設定します。

- `OPENROUTER_API_KEY`
- `SLACK_BOT_TOKEN`
- `SLACK_APP_TOKEN`
- `SLACK_ALLOWED_USERS`

起動と確認:

```bash
docker compose up -d --build
docker compose logs -f hermes
```

初回起動時は `gcloud`、`gws 0.22.3`、`agent-browser 0.24.1` を自動導入するため、通常より時間がかかります。`uv` は Docker build 時にイメージへ同梱されます。

## アクセス

Gateway と Dashboard は Docker ホストの loopback にのみ公開されます。

- Gateway: `http://127.0.0.1:8642`
- Dashboard: `http://127.0.0.1:9119`

Tailscale で外部公開する場合:

```bash
tailscale serve --bg --https 8642 http://127.0.0.1:8642
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

## 永続化と変更時の注意

- `hermes-data/` は git 管理しません。状態、秘密情報の保存先です。
- `gcloud`、`gws`、`agent-browser` 本体と `agent-browser install` が展開するブラウザは `hermes-data/tools/` 配下に永続化されるため、コンテナ再作成後も再利用できます。
- `config.defaults.yaml` は初回 seed 用です。既存の `hermes-data/config.yaml` がある場合は上書きしません。
- 追加の apt / Python パッケージは Dockerfile の専用セクションで管理します。変更後は `docker compose up -d --build` で再ビルドします。
