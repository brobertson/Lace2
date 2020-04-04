xquery version "3.1";
module namespace teivalidation="http://heml.mta.ca/Lace2/teivalidation";
import module namespace teigeneration="http://heml.mta.ca/Lace2/teigeneration" at "teiGeneration.xql";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "app.xql";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace validation="http://exist-db.org/xquery/validation";
import module namespace ctsurns="http://heml.mta.ca/Lace2/ctsurns" at "ctsUrns.xql";

declare function teivalidation:validateAllTeiVolumes($my_collection as xs:string) as node()* {
    let $tei_simple_rng := doc("/db/apps/lace/resources/schemas/teisimple.rng")
    let $volume_refs := ctsurns:uniqueCtsUrnReferences(collection($my_collection)//xh:span[@data-ctsurn])
    for $vol in $volume_refs
    return 
        <validationreport file="{fn:replace($vol,':','_') || '.tei'}">
            {validation:jing-report((teigeneration:wrap_tei(teigeneration:strip_spans(teigeneration:make_all_tei($my_collection, $vol)))), $tei_simple_rng)}
         </validationreport>
};

declare function teivalidation:validationReport($node as node(), $model as map(*),  $collectionUri as xs:string) as node()* {
        (<xh:h3>TEI Validation for {app:formatRunTitle($node, $model, $collectionUri)}</xh:h3>,
    transform:transform(teivalidation:validateAllTeiVolumes($collectionUri),doc('/db/apps/lace/resources/xslt/validation_to_xhtml.xsl'),())
        )
};


