xquery version "3.1";
import module namespace teigeneration="http://heml.mta.ca/Lace2/teigeneration" at "teiGeneration.xql";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace ctsurns="http://heml.mta.ca/Lace2/ctsurns" at "ctsUrns.xql";

declare function local:allTeiVolumes($my_collection as xs:string) as node()* {
    let $volume_refs := ctsurns:uniqueCtsUrnReferences(collection($my_collection)//xh:span[@data-ctsurn])
    for $vol in $volume_refs
    return 
         <entry name="{fn:replace($vol, ':', '_') || '.tei'}" type='xml' method='store'>
         <zoneA><zoneRaw>{teigeneration:make_tei_zone_raw($my_collection, 'primary_text')}</zoneRaw>
         <zonePruned>{teigeneration:strip_zone_of_following_other_doc(teigeneration:make_tei_zone_raw($my_collection, 'primary_text'),'urn:cts:greekLit:tlg0081.tlg003.1st1K-grc1:')}</zonePruned>
         {teigeneration:wrap_tei(teigeneration:strip_spans(teigeneration:make_all_tei($my_collection, $vol)))}
         </zoneA>
         </entry>
};

let $my_collection := xs:string(request:get-parameter('collectionUri', ''))
let $collectionName := collection($my_collection)//dc:identifier


return
    response:stream-binary(
        xs:base64Binary(compression:zip(local:allTeiVolumes($my_collection), false()) ),
    'application/zip',
        $collectionName || ".zip")
