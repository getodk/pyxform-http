FROM python:3.8-alpine

COPY requirements.txt /tmp/ 
RUN pip install --requirement /tmp/requirements.txt

RUN apk --update add openjdk8-jre-base

COPY ./app /app
WORKDIR /app

CMD ["waitress-serve", "--port=80", "--call", "main:app"]
