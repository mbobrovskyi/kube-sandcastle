# --- Stage 1: Build NSJail (The Sandbox Engine) ---
FROM debian:bookworm-slim AS nsjail-builder

RUN apt-get update && apt-get install -y \
    build-essential \
    bison \
    flex \
    pkg-config \
    libnl-route-3-dev \
    libprotobuf-dev \
    protobuf-compiler \
    git \
    ca-certificates

# Cloning and building NSJail from source
RUN git clone https://github.com/google/nsjail.git /nsjail && \
    cd /nsjail && \
    make

# --- Stage 2: Build Go Worker (The Orchestrator) ---
FROM golang:1.25-bookworm AS go-builder

WORKDIR /app
# Pre-copying go.mod/sum to leverage Docker caching
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Building the worker binary
RUN go build -o /kube-sandcastle-worker ./cmd/sandcastle-worker

# --- Stage 3: Final Production Image ---
FROM debian:bookworm-slim

# Install Python and runtime libraries needed for NSJail
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libprotobuf32 \
    libnl-route-3-200 \
    && rm -rf /var/lib/apt/lists/*

# CRITICAL STEP: Copying NSJail from the builder stage
COPY --from=nsjail-builder /nsjail/nsjail /usr/bin/nsjail

# Copying the Go worker
COPY --from=go-builder /kube-sandcastle-worker /app/worker

# Setup the sandbox user (UID 2000) for unprivileged execution
RUN groupadd -g 2000 sandcastle && \
    useradd -u 2000 -g sandcastle -m sandcastle

WORKDIR /app

# The Go worker must run as root to create Linux Namespaces
# NSJail will then drop privileges to 'sandcastle' user (2000)
CMD ["/app/worker"]