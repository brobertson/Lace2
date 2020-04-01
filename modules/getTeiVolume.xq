xquery version "3.1";
import module namespace teigeneration="http://heml.mta.ca/Lace2/teigeneration" at "teiGeneration.xql";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace ctsurns="http://heml.mta.ca/Lace2/ctsurns" at "ctsUrns.xql";

declare function local:allTeiVolumes($my_collection as xs:string) as node()* {
    let $volume_refs := ctsurns:uniqueCtsUrnReferences(collection($my_collection)//xh:span[@data-ctsurn])
    for $vol in $volume_refs
    return 
         {teigeneration:wrap_tei(teigeneration:strip_spans(teigeneration:make_all_tei($my_collection, $vol)))}
};

let $my_collection := xs:string(request:get-parameter('collectionUri', ''))
let $collectionName := collection($my_collection)//dc:identifier


return
    response:stream-binary(
        xs:base64Binary(compression:zip(local:allTeiVolumes($my_collection), false()) ),
    'application/zip',
        $collectionName || ".zip")
