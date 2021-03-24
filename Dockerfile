FROM python:3.9-alpine

COPY requirements.txt /tmp/ 
RUN pip install --requirement /tmp/requirements.txt

RUN apk --update add openjdk11-jre-headless

COPY ./app /app
WORKDIR /app

CMD ["waitress-serve", "--port=80", "--call", "main:app"]
