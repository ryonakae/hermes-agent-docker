#!/bin/sh
set -eu

TEMPLATE_CONFIG_PATH=/usr/local/share/hermes/config.defaults.yaml
OFFICIAL_ENTRYPOINT=/opt/hermes/docker/entrypoint.sh

DATA_DIR=/opt/data
CONFIG_PATH=$DATA_DIR/config.yaml
TOOLS_DIR=$DATA_DIR/tools
GCLOUD_ROOT_DIR=$TOOLS_DIR/gcloud
GCLOUD_DIR=$GCLOUD_ROOT_DIR/sdk
GCLOUD_VERSION_FILE=$GCLOUD_DIR/.installed-version
GWS_ROOT_DIR=$TOOLS_DIR/gws
GWS_DIR=$GWS_ROOT_DIR/install
GWS_VERSION_FILE=$GWS_DIR/.installed-version
GWS_PACKAGE_VERSION=0.22.3
AGENT_BROWSER_ROOT_DIR=$TOOLS_DIR/agent-browser
AGENT_BROWSER_DIR=$AGENT_BROWSER_ROOT_DIR/install
AGENT_BROWSER_VERSION_FILE=$AGENT_BROWSER_DIR/.installed-version
AGENT_BROWSER_PACKAGE_VERSION=0.24.1
AGENT_BROWSER_BROWSERS_DIR=${PLAYWRIGHT_BROWSERS_PATH:-$AGENT_BROWSER_ROOT_DIR/browsers}
UV_CACHE=${UV_CACHE_DIR:-$TOOLS_DIR/cache/uv}
UV_TOOLS_DIR=${UV_TOOL_DIR:-$TOOLS_DIR/uv/tools}
UV_BIN_DIR=${UV_TOOL_BIN_DIR:-$TOOLS_DIR/uv/bin}
UV_PYTHON_DIR=${UV_PYTHON_INSTALL_DIR:-$TOOLS_DIR/uv/python}
UV_PYTHON_BIN=${UV_PYTHON_BIN_DIR:-$UV_BIN_DIR}

export CLOUDSDK_CONFIG="${CLOUDSDK_CONFIG:-$GCLOUD_ROOT_DIR/config}"
export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="${GOOGLE_WORKSPACE_CLI_CONFIG_DIR:-$GWS_ROOT_DIR/config}"
export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND="${GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND:-file}"
export NPM_CONFIG_CACHE="${NPM_CONFIG_CACHE:-$TOOLS_DIR/cache/npm}"
export PLAYWRIGHT_BROWSERS_PATH="$AGENT_BROWSER_BROWSERS_DIR"
export UV_CACHE_DIR="$UV_CACHE"
export UV_TOOL_DIR="$UV_TOOLS_DIR"
export UV_TOOL_BIN_DIR="$UV_BIN_DIR"
export UV_PYTHON_INSTALL_DIR="$UV_PYTHON_DIR"
export UV_PYTHON_BIN_DIR="$UV_PYTHON_BIN"
export UV_PYTHON_INSTALL_BIN="${UV_PYTHON_INSTALL_BIN:-1}"
export PATH="$UV_BIN_DIR:$GCLOUD_DIR/bin:$GWS_DIR/bin:$AGENT_BROWSER_DIR/bin:$PATH"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

ensure_writable_dir() {
  dir=$1
  mkdir -p "$dir"
  if [ ! -w "$dir" ]; then
    fail "書き込みできません: $dir"
  fi
}

seed_if_missing() {
  src=$1
  dst=$2
  mode=${3:-}

  if [ -f "$dst" ]; then
    return
  fi

  cp "$src" "$dst"
  if [ -n "$mode" ]; then
    chmod "$mode" "$dst"
  fi
}

read_gcloud_version() {
  if [ -f "$GCLOUD_DIR/VERSION" ]; then
    tr -d '\r\n' < "$GCLOUD_DIR/VERSION"
  fi
}

read_gws_version() {
  package_json=$GWS_DIR/lib/node_modules/@googleworkspace/cli/package.json
  if [ -f "$package_json" ]; then
    sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$package_json" | head -n 1
  fi
}

read_agent_browser_version() {
  package_json=$AGENT_BROWSER_DIR/lib/node_modules/agent-browser/package.json
  if [ -f "$package_json" ]; then
    sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$package_json" | head -n 1
  fi
}

