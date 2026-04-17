# Hermes Agent Docker ラッパー repo 向けガイド

このリポジトリは `nousresearch/hermes-agent:latest` をベースに、ローカル用の Hermes Agent 環境を Docker で運用するための repo です。通常の編集対象はルートの Docker / 設定ファイルです。`hermes-data/` 配下はこの AGENTS の対象外として扱ってください。

## よく使うコマンド

```bash
cp .env.example .env
docker compose up -d --build
docker compose ps
docker compose logs -f hermes
docker compose exec hermes hermes doctor
docker compose exec hermes sh
docker compose restart hermes
docker compose down
```

- 初回セットアップは `cp .env.example .env` の後に `.env` を埋める。
- 設定や Dockerfile を変えたら `docker compose up -d --build` で再ビルドする。
- 動作確認の基本は `docker compose logs -f hermes` と `docker compose exec hermes hermes doctor`。

## 検証

- `Dockerfile`、`docker-compose.yml`、`entrypoint.sh`、`config.defaults.yaml` を変えたら、最低限 `docker compose up -d --build`、`docker compose logs -f hermes`、`docker compose exec hermes hermes doctor` を順に確認する。
- `.env.example` を変えたら、README のセットアップ手順と矛盾しないか確認する。
- この repo はアプリ本体のユニットテスト repo ではない。まずはコンテナが起動し、gateway が健康状態になることを検証の基準にする。

## 重要ファイル

- `Dockerfile`: ベースイメージ拡張。追加の apt / Python パッケージと PATH などの環境変数もここで管理する。
- `docker-compose.yml`: ローカル起動定義。ポート、永続化ボリュームを持つ。
- `entrypoint.sh`: 初回 bootstrap、`gcloud` / `gws` / `agent-browser` 導入、seed 処理、gateway 起動を行う。
- `config.defaults.yaml`: 初回のみ `hermes-data/config.yaml` へ seed する非機密設定。
- `.env.example`: 利用者が `.env` を作るためのテンプレート。
- `hermes-data/`: コンテナ内 `/opt/data` に bind mount されるローカル状態。git 管理しない。
- `CLAUDE.md`: `AGENTS.md` へのシンボリックリンク。編集は `AGENTS.md` 側で行う。

## 変更時の注意

- `config.defaults.yaml` は seed 専用。`entrypoint.sh` は既存ファイルがある場合に上書きしない。
- 既存環境へ設定反映が必要な変更では、「新規 seed には効くが既存 `hermes-data/` には自動反映されない」前提で影響を考える。
- 秘密情報は追跡ファイルへ書かない。`.env` か `hermes-data/` 配下で扱う。
- 追加の apt / Python パッケージは `Dockerfile` の専用セクションへ追記する。
