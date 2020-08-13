xquery version "3.1";

declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace response = "http://exist-db.org/xquery/response";

(:   :let $user := "admin"
let $pass := "foo"
:)
let $id := request:get-parameter('id', '')
let $new := request:get-parameter('value', '')
let $fileName := request:get-parameter('fileName', '')
let $filePath := request:get-parameter('filePath', '')
let $uniq :=  request:get-parameter('uniq','')
let $original-title := request:get-parameter('original-title','')
let $title := request:get-parameter('title','')
let $below := xs:boolean(request:get-parameter('below','true'))

let $foo1 := response:set-header("Access-Control-Allow-Origin", "*")
let $word := doc(concat($filePath, '/', $fileName))//html:span[@id = $id]

let $line := $word/..
let $line_to_insert : = <html:div id='{$uniq}_holder'  class='inserted_line_holder'><html:span id='{$uniq}' class='inserted_line' data-manually-confirmed='false' original-title='{$original-title}' title='{$title}' contenteditable='true'/><html:button type='button' id='{$uniq}_button' class='delete_element' aria-label='Close' ><html:span aria-hidden='true'>x</html:span></html:button></html:div>
let $foo3 := 
    if ($below) then 
            update  insert $line_to_insert following $line
        else
            update insert $line_to_insert preceding $line

return
    <html>
        <body>
    <p>
    filePath: {$filePath}
    </p>
    <p>
    fileName: {$fileName}
    </p>
    <p>
        ID: {$id}
        </p>
        <p>Foo3: {$foo3}
        </p>
    </body>
    </html>
