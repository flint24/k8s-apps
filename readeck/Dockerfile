FROM debian:bookworm-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download arm64 Readeck binary
RUN curl -L -o readeck https://codeberg.org/readeck/readeck/releases/download/v0.16.0/readeck-0.16.0-linux-arm64

RUN chmod +x readeck

# Expose Readeck's default port
EXPOSE 8000

# Start Readeck
ENTRYPOINT ["./readeck", "serve"]
