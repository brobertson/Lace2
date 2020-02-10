xquery version "3.1";

declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace response = "http://exist-db.org/xquery/response";

let $id := request:get-parameter('id', '')
let $fileName := request:get-parameter('fileName', '')
let $filePath := request:get-parameter('filePath', '')

(:  logs into the collection :)
  
let $file := concat($filePath, '/', $fileName)
(: 
let $login := xmldb:login($dbpath, $user, $pass)
:)

let $foo1 := response:set-header("Access-Control-Allow-Origin", "*")
let $element_to_be_deleted := doc($file)//*[@id = $id]

 
let $foo3 := update delete $element_to_be_deleted
return
    <html>
        <body>
    <p>
    filePath: {$filePath}
    </p>
    <p>
    file: {$file}
    </p>
    <p>
        ID: {$id}
        </p>
        <p>Deleted element: {$element_to_be_deleted}
        </p>
        <p>foo3: {$foo3}</p>
    </body>
    </html>

