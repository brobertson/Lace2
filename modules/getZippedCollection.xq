xquery version "3.1";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace compression = "http://exist-db.org/xquery/compression";
import module namespace response = "http://exist-db.org/xquery/response";

declare function local:make-sources( $path as xs:string)  as item()* {
for $page in collection(xmldb:encode-uri($path))
  let $docnum := 5
  return
  <entry name="{$page}" type='text' method='store'>
    {doc(concat($path,$page))}
</entry>
} ;

let $collectionUri := request:get-parameter('collectionUri', '')
let $col := 
  <entry name="samiam3.html" type='text' method='store'>
    {doc("/db/Lace2Data/texts/992552838/2018-07-26-08-00_oxford_lunate-00044700.pyrnn.gz_selected_hocr_output/992552838_0003.html")}
</entry>
let $col := local:make-sources($collectionUri)
return
    response:stream-binary(
        xs:base64Binary(compression:zip($col, false()) ),
    'application/zip',
        "foo.zip")
