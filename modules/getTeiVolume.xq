xquery version "3.1";
import module namespace teigeneration="http://heml.mta.ca/Lace2/teigeneration" at "teiGeneration.xql";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace ctsurns="http://heml.mta.ca/Lace2/ctsurns" at "ctsUrns.xql";

declare function local:allTeiVolumes($my_collection as xs:string, $first_name as xs:string, $last_name as xs:string, $OGLHeader as xs:string) as node()* {
    let $volume_refs := ctsurns:uniqueCtsUrnReferences(collection($my_collection)//xh:span[@data-ctsurn])
    for $vol in $volume_refs
    return
        <entry type="xml" name="{teigeneration:get_filename_from_ref($vol)}">
            {
                teigeneration:wrap_tei(
                    teigeneration:strip_spans(
                        teigeneration:make_all_tei($my_collection, $vol)
                    ), 
                $my_collection, $vol, $first_name, $last_name, $OGLHeader)
            
            }
        </entry>
};

let $my_collection := xs:string(request:get-parameter('collectionUri', ''))
let $last_name := xs:string(request:get-parameter('last_name', ''))
let $first_name := xs:string(request:get-parameter('first_name', ''))
let $OGLHeader := xs:boolean(request:get-parameter('OGLHeader', false()))
let $collectionName := collection($my_collection)//dc:identifier

return
    response:stream-binary(
        xs:base64Binary(compression:zip(local:allTeiVolumes($my_collection, $first_name, $last_name, $OGLHeader), false()) ),
    'application/zip',
        $collectionName || ".zip")
