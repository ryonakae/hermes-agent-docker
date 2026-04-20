FROM nousresearch/hermes-agent:latest

ARG GWS_VERSION=0.22.3
ARG AGENT_BROWSER_VERSION=0.24.1

ENV GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    export UV_UNMANAGED_INSTALL=/usr/local/bin; \
    curl -LsSf https://astral.sh/uv/install.sh | sh

# gcloud CLI
RUN set -eu; \
    arch=$(uname -m); \
    case "$arch" in \
      x86_64)  archive_name="google-cloud-cli-linux-x86_64.tar.gz" ;; \
      arm64|aarch64) archive_name="google-cloud-cli-linux-arm.tar.gz" ;; \
      *) echo "未対応のCPUアーキテクチャ: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$archive_name" \
      | tar -xz -C /usr/local/lib; \
    ln -s /usr/local/lib/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud; \
    ln -s /usr/local/lib/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil

# gws (Google Workspace CLI)
RUN npm install -g "@googleworkspace/cli@${GWS_VERSION}"

# gws ラッパースクリプト
COPY bin/gws/ /tmp/gws-wrappers/
RUN cp -f /tmp/gws-wrappers/* "$(dirname "$(which gws)")/" && rm -rf /tmp/gws-wrappers

# agent-browser CLI + Chrome for Testing
# 公式同梱の Playwright は headless shell のみで agent-browser が認識しないため、
# フルブラウザを /opt/hermes に焼き込む（bind mount で隠れない場所）
RUN npm install -g "agent-browser@${AGENT_BROWSER_VERSION}" \
    && HOME=/opt/hermes agent-browser install \
    && ln -s /opt/hermes/.agent-browser/browsers/chrome-*/chrome \
             /usr/local/bin/agent-browser-chrome
ENV AGENT_BROWSER_EXECUTABLE_PATH=/usr/local/bin/agent-browser-chrome

# 必要なaptパッケージをここに追記する
RUN set -eu; \
    extra_apt_packages=' \
      # 例: ffmpeg \
      # 例: imagemagick \
    '; \
    extra_apt_packages="$(printf '%s\n' "$extra_apt_packages" | sed 's/#.*//' | xargs)"; \
    if [ -n "$extra_apt_packages" ]; then \
      apt-get update; \
      apt-get install -y --no-install-recommends $extra_apt_packages; \
      rm -rf /var/lib/apt/lists/*; \
    fi

# 必要なPythonパッケージをここに追記する
RUN set -eu; \
    extra_python_packages=' \
      # 例: requests \
      # 例: pandas \
    '; \
    extra_python_packages="$(printf '%s\n' "$extra_python_packages" | sed 's/#.*//' | xargs)"; \
    if [ -n "$extra_python_packages" ]; then \
      pip install --break-system-packages $extra_python_packages; \
    fi

COPY config.defaults.yaml /usr/local/share/hermes/config.defaults.yaml
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh
