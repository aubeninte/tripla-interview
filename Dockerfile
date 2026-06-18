# Builder
FROM python:3.11-slim AS builder

WORKDIR /terraform_parse_service

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY terraform_parse_service/requirements.txt .

# Install dependencies into a local directory wheels/ folder
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Runtime Image - Using slim to maintain glibc compatibility with the builder
FROM python:3.11-slim AS runner

WORKDIR /terraform_parse_service

RUN groupadd -g 10001 serveruser \
    && useradd -u 10001 -g serveruser -m -s /sbin/nologin serveruser

COPY --from=builder /install /usr/local

# Copy files from the service directory using the repo root as build context.
COPY --chown=serveruser:serveruser terraform_parse_service/ ./
USER serveruser
EXPOSE 8080

# gunicorn better than Flask for prod for example
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "main:app", "--workers", "2", "--threads", "4"]
