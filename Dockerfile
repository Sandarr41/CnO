# syntax=docker/dockerfile:1.7

# Base image
FROM python:3.12.2-slim AS base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Builder stage
FROM base AS builder

# Устанавливаем системные зависимости (если нужны)
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Копируем только зависимости
COPY requirements.txt .

# Создаем venv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM base AS runtime

# Создаем non-root пользователя
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Копируем виртуальное окружение
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Копируем только нужный код
COPY agent/ ./agent/
COPY models/ ./models/
COPY services/ ./services/
COPY ui/ ./ui/
COPY app.py .
COPY emails.jsonl .

# Создаем директорию для данных
RUN mkdir -p /app/data && chown -R appuser:appuser /app

# Обязательный volume для email-хранилища
VOLUME ["/app/data"]

USER appuser

EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import socket; s=socket.socket(); s.connect(('localhost',7860))" || exit 1

CMD ["python", "app.py"]
