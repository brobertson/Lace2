xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $urnLibrary := doc("resources/xml/urns.xml")/ctsTags

for $tag in $urnLibrary/*
    return
        map {
            "id": data($tag/@urn),
            "label": data($tag/@label)
        }

