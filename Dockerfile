ARG PLAYWRIGHT_TAG=v1.44.0-jammy
ARG PLAYWRIGHT_VERSION=1.44.0
ARG CHROME_VERSION=124
FROM mcr.microsoft.com/playwright/python:${PLAYWRIGHT_TAG}

WORKDIR /app

RUN apt-get update && apt-get install -y xvfb netcat-openbsd git wget gnupg jq unzip --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Install exact Chrome version via Chrome for Testing
ARG CHROME_VERSION
RUN FULL_VERSION=$(wget -qO- "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json" \
        | python3 -c "import sys,json; data=json.load(sys.stdin); versions=[v for v in data['versions'] if v['version'].startswith('${CHROME_VERSION}.')]; url=versions[-1]['downloads']['chrome'][-1]['url'] if versions else ''; print(url)" \
    ) \
    && wget -q -O /tmp/chrome.zip "$FULL_VERSION" \
    && unzip /tmp/chrome.zip -d /opt/chrome-cft \
    && ln -sf /opt/chrome-cft/chrome-linux64/chrome /usr/local/bin/google-chrome \
    && rm /tmp/chrome.zip

COPY requirements.txt start.sh ./
ARG PLAYWRIGHT_VERSION
RUN pip install -r requirements.txt playwright==${PLAYWRIGHT_VERSION} && chmod +x start.sh

ENV SOCKS_PORT=9050
ENV CONTROL_PORT=9051
ENV API_PORT=5000

CMD ["./start.sh"]
