FROM tiangolo/uwsgi-nginx-flask:python3.7-alpine3.8

COPY requirements.txt /tmp/ 
RUN pip install --upgrade pip 
RUN pip install -r /tmp/requirements.txt

RUN apk --update add openjdk8-jre-base

COPY ./app /app
