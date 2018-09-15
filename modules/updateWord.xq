xquery version "3.0";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace response = "http://exist-db.org/xquery/response";

let $user := "admin"
let $pass := "foo"
let $dbroot := "/db/apps/lace/data/texts/"
let $id := request:get-parameter('id', '')
let $new := request:get-parameter('value', '')
let $fileName := request:get-parameter('fileName', '')
let $filePath := request:get-parameter('filePath', '')


(:  logs into the collection :)
let $dbpath := concat($dbroot, $filePath)
let $login := xmldb:login($dbpath, $user, $pass)


let $foo1 := response:set-header("Access-Control-Allow-Origin", "*")
let $word := doc(concat($dbpath, '/', $fileName))//xh:span[@id = $id]


let $foo3 := update  value $word/@data-manually-confirmed with 'true'
let $foo4 := update value $word with $new

return 
    <html>
        <body>
            <p>
    login: {$login}
    </p>
    <p>
    filePath: {$filePath}
    </p>
    <p>
    fileName: {$fileName}
    </p>
    <p>
        ID: {$id}
        </p>
        <p>Foo1: {$foo1}
        </p>
    </body>
    </html>
