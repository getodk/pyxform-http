#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

docker build --quiet --tag pyxform-http . >/dev/null
docker run --detach --publish 5001:80 --name pyxform-http-tester pyxform-http >/dev/null

# wait for docker container to come up
sleep 1

test_failed="false"

test_1_actual=$(curl --silent --request POST --header "X-XlsForm-FormId-Fallback: pyxform-clean" --header 'Transfer-Encoding: chunked' --data-binary @test/pyxform-clean.xlsx http://127.0.0.1:5001/api/v1/convert)
test_1_expected='{"error":null,"itemsets":null,"result":"<?xml version=\"1.0\"?><h:html xmlns=\"http://www.w3.org/2002/xforms\" xmlns:ev=\"http://www.w3.org/2001/xml-events\" xmlns:h=\"http://www.w3.org/1999/xhtml\" xmlns:jr=\"http://openrosa.org/javarosa\" xmlns:odk=\"http://www.opendatakit.org/xforms\" xmlns:orx=\"http://openrosa.org/xforms\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><h:head><h:title>pyxform-clean</h:title><model odk:xforms-version=\"1.0.0\"><instance><data id=\"pyxform-clean\"><name/><age/><meta><instanceID/></meta></data></instance><bind nodeset=\"/data/name\" type=\"string\"/><bind nodeset=\"/data/age\" type=\"int\"/><bind jr:preload=\"uid\" nodeset=\"/data/meta/instanceID\" readonly=\"true()\" type=\"string\"/></model></h:head><h:body><input ref=\"/data/name\"><label>what is your name</label></input><input ref=\"/data/age\"><label>what is your age</label></input></h:body></h:html>","status":200,"warnings":[]}'
if [ "$test_1_actual" != "$test_1_expected" ]; then
  echo "test 1 failed: form that converts (with chunked encoding)"
  test_failed="true"
fi

test_2_actual=$(curl --silent --request POST --header "X-XlsForm-FormId-Fallback: pyxform-error" --data-binary @test/pyxform-error.xlsx http://127.0.0.1:5001/api/v1/convert)
test_2_expected='{"error":"Unknown question type '\''textX'\''.","itemsets":null,"result":null,"status":400,"warnings":null}'
if [ "$test_2_actual" != "$test_2_expected" ]; then
  echo "test 2 failed: form that fails to convert and returns a pyxform error"
  test_failed="true"
fi

test_3_actual=$(curl --silent --request POST --header "X-XlsForm-FormId-Fallback: pyxform-warning" --data-binary @test/pyxform-warning.xlsx http://127.0.0.1:5001/api/v1/convert)
test_3_expected='{"error":null,"itemsets":null,"result":"<?xml version=\"1.0\"?><h:html xmlns=\"http://www.w3.org/2002/xforms\" xmlns:ev=\"http://www.w3.org/2001/xml-events\" xmlns:h=\"http://www.w3.org/1999/xhtml\" xmlns:jr=\"http://openrosa.org/javarosa\" xmlns:odk=\"http://www.opendatakit.org/xforms\" xmlns:orx=\"http://openrosa.org/xforms\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><h:head><h:title>pyxform-warning</h:title><model odk:xforms-version=\"1.0.0\"><instance><data id=\"pyxform-warning\"><name/><group><age/></group><meta><instanceID/></meta></data></instance><bind nodeset=\"/data/name\" type=\"string\"/><bind nodeset=\"/data/group/age\" type=\"string\"/><bind jr:preload=\"uid\" nodeset=\"/data/meta/instanceID\" readonly=\"true()\" type=\"string\"/></model></h:head><h:body><input ref=\"/data/name\"><label>what is your name</label></input><group ref=\"/data/group\"><input ref=\"/data/group/age\"><label>what is your age</label></input></group></h:body></h:html>","status":200,"warnings":["[row : 3] Group has no label: {'\''name'\'': '\''group'\'', '\''type'\'': '\''begin group'\''}"]}'
if [ "$test_3_actual" != "$test_3_expected" ]; then
  echo "test 3 failed: form that converts and also returns pyxform warnings"
  test_failed="true"
fi

test_4_actual=$(curl --silent --request POST --header "X-XlsForm-FormId-Fallback: validate-error" --data-binary @test/validate-error.xlsx http://127.0.0.1:5001/api/v1/convert)
test_4_expected='{"error":"ODK Validate Errors:\n>> Something broke the parser. See above for a hint.\nError evaluating field '\''concat'\'' (${concat}[1]): The problem was located in Calculate expression for ${concat}\nXPath evaluation: cannot handle function '\''concatx'\''\nCaused by: org.javarosa.xpath.XPathUnhandledException: The problem was located in Calculate expression for ${concat}\nXPath evaluation: cannot handle function '\''concatx'\''\n\t... 10 more\n\nThe following files failed validation:\n${validate-error}.xml\n\nResult: Invalid","itemsets":null,"result":null,"status":400,"warnings":null}'
if [ "$test_4_actual" != "$test_4_expected" ]; then
  echo "test 4 failed: form that passes pyxform's internal checks, but fails ODK Validate's checks"
  test_failed="true"
fi

test_5_actual=$(curl --silent --request POST --header "X-XlsForm-FormId-Fallback: external-choices" --data-binary @test/external-choices.xlsx http://127.0.0.1:5001/api/v1/convert)
test_5_expected='{"error":null,"itemsets":"\"list_name\",\"name\",\"label\",\"province\",\"district\"\n\"districts\",\"district_a\",\"District A (in Province 1)\",\"province_1\",\"None\"\n\"districts\",\"district_b\",\"District B (in Province 1)\",\"province_1\",\"None\"\n\"districts\",\"district_c\",\"District C (in Province 2)\",\"province_2\",\"None\"\n\"None\",\"None\",\"None\",\"None\",\"None\"\n\"lots\",\"lot_10\",\"Lot 10 (in District A)\",\"province_1\",\"district_a\"\n\"lots\",\"lot_20\",\"Lot 20 (in District A)\",\"province_1\",\"district_a\"\n\"lots\",\"lot_30\",\"Lot 30 (In District B)\",\"province_1\",\"district_b\"\n\"lots\",\"lot_40\",\"Lot 40 (In District C)\",\"province_2\",\"district_c\"\n","result":"<?xml version=\"1.0\"?><h:html xmlns=\"http://www.w3.org/2002/xforms\" xmlns:ev=\"http://www.w3.org/2001/xml-events\" xmlns:h=\"http://www.w3.org/1999/xhtml\" xmlns:jr=\"http://openrosa.org/javarosa\" xmlns:odk=\"http://www.opendatakit.org/xforms\" xmlns:orx=\"http://openrosa.org/xforms\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><h:head><h:title>external-choices</h:title><model odk:xforms-version=\"1.0.0\"><instance><data id=\"external-choices\"><province/><district/><lot/><meta><instanceID/></meta></data></instance><bind nodeset=\"/data/province\" type=\"string\"/><bind nodeset=\"/data/district\" type=\"string\"/><bind nodeset=\"/data/lot\" type=\"string\"/><bind jr:preload=\"uid\" nodeset=\"/data/meta/instanceID\" readonly=\"true()\" type=\"string\"/></model></h:head><h:body><select1 ref=\"/data/province\"><label>Province</label><item><label>Province 1</label><value>province_1</value></item><item><label>Province 2</label><value>province_2</value></item></select1><input ref=\"/data/district\" query=\"instance('\''districts'\'')/root/item[province= /data/province ]\"><label>District</label></input><input ref=\"/data/lot\" query=\"instance('\''lots'\'')/root/item[province= /data/province  and district= /data/district ]\"><label>Lot</label></input></h:body></h:html>","status":200,"warnings":[]}'
if [ "$test_5_actual" != "$test_5_expected" ]; then
  echo "test 5 failed: form that converts (with external choices)"
  test_failed="true"
fi

# test removes uuid from actual and expected
test_6_actual=$(curl --silent --request POST --data-binary @test/pyxform-clean.xlsx http://127.0.0.1:5001/api/v1/convert | sed 's/[0-9a-f-]\{36\}//g')
test_6_expected=$(echo '{"error":null,"itemsets":null,"result":"<?xml version=\"1.0\"?><h:html xmlns=\"http://www.w3.org/2002/xforms\" xmlns:ev=\"http://www.w3.org/2001/xml-events\" xmlns:h=\"http://www.w3.org/1999/xhtml\" xmlns:jr=\"http://openrosa.org/javarosa\" xmlns:odk=\"http://www.opendatakit.org/xforms\" xmlns:orx=\"http://openrosa.org/xforms\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><h:head><h:title>pyxform-clean</h:title><model odk:xforms-version=\"1.0.0\"><instance><data id=\"a126d83c-ac40-4fd1-b3b0-9f32affacd14\"><name/><age/><meta><instanceID/></meta></data></instance><bind nodeset=\"/data/name\" type=\"string\"/><bind nodeset=\"/data/age\" type=\"int\"/><bind jr:preload=\"uid\" nodeset=\"/data/meta/instanceID\" readonly=\"true()\" type=\"string\"/></model></h:head><h:body><input ref=\"/data/name\"><label>what is your name</label></input><input ref=\"/data/age\"><label>what is your age</label></input></h:body></h:html>","status":200,"warnings":[]}' | sed 's/[0-9a-f-]\{36\}//g')
if [ "$test_6_actual" != "$test_6_expected" ]; then
  echo "test 6 failed: form that converts (with no id)"
  test_failed="true"
fi

# test removes uuid from actual and expected
test_7_actual=$(curl --silent --request POST --header "X-XlsForm-FormId-Fallback: example%40example.org" --data-binary @test/pyxform-clean.xlsx http://127.0.0.1:5001/api/v1/convert | sed 's/[0-9a-f-]\{36\}//g')
test_7_expected=$(echo '{"error":null,"itemsets":null,"result":"<?xml version=\"1.0\"?><h:html xmlns=\"http://www.w3.org/2002/xforms\" xmlns:ev=\"http://www.w3.org/2001/xml-events\" xmlns:h=\"http://www.w3.org/1999/xhtml\" xmlns:jr=\"http://openrosa.org/javarosa\" xmlns:odk=\"http://www.opendatakit.org/xforms\" xmlns:orx=\"http://openrosa.org/xforms\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><h:head><h:title>pyxform-clean</h:title><model odk:xforms-version=\"1.0.0\"><instance><data id=\"example@example.org\"><name/><age/><meta><instanceID/></meta></data></instance><bind nodeset=\"/data/name\" type=\"string\"/><bind nodeset=\"/data/age\" type=\"int\"/><bind jr:preload=\"uid\" nodeset=\"/data/meta/instanceID\" readonly=\"true()\" type=\"string\"/></model></h:head><h:body><input ref=\"/data/name\"><label>what is your name</label></input><input ref=\"/data/age\"><label>what is your age</label></input></h:body></h:html>","status":200,"warnings":[]}' | sed 's/[0-9a-f-]\{36\}//g')
if [ "$test_7_actual" != "$test_7_expected" ]; then
  echo "test 7 failed: form that converts (with percent encoded id)"
  test_failed="true"
fi

# test removes uuid from actual and expected
test_8_actual=$(curl --silent --request POST --data-binary @test/pyxform-clean.xls http://127.0.0.1:5001/api/v1/convert | sed 's/[0-9a-f-]\{36\}//g')
test_8_expected=$(echo '{"error":null,"itemsets":null,"result":"<?xml version=\"1.0\"?><h:html xmlns=\"http://www.w3.org/2002/xforms\" xmlns:ev=\"http://www.w3.org/2001/xml-events\" xmlns:h=\"http://www.w3.org/1999/xhtml\" xmlns:jr=\"http://openrosa.org/javarosa\" xmlns:odk=\"http://www.opendatakit.org/xforms\" xmlns:orx=\"http://openrosa.org/xforms\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><h:head><h:title>pyxform-clean</h:title><model odk:xforms-version=\"1.0.0\"><instance><data id=\"bbf27b70-9eb7-4659-9933-c22cb9e1451b\"><name/><age/><meta><instanceID/></meta></data></instance><bind nodeset=\"/data/name\" type=\"string\"/><bind nodeset=\"/data/age\" type=\"int\"/><bind jr:preload=\"uid\" nodeset=\"/data/meta/instanceID\" readonly=\"true()\" type=\"string\"/></model></h:head><h:body><input ref=\"/data/name\"><label>what is your name</label></input><input ref=\"/data/age\"><label>what is your age</label></input></h:body></h:html>","status":200,"warnings":[]}' | sed 's/[0-9a-f-]\{36\}//g')
if [ "$test_8_actual" != "$test_8_expected" ]; then
  echo "test 8 failed: form that converts (with no id, in XLS format)"
  test_failed="true"
fi

docker container stop pyxform-http-tester >/dev/null
docker container rm pyxform-http-tester >/dev/null

if [ "$test_failed" == "true" ] ; then
    exit 1
fi