#!/usr/bin/env bash
set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBUI_DIR="$REPO_DIR/hermes-webui"
DATA_DIR="$REPO_DIR/hermes-data"
STATE_DIR="$DATA_DIR/webui"
LOG_FILE="$STATE_DIR/server.log"
PID_FILE="$STATE_DIR/server.pid"

export HERMES_HOME="$DATA_DIR"
export HERMES_WEBUI_HOST="127.0.0.1"
export HERMES_WEBUI_PORT="8787"
export HERMES_WEBUI_STATE_DIR="$STATE_DIR"

is_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

setup_venv() {
  echo "仮想環境を作成して依存関係をインストールします..."
  cd "$WEBUI_DIR"
  uv venv venv
  uv pip install --python venv/bin/python -r requirements.txt
}

case "${1:-}" in
  start)
    if is_running; then
      echo "WebUI は既に起動中です (PID: $(cat "$PID_FILE"))"
      exit 0
    fi
    mkdir -p "$STATE_DIR"
    cd "$WEBUI_DIR"
    if [ ! -d venv ]; then
      setup_venv
    fi
    source venv/bin/activate
    nohup python server.py >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "WebUI を起動しました (PID: $!) → http://127.0.0.1:8787"
    ;;
  stop)
    if is_running; then
      pid=$(cat "$PID_FILE")
      kill "$pid"
      rm -f "$PID_FILE"
      echo "WebUI を停止しました (PID: $pid)"
    else
      rm -f "$PID_FILE"
      echo "WebUI は起動していません"
    fi
    ;;
  restart)
    "$0" stop
    "$0" start
    ;;
  status)
    if is_running; then
      echo "WebUI は起動中です (PID: $(cat "$PID_FILE")) → http://127.0.0.1:8787"
    else
      echo "WebUI は停止しています"
    fi
    ;;
  logs)
    if [ -f "$LOG_FILE" ]; then
      tail -f "$LOG_FILE"
    else
      echo "ログファイルがありません: $LOG_FILE"
      exit 1
    fi
    ;;
  setup)
    cd "$WEBUI_DIR"
    if [ -d venv ]; then
      echo "仮想環境を再作成します..."
      rm -rf venv
    fi
    setup_venv
    echo "セットアップ完了"
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status|logs|setup}"
    exit 1
    ;;
esac
