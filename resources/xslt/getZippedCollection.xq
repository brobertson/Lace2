xquery version "3.1";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace compression = "http://exist-db.org/xquery/compression";
import module namespace response = "http://exist-db.org/xquery/response";

declare function local:make-sources( $path as xs:string, $format as xs:string)  as item()* {
 if ($path = '')
then
   error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $path || '"')
else 
for $page in collection($path)
  return
        if ($format = "xml")
 then
  <entry name="{util:document-name($page)}" type='text' method='deflate'>
     {$page}
  </entry>
  else if ($format = "text")
   then
    <entry name="{fn:tokenize(util:document-name($page), '\.')[1] || '.txt'}" type='text' method='store'>
     {transform:transform($page, doc("resources/xslt/hocr_to_plain_text.xsl"), <parameters/>)}
  </entry>
  else
      <wha/>
} ;

declare function local:collection-local-name($path as xs:string) as xs:string {
    let $a := tokenize(util:collection-name($path),'/')
    return 
        $a[count($a)]
};

let $collectionUri := xs:string(request:get-parameter('value', ''))
let $collectionName := local:collection-local-name($collectionUri) || ".zip"
let $format := xs:string(request:get-parameter('format','xml'))
let $col :=  local:make-sources($collectionUri, $format)
return
    response:stream-binary(
        xs:base64Binary(compression:zip($col, true()) ),
    'application/zip',
        $collectionName)