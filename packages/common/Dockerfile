# Shared Python service image. Prefer services/<name>/Dockerfile in this repo.
FROM python:3.12-alpine
WORKDIR /app
COPY packages/common /app/common
ARG SERVICE
COPY services/${SERVICE} /app/service
ENV PYTHONPATH=/app
ENV DATA_DIR=/data
EXPOSE 8080
CMD ["python3", "/app/service/app.py"]
