ARG PLAYWRIGHT_TAG=v1.44.0-jammy
ARG PLAYWRIGHT_VERSION=1.44.0
FROM mcr.microsoft.com/playwright/python:${PLAYWRIGHT_TAG}

WORKDIR /app

RUN apt-get update && apt-get install -y xvfb netcat-openbsd git --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt start.sh ./
ARG PLAYWRIGHT_VERSION
RUN pip install -r requirements.txt playwright==${PLAYWRIGHT_VERSION} && chmod +x start.sh

RUN playwright install chrome

ENV SOCKS_PORT=9050
ENV CONTROL_PORT=9051
ENV API_PORT=5000

CMD ["./start.sh"]
