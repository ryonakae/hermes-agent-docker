#!/bin/sh
set -eu

TEMPLATE_CONFIG_PATH=/usr/local/share/hermes/config.defaults.yaml
OFFICIAL_ENTRYPOINT=/opt/hermes/docker/entrypoint.sh

DATA_DIR=/opt/data
CONFIG_PATH=$DATA_DIR/config.yaml

# カスタム設定を seed する（公式 entrypoint のデフォルト seed より先に実行）
if [ ! -f "$CONFIG_PATH" ]; then
  cp "$TEMPLATE_CONFIG_PATH" "$CONFIG_PATH"
fi

# 公式 entrypoint に委譲（権限降格、venv有効化、スキル同期、hermes 起動を行う）
exec "$OFFICIAL_ENTRYPOINT" "$@"
