xquery version "3.0";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace config = "http://exist-db.org/xquery/securitymanager";

let $fullPath := request:get-parameter('doc', '')
let $fileName := request:get-parameter('fileName', '')
let $svgFileName := replace($fileName,".html",".svg")
let $collectionPath := request:get-parameter('filePath', '')
let $svgDirName := "SVG"
let $SvgCollectionPath := $collectionPath || "/" || $svgDirName
let $fullPath := $collectionPath || '/' || $fileName
let $unused0 := response:set-header("Access-Control-Allow-Origin", "*")
let $svg_in_xml := fn:parse-xml(request:get-parameter('svg',''))
let $unused1 := 
    if (not(xmldb:collection-available($SvgCollectionPath))) then
        xmldb:create-collection($collectionPath, $svgDirName)
    else
        "foo"
let $unused2 := xmldb:store($SvgCollectionPath, $svgFileName, 
$svg_in_xml, "image/svg+xml")

(:  
let $confirmed_count := count(doc($fullPath)//xh:span[@data-manually-confirmed="true"])
  
let $unused3 := 
if (exists($page/@data-confirmed-word-count)) then
    update value $page/@data-confirmed-word-count with $confirmed_count
else
    update insert attribute data-confirmed-word-count {$confirmed_count} into $page
:)
return 
    
    if (not(xmldb:collection-available($collectionPath))) then (
        let $sowhat := response:set-status-code(400)
        return
            "Error! This path is not in the database: '" || $collectionPath || "'"
    )
    else if(not(doc-available($fullPath))) then (
        let $sowhat := response:set-status-code(400)
        return
            "Error! The file '" || $fileName || "' is not in the collection at: '" || $collectionPath || "'"
    )
    else if(not(sm:has-access(xs:anyURI($fullPath), "rw-"))) then (
        let $sowhat := response:set-status-code(400)
        return
            "Error! the user guest does not have access to file '" || $fullPath
        )
    else (
        $svg_in_xml
    )
