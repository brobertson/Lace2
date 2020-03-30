xquery version "3.1";
import module namespace teigeneration="http://heml.mta.ca/Lace2/teigeneration" at "teiGeneration.xql";
declare namespace dc="http://purl.org/dc/elements/1.1/";
let $my_collection := xs:string(request:get-parameter('collectionUri', ''))

(:  
let $my_collection := "/db/apps/b29006284_2019-07-10-16-32-00"
:)
let $set-content-type := response:set-header('Content-Type', 'application/tei+xml')
let $collectionName := collection($my_collection)//dc:identifier
let $set-file-name := response:set-header('Content-Disposition',  'attachment; filename="' || $collectionName ||'.tei"')
 
let $complete_tei := teigeneration:wrap_tei(teigeneration:strip_spans(teigeneration:make_all_tei($my_collection)))

let $streaming_options := 'method=xml media-type=application/tei+xml omit-xml-declaration=no indent=yes'
return
response:stream($complete_tei, $streaming_options)