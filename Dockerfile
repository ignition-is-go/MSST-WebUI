# Multi-stage build for MSST-WebUI
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies and uv
RUN apt-get update && apt-get install -y \
    curl \
    git \
    cmake \
    build-essential \
    libsamplerate0-dev \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

ENV PATH="/root/.local/bin:$PATH"

# Install Python dependencies first (better caching)
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

# Copy custom librosa wheel and install it
COPY tools/webUI_for_clouds/librosa-0.9.2-py3-none-any.whl ./
RUN ls -la librosa-0.9.2-py3-none-any.whl && \
    uv remove librosa || true && \
    uv add ./librosa-0.9.2-py3-none-any.whl

# Production stage
FROM python:3.11-slim as production

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    python3-dev \
    ffmpeg \
    libsndfile1 \
    curl \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

ENV PATH="/root/.local/bin:$PATH"

# Copy uv and installed packages from builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/pyproject.toml /app/uv.lock ./
COPY --from=builder /app/librosa-0.9.2-py3-none-any.whl ./

# Copy essential application files only
COPY webUI.py ./
COPY configs_backup/ ./configs/
COPY data_backup/ ./data_backup/
COPY inference/ ./inference/
COPY modules/ ./modules/
COPY utils/ ./utils/
COPY webui/ ./webui/
COPY tools/ ./tools/
COPY train/ ./train/

# Create necessary directories and initialize data from backup
RUN mkdir -p cache tmpdir logs results input pretrain data && \
    cp -r data_backup/* data/ && \
    ls -la data/

EXPOSE 7860

CMD ["uv", "run", "webUI.py", "--use_cloud", "--ip_address", "0.0.0.0", "--port", "7860", "--debug"]
