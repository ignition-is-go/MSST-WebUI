FROM ubuntu:22.04

WORKDIR /app

# Install system dependencies and uv
RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    ffmpeg \
    libsndfile1 \
    curl \
    git \
    cmake \
    build-essential \
    libsamplerate0-dev \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.local/bin:$PATH"

# Install dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen

# Copy source code and setup
COPY . .
RUN mkdir -p cache tmpdir logs results input pretrain && \
    cp -r configs_backup configs && \
    cp -r data_backup data

CMD ["uv", "run", "webUI.py", "--use_cloud", "--ip_address", "0.0.0.0", "--port", "7860"]
