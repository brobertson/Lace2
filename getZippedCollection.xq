xquery version "3.1";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace compression = "http://exist-db.org/xquery/compression";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace functx="http://www.functx.com";
declare function local:get-datatype($filename as xs:string) as xs:string {
    let $extension := functx:substring-after-last($filename,'.')
    return 
        if ($extension = 'svg') then 
            'image/svg+xml'
        else if ($extension = 'xql') then
            'application/xml'
        else if (($extension = 'xml') || ($extension = 'html') || ($extension = 'xconf')) then
            'text/xml'

        else
            'text'
};


declare function local:make-sources( $path as xs:string, $format as xs:string)  as item()* {
    if ($path = '') then
       error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $path || '"')
    else 
        for $page in collection($path)
            return
                if ($format = "xar") then
                    <entry name="{util:document-name($page)}" type='{local:get-datatype(util:document-name($page))}' method='deflate'>
                        {$page}
                    </entry>
                else if ($format = "text") then
                    <entry name="{fn:tokenize(util:document-name($page), '\.')[1] || '.txt'}" type='text' method='store'>
                        {transform:transform($page, doc("resources/xslt/hocr_to_plain_text.xsl"), <parameters/>)}
                    </entry>
                else
                    <wha/>
} ;

declare function local:collection-local-name($path as xs:string) as xs:string {
    let $a := tokenize(util:collection-name($path||'/f'),'/')
    return 
        $a[count($a)]
};

let $collectionUri := xs:string(request:get-parameter('collectionUri', ''))
let $format := xs:string(request:get-parameter('format','xar'))
let $collectionSuffix := 
if ($format = "xar") then
        "xar"
    else
        "zip"
let $collectionName := local:collection-local-name($collectionUri) || "." || $collectionSuffix
let $col :=  local:make-sources($collectionUri, $format)
return
    response:stream-binary(
        xs:base64Binary(compression:zip($col, true()) ),
    'application/zip',
        $collectionName)
