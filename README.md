# Overview
pyxform-http is a Flask-based web service that uses pyxform to convert a XLSForm to an ODK XForm.

# Requirements
* Python 3
* Java

# Run locally
```
pip install -r requirements.txt
FLASK_APP=app/main.py FLASK_DEBUG=1 flask run
```

# Run in a Docker container
```
docker build -t pyxform-http .
docker run -d --name pyxform-http -p 80:80 pyxform-http
```

# Test
```
curl --request POST --data-binary @test/pyxform-clean.xlsx http://127.0.0.1/api/v1/convert
curl --request POST --data-binary @test/pyxform-error.xlsx http://127.0.0.1/api/v1/convert
curl --request POST --data-binary @test/pyxform-warning.xlsx http://127.0.0.1/api/v1/convert
curl --request POST --data-binary @test/validate-error.xlsx http://127.0.0.1/api/v1/convert
```