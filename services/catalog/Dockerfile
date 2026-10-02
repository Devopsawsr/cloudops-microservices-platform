FROM python:3.12-alpine
WORKDIR /app
COPY packages/common /app/common
COPY services/catalog /app/service
ENV PYTHONPATH=/app
ENV DATA_DIR=/data
EXPOSE 8080
CMD ["python3", "/app/service/app.py"]
