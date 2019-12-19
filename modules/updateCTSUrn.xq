xquery version "3.0";
declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace response = "http://exist-db.org/xquery/response";

let $span_id := request:get-parameter('id', '')
let $action := request:get-parameter('action','add')
let $label := request:get-parameter('label', '')
let $next_sibling_id := request:get-parameter('next_sibling_id','')
let $fileName := request:get-parameter('fileName', '')
let $filePath := request:get-parameter('filePath', '')
let $value :=  request:get-parameter('value','')
let $name := request:get-parameter('name','')
let $bare_id := substring($span_id, 1, string-length($span_id) - 5)
let $button_id := $bare_id || '_kill_button'
let $filePath := concat($filePath, '/', $fileName)

let $next_sibling := doc($filePath)//html:span[@id = $next_sibling_id]

let $foo3 := if ($action = 'add') then
update  insert <html:span xmlns:html="http://www.w3.org/1999/xhtml" class="cts_picker" id="{$span_id}" data-ctsurn="{$value}" title="{$name}">📖<button class="kill_button" type='button' id="{$button_id}"> <span>×</span> </button></html:span> preceding $next_sibling
else (: assuming this is 'remove' :)
    update delete doc($filePath)//html:span[@id = $span_id]
    
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
        ID: {$bare_id}
        </p>
        <p>Foo3: {$foo3}
        </p>
    </body>
    </html>