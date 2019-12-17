xquery version "3.0";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace config = "http://exist-db.org/xquery/securitymanager";

let $fileName := request:get-parameter('fileName', '')
let $svgFileName := replace($fileName,".html",".svg")
let $collectionPath := request:get-parameter('filePath', '')
let $svgDirName := "SVG"
let $SvgCollectionPath := $collectionPath || "/" || $svgDirName
let $fullPath := $collectionPath || '/' || $fileName
(:  convert svg parameter, which is  string, into xml :)
let $svg_in_xml := fn:parse-xml(request:get-parameter('svg',''))
(:  check if the SVG directory in this collection actually exists
 :  and if it doesn't, make it
 :  :)
let $unused1 := 
    if (not(xmldb:collection-available($SvgCollectionPath))) then
        xmldb:create-collection($collectionPath, $svgDirName)
    else
        "foo"
(:  store the svg file :)
let $unused2 := xmldb:store($SvgCollectionPath, $svgFileName, 
$svg_in_xml, "image/svg+xml")

return 
    (: if for some reason the SVG collection still doesn't exist, we 
    : return this error
    :)
    if (not(xmldb:collection-available($collectionPath))) then (
        let $sowhat := response:set-status-code(400)
        return
            "Error! This path is not in the database: '" || $collectionPath || "'"
    )
    (: If our saving didn't work, we throw this error 
    :)
    else if(not(doc-available($fullPath))) then (
        let $sowhat := response:set-status-code(400)
        return
            "Error! The file '" || $fileName || "' is not in the collection at: '" || $collectionPath || "'"
    )
    (: Check for erroneous permissions :)
    else if(not(sm:has-access(xs:anyURI($fullPath), "rw-"))) then (
        let $sowhat := response:set-status-code(400)
        return
            "Error! the user guest does not have access to file '" || $fullPath
        )
    (: return the xml of the SVG if everything seems ok :)
    else (
        $svg_in_xml
    )
