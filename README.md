# Overview
pyxform-http is a Flask-based web service that uses pyxform to convert a XLSForm to an ODK XForm. Thanks to [Alex Patow](https://www.alexpatow.com) for doing much of the actual work on this in [xlsform-api](https://github.com/alexpatow).

# Install requirements
* Python 3
* Java 8

# Run locally
```
pip install --requirement requirements.txt
FLASK_APP=app/main.py:app FLASK_DEBUG=1 flask run --port=5001
```

# Run in Docker
```
docker build --tag pyxform-http .
docker run --detach --publish 5001:80 pyxform-http
```

# Test forms

```
bash test.sh
```

The test script builds, runs, stops, and removes a pyxform-http-tester container

# Notes

* We use port 5001 because 5000 is used by ControlCenter on macOS. 
