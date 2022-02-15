# Overview
pyxform-http is a Flask-based web service that uses pyxform to convert a XLSForm to an ODK XForm. Thanks to [Alex Patow](https://www.alexpatow.com) for doing much of the actual work on this in [xlsform-api](https://github.com/alexpatow).

# Install requirements
* Python 3
* Java 8

# Run locally
```
pip install --requirement requirements.txt
FLASK_APP=app/main.py:app FLASK_DEBUG=1 flask run
```

# Run in Docker
```
docker build --tag pyxform-http .
docker run --detach --publish 5001:80 pyxform-http
```

# Test forms

A form that converts successfully (with chunked encoding!)
```
curl --request POST --header "X-XlsForm-FormId-Fallback: pyxform-clean" --header 'Transfer-Encoding: chunked' --data-binary @test/pyxform-clean.xlsx http://127.0.0.1:5001/api/v1/convert
```

A form that fails to convert and returns a pyxform error
```
curl --request POST --header "X-XlsForm-FormId-Fallback: pyxform-error" --data-binary @test/pyxform-error.xlsx http://127.0.0.1:5001/api/v1/convert
```

A form that converts successfully and also returns pyxform warnings
```
curl --request POST --header "X-XlsForm-FormId-Fallback: pyxform-warning" --data-binary @test/pyxform-warning.xlsx http://127.0.0.1:5001/api/v1/convert
```

A form that passes pyxform's internal checks, but fails ODK Validate's checks
```
curl --request POST --header "X-XlsForm-FormId-Fallback: validate-error" --data-binary @test/validate-error.xlsx http://127.0.0.1:5001/api/v1/convert
```

A form that converts successfully (with external choices)
```
curl --request POST --header "X-XlsForm-FormId-Fallback: external-choices" --data-binary @test/external-choices.xlsx http://127.0.0.1:5001/api/v1/convert
```

A form that converts successfully (with no id)
```
curl --request POST --data-binary @test/pyxform-clean.xlsx http://127.0.0.1:5001/api/v1/convert
```

A form that converts successfully (with percent encoded id)
```
curl --request POST --header "X-XlsForm-FormId-Fallback: example%40example.org"  --data-binary @test/pyxform-clean.xlsx http://127.0.0.1:5001/api/v1/convert
```
