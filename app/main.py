# -*- coding: utf-8 -*-

import logging
from tempfile import TemporaryDirectory
import os.path

from flask import Flask, jsonify, request, escape
from pyxform import xls2xform
from uuid import uuid4 as uuid
from urllib.parse import unquote


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
        if xlsform_formid_fallback_header is not None:
            xlsform_formid_fallback = sanitize(xlsform_formid_fallback_header)
        else:
            xlsform_formid_fallback = str(uuid())

        request_data = request.get_data()

        file_ext = ".xlsx" if has_zip_magic_number(request_data) else ".xls"

        with TemporaryDirectory() as temp_dir_name:
            try:
                with open(
                    os.path.join(temp_dir_name, xlsform_formid_fallback + ".xml"), "w+"
                ) as xform, open(
                    os.path.join(temp_dir_name, xlsform_formid_fallback + file_ext),
                    "wb",
                ) as xlsform:
                    xlsform.write(request_data)
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


def has_zip_magic_number(buffer):
    # https://github.com/h2non/filetype.py/blob/master/filetype/types/archive.py#L54
    return (
        len(buffer) > 3
        and buffer[0] == 0x50
        and buffer[1] == 0x4B
        and (buffer[2] == 0x3 or buffer[2] == 0x5 or buffer[2] == 0x7)
        and (buffer[3] == 0x4 or buffer[3] == 0x6 or buffer[3] == 0x8)
    )


def sanitize(string):
    return os.path.basename(escape(unquote(string)))


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
