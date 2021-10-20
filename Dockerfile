FROM python:3.7-alpine

COPY requirements.txt /tmp/ 
RUN pip install --requirement /tmp/requirements.txt

RUN apk --update add openjdk8-jre-base

COPY ./app /app
WORKDIR /app

CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "5", "--timeout", "600", "--max-requests", "1", "--max-requests-jitter", "3", "main:app()"]
