FROM nousresearch/hermes-agent:latest

ENV PATH="\
/opt/data/tools/uv/bin:\
/opt/data/tools/gcloud/sdk/bin:\
/opt/data/tools/gws/install/bin:\
/opt/data/tools/agent-browser/install/bin:\
/opt/hermes/.venv/bin:\
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    export UV_UNMANAGED_INSTALL=/usr/local/bin; \
    curl -LsSf https://astral.sh/uv/install.sh | sh

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
COPY env.defaults /usr/local/share/hermes/env.defaults
COPY bin/ /usr/local/share/hermes/bin/
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh
