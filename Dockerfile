FROM tiangolo/uwsgi-nginx-flask:python3.7

COPY requirements.txt /tmp/
RUN pip install -r /tmp/requirements.txt

RUN apt-get update && apt-get install -y openjdk-8-jre-headless
# Needed to prevent Java from AWTError Assistive Technology not found
RUN sed -i -e '/^assistive_technologies=/s/^/#/' /etc/java-*-openjdk/accessibility.properties

COPY ./app /app
