FROM python:3.12-slim
WORKDIR /app
COPY hello.py /app/hello.py
CMD ["python", "hello.py"]
