FROM debian:bookworm-slim

ARG BROWSERVICE_VERSION=v0.9.12.2
# Set by BuildKit to the target platform's architecture (amd64, arm64, arm).
# The legacy builder leaves it empty, so the download step falls back to dpkg.
ARG TARGETARCH

# Libraries the bundled Chromium (CEF) needs, plus Xvfb and fonts.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
        libgbm1 libpango-1.0-0 libcairo2 libasound2 libxshmfence1 libx11-6 \
        libx11-xcb1 libxcb1 libxext6 libxi6 libxtst6 libxss1 libglib2.0-0 \
        libdbus-1-3 libexpat1 libgtk-3-0 libpangocairo-1.0-0 \
        xvfb xauth fontconfig fonts-dejavu-core fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Fetch, verify and unpack the AppImage (no FUSE inside Docker). The SHA-256
# values are the digests GitHub publishes for the v0.9.12.2 release assets;
# update them together with BROWSERVICE_VERSION.
RUN target="${TARGETARCH:-$(dpkg --print-architecture)}" \
    && case "$target" in \
        amd64) arch=x86_64 \
            sha=967d3e68d48fbf58121529dc5bc67ecff0a1cb767836414d8a7344ba048cbd51 ;; \
        arm64) arch=aarch64 \
            sha=c09ffb2b2b95f18bda8fd471ff3e6a1a768faf1cf03d3809dabd18e5bb35f504 ;; \
        arm|armhf) arch=armhf \
            sha=a346b7f1980bd0ea7b9f8ccd87bea5a9ea6f88967b2b3640be8e3ed038f153f9 ;; \
        *) echo "unsupported architecture: $target" >&2; exit 1 ;; \
    esac \
    && mkdir /opt/bsv && cd /opt/bsv \
    && curl -fsSL --proto '=https' --tlsv1.2 -o bsv.AppImage \
       "https://github.com/ttalvitie/browservice/releases/download/${BROWSERVICE_VERSION}/browservice-${BROWSERVICE_VERSION}-${arch}.AppImage" \
    && echo "${sha}  bsv.AppImage" | sha256sum -c - \
    && chmod +x bsv.AppImage \
    && ./bsv.AppImage --appimage-extract >/dev/null \
    && mv squashfs-root browservice.AppDir \
    && rm bsv.AppImage

# The client page only uses onmousewheel for Chrome and IE and falls back to
# onwheel, which Safari 3-5 lack. Make old Safari take the onmousewheel path
# ("chromium" -> "safari/5", same length; Chromium still matches "chrome").
RUN so=/opt/bsv/browservice.AppDir/opt/browservice/retrojsvice.so \
    && perl -pi -e 's/ua\.indexOf\("chromium"\)/ua.indexOf("safari\/5")/g' "$so" \
    && grep -q 'ua\.indexOf("safari/5")' "$so" \
    && ! grep -q 'ua\.indexOf("chromium")' "$so"

# Run as an unprivileged user, as upstream recommends.
RUN useradd -m -u 1000 bsv
USER bsv
WORKDIR /home/bsv

EXPOSE 8080
# Navigation forwarding relies on history tricks that leave Safari 3 on a
# blank page; the control bar's own Back/Forward buttons replace it.
ENTRYPOINT ["/opt/bsv/browservice.AppDir/AppRun", \
            "--vice-opt-http-listen-addr=0.0.0.0:8080", \
            "--vice-opt-navigation-forwarding=no", \
            "--show-soft-navigation-buttons=yes", \
            "--start-page=https://duckduckgo.com/"]
