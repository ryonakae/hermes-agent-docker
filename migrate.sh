#!/bin/sh
# 一度きりのマイグレーションスクリプト
# ツールバイナリを Dockerfile に移行した後、ボリューム内の残骸を掃除する
set -eu

DATA_DIR="${1:-./hermes-data}"

if [ ! -d "$DATA_DIR" ]; then
  echo "hermes-data ディレクトリが見つかりません: $DATA_DIR" >&2
  exit 1
fi

echo "=== gcloud 認証情報の移行 ==="
GCLOUD_OLD="$DATA_DIR/tools/gcloud/config"
GCLOUD_NEW="$DATA_DIR/home/.config/gcloud"
if [ -d "$GCLOUD_OLD" ]; then
  mkdir -p "$GCLOUD_NEW"
  cp -a "$GCLOUD_OLD"/. "$GCLOUD_NEW"/
  echo "移行完了: $GCLOUD_OLD -> $GCLOUD_NEW"
else
  echo "スキップ: $GCLOUD_OLD が存在しません"
fi

echo ""
echo "=== /opt/data/tools/ の削除 ==="
if [ -d "$DATA_DIR/tools" ]; then
  rm -rf "$DATA_DIR/tools"
  echo "削除完了: $DATA_DIR/tools/"
else
  echo "スキップ: $DATA_DIR/tools/ が存在しません"
fi

echo ""
echo "=== /opt/data/.agent-browser/ の削除 ==="
if [ -e "$DATA_DIR/.agent-browser" ]; then
  rm -rf "$DATA_DIR/.agent-browser"
  echo "削除完了: $DATA_DIR/.agent-browser/"
else
  echo "スキップ: $DATA_DIR/.agent-browser/ が存在しません"
fi

echo ""
echo "=== /opt/data/home/ 内の Hermes データ残骸の削除 ==="
HOME_DIR="$DATA_DIR/home"
if [ -d "$HOME_DIR" ]; then
  # 削除対象のファイル
  for f in config.yaml .env auth.json auth.lock channel_directory.json \
           gateway_state.json .clean_shutdown .profile \
           .skills_prompt_snapshot.json models_dev_cache.json state.db; do
    if [ -e "$HOME_DIR/$f" ]; then
      rm -f "$HOME_DIR/$f"
      echo "削除: $HOME_DIR/$f"
    fi
  done

  # 削除対象のディレクトリ
  for d in skills sessions logs memories cron hooks plans skins \
           workspace platforms sandboxes bin home; do
    if [ -e "$HOME_DIR/$d" ]; then
      rm -rf "$HOME_DIR/$d"
      echo "削除: $HOME_DIR/$d/"
    fi
  done

  # .agent-browser シンボリックリンク
  if [ -L "$HOME_DIR/.agent-browser" ]; then
    rm -f "$HOME_DIR/.agent-browser"
    echo "削除: $HOME_DIR/.agent-browser (symlink)"
  fi

  echo ""
  echo "残っているファイル（.config 等）:"
  ls -la "$HOME_DIR/" 2>/dev/null || true
else
  echo "スキップ: $HOME_DIR が存在しません"
fi

echo ""
echo "=== マイグレーション完了 ==="
echo "docker compose up -d --build で再ビルドしてください"
