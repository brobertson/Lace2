xquery version "3.1";

declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace response = "http://exist-db.org/xquery/response";

(:   :let $user := "admin"
let $pass := "foo"
:)
let $dbroot := "/db/Lace2Data/texts/"
let $id := request:get-parameter('id', '')
let $fileName := request:get-parameter('fileName', '')
let $filePath := request:get-parameter('filePath', '')

(:  logs into the collection :)
  
let $dbpath := concat($dbroot, $filePath)
let $file := concat($dbpath, '/', $fileName)
(: 
let $login := xmldb:login($dbpath, $user, $pass)
:)

let $foo1 := response:set-header("Access-Control-Allow-Origin", "*")
let $button_div := doc($file)//html:div[@id = $id]

 
let $foo3 := update delete $button_div
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
        <p>Button div: {$button_div}
        </p>
        <p>foo3: {$foo3}</p>
    </body>
    </html>