install_gcloud() {
  if [ -x "$GCLOUD_DIR/bin/gcloud" ] && "$GCLOUD_DIR/bin/gcloud" version >/dev/null 2>&1; then
    installed_version=$(read_gcloud_version || true)
    if [ -n "${installed_version:-}" ]; then
      printf '%s\n' "$installed_version" > "$GCLOUD_VERSION_FILE"
    fi
    return
  fi

  arch=$(uname -m)
  case "$arch" in
    x86_64)
      archive_name="google-cloud-cli-linux-x86_64.tar.gz"
      ;;
    arm64|aarch64)
      archive_name="google-cloud-cli-linux-arm.tar.gz"
      ;;
    *)
      fail "未対応のCPUアーキテクチャです: $arch"
      ;;
  esac

  tmp_dir=$(mktemp -d)
  archive_path="$tmp_dir/$archive_name"
  archive_url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$archive_name"

  cleanup_tmp_dir() {
    rm -rf "$tmp_dir"
  }
  trap cleanup_tmp_dir EXIT INT TERM

  curl -fsSL "$archive_url" -o "$archive_path"
  tar -xzf "$archive_path" -C "$tmp_dir"

  rm -rf "$GCLOUD_DIR"
  cp -a "$tmp_dir/google-cloud-sdk" "$GCLOUD_DIR"

  installed_version=$(read_gcloud_version || true)
  if [ -n "${installed_version:-}" ]; then
    printf '%s\n' "$installed_version" > "$GCLOUD_VERSION_FILE"
  fi

  trap - EXIT INT TERM
  cleanup_tmp_dir
}

install_gws() {
  if [ -x "$GWS_DIR/bin/gws" ]; then
    installed_version=$(read_gws_version || true)
    if [ "${installed_version:-}" = "$GWS_PACKAGE_VERSION" ] && "$GWS_DIR/bin/gws" --version >/dev/null 2>&1; then
      printf '%s\n' "$installed_version" > "$GWS_VERSION_FILE"
      return
    fi
  fi

  rm -rf "$GWS_DIR"
  mkdir -p "$GWS_DIR"
  npm install -g --prefix "$GWS_DIR" "@googleworkspace/cli@$GWS_PACKAGE_VERSION"
  if ! "$GWS_DIR/bin/gws" --version >/dev/null 2>&1; then
    fail "gws の起動確認に失敗しました。導入版: @googleworkspace/cli@$GWS_PACKAGE_VERSION"
  fi
  installed_version=$(read_gws_version || true)
  if [ "${installed_version:-}" != "$GWS_PACKAGE_VERSION" ]; then
    fail "gws の導入バージョンが想定と一致しません。期待値: $GWS_PACKAGE_VERSION 実際: ${installed_version:-unknown}"
  fi
  printf '%s\n' "$installed_version" > "$GWS_VERSION_FILE"
}

install_agent_browser() {
  if [ -x "$AGENT_BROWSER_DIR/bin/agent-browser" ]; then
    installed_version=$(read_agent_browser_version || true)
    if [ "${installed_version:-}" != "$AGENT_BROWSER_PACKAGE_VERSION" ] || ! "$AGENT_BROWSER_DIR/bin/agent-browser" --version >/dev/null 2>&1; then
      rm -rf "$AGENT_BROWSER_DIR"
    fi
  fi

  if [ ! -x "$AGENT_BROWSER_DIR/bin/agent-browser" ]; then
    mkdir -p "$AGENT_BROWSER_DIR"
    npm install -g --prefix "$AGENT_BROWSER_DIR" "agent-browser@$AGENT_BROWSER_PACKAGE_VERSION"
  fi

  if ! "$AGENT_BROWSER_DIR/bin/agent-browser" --version >/dev/null 2>&1; then
    fail "agent-browser の起動確認に失敗しました。導入版: agent-browser@$AGENT_BROWSER_PACKAGE_VERSION"
  fi

  installed_version=$(read_agent_browser_version || true)
  if [ "${installed_version:-}" != "$AGENT_BROWSER_PACKAGE_VERSION" ]; then
    fail "agent-browser の導入バージョンが想定と一致しません。期待値: $AGENT_BROWSER_PACKAGE_VERSION 実際: ${installed_version:-unknown}"
  fi

  "$AGENT_BROWSER_DIR/bin/agent-browser" install
  printf '%s\n' "$installed_version" > "$AGENT_BROWSER_VERSION_FILE"
}

# ツール用ディレクトリの初期化
ensure_writable_dir "$DATA_DIR"
ensure_writable_dir "$TOOLS_DIR"
ensure_writable_dir "$CLOUDSDK_CONFIG"
ensure_writable_dir "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR"
ensure_writable_dir "$NPM_CONFIG_CACHE"
ensure_writable_dir "$AGENT_BROWSER_ROOT_DIR"
ensure_writable_dir "$AGENT_BROWSER_BROWSERS_DIR"
ensure_writable_dir "$UV_CACHE_DIR"
ensure_writable_dir "$UV_TOOL_DIR"
ensure_writable_dir "$UV_TOOL_BIN_DIR"
ensure_writable_dir "$UV_PYTHON_INSTALL_DIR"
ensure_writable_dir "$UV_PYTHON_BIN_DIR"

# ツールのインストール
install_gcloud
install_gws
install_agent_browser

# カスタム設定を seed する（公式 entrypoint のデフォルト seed より先に実行）
seed_if_missing "$TEMPLATE_CONFIG_PATH" "$CONFIG_PATH"

# 公式 entrypoint に委譲（権限降格、venv有効化、スキル同期、hermes 起動を行う）
exec "$OFFICIAL_ENTRYPOINT" "$@"
