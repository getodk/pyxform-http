# -*- coding: utf-8 -*-

import logging
from tempfile import TemporaryDirectory
import os.path

from flask import Flask, jsonify, request, escape
from pyxform import xls2xform
from uuid import uuid4 as uuid


def app():
    app = Flask(__name__)
    logger = logging.getLogger(__name__)

    @app.route("/")
    def index():
        return "Welcome to the pyxform-http! Make a POST request to '/api/v1/convert' to convert an XLSForm to an ODK XForm."

    @app.route("/api/v1/convert", methods=["POST"])
    def post():

        xlsform_formid_fallback_header = request.headers.get(
            "X-XlsForm-FormId-Fallback"
        )
        xlsform_formid_fallback = str(uuid())
        if xlsform_formid_fallback_header != None:
            xlsform_formid_fallback = sanitize(xlsform_formid_fallback_header)

        with TemporaryDirectory() as temp_dir_name:
            try:
                with open(
                    os.path.join(temp_dir_name, xlsform_formid_fallback + ".xml"), "w+"
                ) as xform, open(
                    os.path.join(temp_dir_name, xlsform_formid_fallback + ".xlsx"), "wb"
                ) as xlsform:
                    xlsform.write(request.get_data())
                    convert_status = xls2xform.xls2xform_convert(
                        xlsform_path=str(xlsform.name),
                        xform_path=str(xform.name),
                        validate=True,
                        pretty_print=False,
                    )

                    if convert_status:
                        logger.warning(convert_status)

                    if os.path.isfile(xform.name):
                        itemsets_path = os.path.join(temp_dir_name, "itemsets.csv")
                        if os.path.isfile(itemsets_path):
                            try:
                                with open(itemsets_path, "r") as itemsets:
                                    return response(
                                        status=200,
                                        result=xform.read(),
                                        itemsets=itemsets.read(),
                                        warnings=convert_status,
                                    )
                            except Exception as e:
                                logger.error(e)
                                return response(error=str(e))
                        else:
                            return response(
                                status=200, result=xform.read(), warnings=convert_status
                            )
                    else:
                        return response(error=convert_status)

            except Exception as e:
                logger.error(e)
                return response(error=str(e))

    return app


def sanitize(string):
    return os.path.basename(escape(string))


def response(status=400, result=None, itemsets=None, warnings=None, error=None):
    return (
        jsonify(
            status=status,
            result=result,
            itemsets=itemsets,
            warnings=warnings,
            error=error,
        ),
        status,
    )


if __name__ == "__main__":
    app = app()
    app.run()
