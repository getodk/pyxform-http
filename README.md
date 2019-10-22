# Overview
pyxform-http is a Flask-based web service that uses pyxform to convert a XLSForm to an ODK XForm.

# Install requirements
* Python 3
* Java

# Run locally
```
pip install --requirement requirements.txt
FLASK_APP=app/main.py FLASK_DEBUG=1 flask run
```

# Run in Docker
```
docker build --tag pyxform-http .
docker run --detach --name pyxform-http --publish 5000:5000 pyxform-http
```

# Test forms


A form that converts successfully
```
curl --request POST --header "X-XlsForm-FormId-Fallback: pyxform-clean" --data-binary @test/pyxform-clean.xlsx http://127.0.0.1:5000/api/v1/convert
```

A form that fails to convert and returns a pyxform error
```
curl --request POST --header "X-XlsForm-FormId-Fallback: pyxform-error" --data-binary @test/pyxform-error.xlsx http://127.0.0.1:5000/api/v1/convert
```

A form that converts successfully and also returns pyxform warnings
```
curl --request POST --header "X-XlsForm-FormId-Fallback: pyxform-warning" --data-binary @test/pyxform-warning.xlsx http://127.0.0.1:5000/api/v1/convert
```

A form that passes pyxform's internal checks, but fails ODK Validate's checks
```
curl --request POST --header "X-XlsForm-FormId-Fallback: validate-error" --data-binary @test/validate-error.xlsx http://127.0.0.1:5000/api/v1/convert
```