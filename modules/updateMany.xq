xquery version "3.1";
declare namespace xh="http://www.w3.org/1999/xhtml";

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

let $fileName := request:get-parameter('fileName', '')
let $collectionPath := request:get-parameter('filePath', '')

let $query := request:get-parameter('query', '')
let $correctedForm := request:get-parameter('correctedForm','')


let $search-results := collection($collectionPath)//xh:span[@class='ocr_word'][text()=$query]
let $count := count($search-results)

(:  
let $foo1 := update value $search-results/@data-manually-confirmed with 'true'
:)
let $foo2 := update value $search-results with $correctedForm

return
<html>
<body>
    <p>'{$query}' corrected to '{$correctedForm}' {$count} times.</p>
</body>
</html>
