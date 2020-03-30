xquery version "3.1";

module namespace teipreflight="http://heml.mta.ca/Lace2/teipreflight";

declare namespace html="http://www.w3.org/1999/xhtml";
import module namespace functx="http://www.functx.com";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "app.xql";
import module namespace teigeneration="http://heml.mta.ca/Lace2/teigeneration" at "teiGeneration.xql";

declare function teipreflight:ctsUrnReference($urn as xs:string) {
    functx:substring-before-last($urn,':') || ":"
};

declare function teipreflight:uniqueCtsUrnReferences($ordered_pickers as node()*) {
        let $runRefsOnly :=
            for $picker in $ordered_pickers
            return
                teipreflight:ctsUrnReference($picker//@data-ctsurn/string())
        return fn:distinct-values($runRefsOnly)
};



declare function teipreflight:getPickerNodesForCtsUrnReference($ordered_pickers as node()*, $ref as xs:string) as node()* {
    for $picker in $ordered_pickers
    where teipreflight:ctsUrnReference($picker/@data-ctsurn/string()) = $ref
    return $picker
};



declare function teipreflight:ctsUrnReferencesSame($urn1 as xs:string, $urn2 as xs:string) as xs:boolean {
  (teipreflight:ctsUrnReference($urn1) = teipreflight:ctsUrnReference($urn2))  
};

declare function teipreflight:ctsUrnPassageCitation($urn as xs:string) {
    functx:substring-after-last($urn,':')
};

declare function teipreflight:ctsUrnPassageCitationParts($passageCitation) {
    fn:tokenize(teipreflight:ctsUrnPassageCitation($passageCitation),'\.')
};

declare function teipreflight:ctsUrnPassageCitationDepth($urn as xs:string) {
    count(teipreflight:ctsUrnPassageCitationParts(teipreflight:ctsUrnPassageCitation($urn)))
};

declare function teipreflight:ctsPickerPassageCitationDepth($picker as node()) {
    teipreflight:ctsUrnPassageCitationDepth(teipreflight:ctsUrnPassageCitation($picker/@data-ctsurn/string()))
};

(:  
declare function teipreflight:getOrderedUrnPickers($my_collection as xs:string) as node()* {
let $col := collection($my_collection)
for $doc in $col
let $seq := ()
let $name := util:document-name($doc)
    order by util:document-name($doc)
where (functx:substring-after-last($name,'.') = 'html')
    return ($seq, $doc//html:span[@class='cts_picker'])
};
:)


declare function teipreflight:testPassageCitationDepths($pickers as node()*) {
    let $first_depth :=  teipreflight:ctsPickerPassageCitationDepth($pickers[1])
    for $picker in $pickers
    let $this_depth := teipreflight:ctsPickerPassageCitationDepth($picker)
    
    return
    if 
    ( $this_depth != $first_depth) then
        (: there is no document that remains associated with this node, alas, so this doesn't work
        TODO: try to retain this so we can keep links
        let $image_position_results := app:getSideBySideViewDataForDocumentElement($picker)
        let $docCollectionUri := $image_position_results[1]
        let $position := $image_position_results[2]
        :)
        <html:div class="tei_error">❌The depth of the first reference for the work <html:code>{teipreflight:ctsUrnReference($picker/@data-ctsurn/string())}</html:code> is {$first_depth}, but for another it is {$this_depth} with a citation that reads <html:code>{teipreflight:ctsUrnPassageCitation($picker/@data-ctsurn/string())}</html:code>. To generate a TEI text, all references for a work have to have the same depth.</html:div>
    else
        ()
};

declare function teipreflight:duplicateUrnTest($ordered_pickers) {
    let $urns := $ordered_pickers//@data-ctsurn/string()
    let $dups := distinct-values(
        for $s in $urns
    where count($urns[. eq $s]) gt 1
        return $s
        )
    return
    if (fn:count($dups) > 0) then
        <html:div class="tei_error">❌Duplicated URNs: {$dups}</html:div>
    else
        ()
};

declare function teipreflight:interleavedUrnReferencesTest($ordered_pickers) {
    let $refs :=
            for $picker in $ordered_pickers
            return
                teipreflight:ctsUrnReference($picker//@data-ctsurn/string())
    for $ref at $pos in $refs
       where ($refs[$pos + 1] != $ref) and ($ref = subsequence($refs, ($pos + 2), count($refs))) 
    return
    <html:div class="tei_error">❌Your Urn References are not in blocks: {$ref} and {$refs[$pos +1]} are interleaved.</html:div>
};

declare function teipreflight:depthTestReport($ordered_pickers as node()*) {
    for $ref in teipreflight:uniqueCtsUrnReferences($ordered_pickers)
        return 
        teipreflight:testPassageCitationDepths(teipreflight:getPickerNodesForCtsUrnReference($ordered_pickers, $ref))
};



declare function teipreflight:zoneReport($zone as xs:string, $raw_elements) {
    let $enclosed := <here>{$raw_elements}</here>
    let $ordered_pickers := $enclosed//*[@class='cts_picker']
    let $allReports :=
    (
    teipreflight:depthTestReport($ordered_pickers),
    teipreflight:duplicateUrnTest($ordered_pickers),
    teipreflight:interleavedUrnReferencesTest($ordered_pickers)
    )
    return
        if ($allReports/@class="tei_error") then
            (<h4>Error in Zone {$zone}</h4>,
                    <html:div>{$allReports}</html:div>
            )
        else 
            ()
};          

declare function teipreflight:reportGoodUri($node as node(), $model as map(*),  $collectionUri as xs:string) {
    let $title := <html:h3>TEI Generation Precheck for: {app:formatRunTitle($node, $model, $collectionUri)}</html:h3>
    let $reports := 
        for $zone_label in $teigeneration:svg_zone_types
        let $zone_elements := teigeneration:make_tei_zone_raw($collectionUri, $zone_label)
        return 
            teipreflight:zoneReport($zone_label, $zone_elements)
    return
        if ($reports//@class="tei_error") then
            ($title,
            $reports)
        else
            ($title,
            <html:div><html:p>✅Your editing passes tests and is ready to be transformed to TEI by pressing this button:</html:p></html:div>,
        <html:div><html:button type="button" class="btn btn-success"><html:a id="download_tei" href='{concat("getTeiVolume.xq?collectionUri=",$collectionUri)}'>Download TEI File</html:a></html:button>
            </html:div>
            )
};   
declare function teipreflight:report($node as node(), $model as map(*),  $collectionUri as xs:string) {
if (xmldb:collection-available($collectionUri)) then
    teipreflight:reportGoodUri($node, $model, $collectionUri)
    else
        (<html:h4>TEI Generation Precheck</html:h4>,
        <html:div>Error: collection URI <html:code>{$collectionUri}</html:code> is not in database.</html:div>)
    
};
