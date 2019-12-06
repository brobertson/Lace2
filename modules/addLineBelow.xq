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

let $foo1 := response:set-header("Access-Control-Allow-Origin", "*")
let $word := doc(concat($filePath, '/', $fileName))//html:span[@id = $id]

let $line := $word/..
let $foo3 := update  insert <html:div id='{$uniq}_div' classs='inserted_line_div'><html:span id='{$uniq}' class='inserted_line' data-manually-confirmed='false' contenteditable='true'/><html:button type='button' id='{$uniq}_button' class='close' aria-label='Close' onclick='delete_added_line(this)'><html:span aria-hidden='true'>x</html:span></html:button></html:div> following $line

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
