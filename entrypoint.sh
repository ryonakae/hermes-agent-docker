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

# .env の seed とカスタム変数のマージ
OFFICIAL_ENV_EXAMPLE=/opt/hermes/.env.example
CUSTOM_ENV_DEFAULTS=/usr/local/share/hermes/env.defaults
ENV_PATH=$DATA_DIR/.env

if [ ! -f "$ENV_PATH" ]; then
  if [ -f "$OFFICIAL_ENV_EXAMPLE" ]; then
    cp "$OFFICIAL_ENV_EXAMPLE" "$ENV_PATH"
  else
    touch "$ENV_PATH"
  fi
fi

if [ -f "$CUSTOM_ENV_DEFAULTS" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '#'*|'') continue ;;
    esac
    key="${line%%=*}"
    if ! grep -q "^${key}=" "$ENV_PATH"; then
      printf '%s\n' "$line" >> "$ENV_PATH"
    fi
  done < "$CUSTOM_ENV_DEFAULTS"
fi

# 公式 entrypoint に委譲（権限降格、venv有効化、スキル同期、hermes 起動を行う）
exec "$OFFICIAL_ENTRYPOINT" "$@"
