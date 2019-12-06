xquery version "3.1";
declare namespace xh="http://www.w3.org/1999/xhtml";
declare base-uri "http://www.w3.org/1999/xhtml";

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

let $collectionPath := request:get-parameter('collectionPath', '')
let $query := request:get-parameter('query', '')
let $correctedForm := request:get-parameter('correctedForm','')
let $filtered-query := replace($query, "[&amp;&quot;-*;-`~!@#$%^*()_+-=\[\]\{\}\|';:/.,?(:]", "")
let $data-collection := '/db/laceData/830740755brucerob/2016-03-22-19-31_loeb_2016-03-20-14-17-00128200.pyrnn.gz_selected_hocr_output'

let $search-results := collection($collectionPath)//xh:span[@class='ocr_word'][text()=$query]
let $count := count($search-results)

let $processed-results :=
    for $result in $search-results
    let $foo3 := update  value $result/@data-manually-confirmed with 'true'
    let $foo4 := update value $result with $correctedForm
    return
        <p/>
return
<html>
<body>
    <p>'{$query}' corrected to '{$correctedForm}' {$count} times.</p>
</body>
</html>
