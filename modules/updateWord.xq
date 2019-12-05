xquery version "3.0";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace config = "http://exist-db.org/xquery/securitymanager";

let $id := request:get-parameter('id', '')
let $new := request:get-parameter('value', '')
let $fileName := request:get-parameter('fileName', '')
let $collectionPath := request:get-parameter('filePath', '')
let $fullPath := $collectionPath || '/' || $fileName
let $unused0 := response:set-header("Access-Control-Allow-Origin", "*")
let $word := doc($fullPath)//xh:span[@id = $id]
let $page := doc($fullPath)//xh:div[@class='ocr_page']

let $unused1 := update  value $word/@data-manually-confirmed with 'true'
let $unused2 := update value $word with $new
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
        <html>
            <body>
        <p>
        collectionPath: {$collectionPath}
        </p>
        <p>
        fileName: {$fileName}
        </p>
        <p>
            ID: {$id}
            </p>
            <p>Update of data: {$unused1}</p>
            <p>Update of word: {$unused2}</p>
        </body>
        </html>
    )
