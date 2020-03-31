xquery version "3.1";

module namespace teigeneration="http://heml.mta.ca/Lace2/teigeneration";
import module namespace ctsurns="http://heml.mta.ca/Lace2/ctsurns" at "ctsUrns.xql";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace svg="http://www.w3.org/2000/svg";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dc="http://purl.org/dc/elements/1.1/";

declare variable $teigeneration:svg_zone_types := ("primary_text", "translation", "app_crit",  "commentary");

declare function teigeneration:clear_extra_bbox_data($in as xs:string) as xs:string {
  let $out := replace(functx:substring-before-if-contains($in,";"),'"','')
  return
      $out
};

declare function teigeneration:get_bbox($node as node()) as xs:string {
    let $node_out :=
        if ($node[@class='cts_picker']) then 
            $node/following::*[@id=$node/@data-starting-span]
        else
            $node
    let $out := substring(teigeneration:clear_extra_bbox_data($node_out/@title), 6)
    return $out
};

declare function teigeneration:clean_line_string($div as node())  as xs:string {
    let $out := normalize-unicode(normalize-space($div),"NFD")
    return $out
};

declare function teigeneration:html_node_corresponding_to_svg_node($node as node(), $my_collection as xs:string) as node()* {
    doc($my_collection || "/" || substring-before(util:document-name($node), ".svg") || ".html")
};


declare function teigeneration:intersect_bbox_and_rect($rect as node(), $bbox as node()) as xs:boolean {
    let $bbox_string := teigeneration:get_bbox($bbox)
    let $scale := xs:float($rect/preceding::svg:image/@data-scale)
    let $bbox_tokens := fn:tokenize($bbox_string,'\s+')
    let $bULx := xs:float($bbox_tokens[1])
    let $bULy := xs:float($bbox_tokens[2])
    let $bLRx := xs:float($bbox_tokens[3])
    let $bLRy := xs:float($bbox_tokens[4])
    let $rULx := xs:float($rect/@x) div $scale
    let $rULy := xs:float($rect/@y)  div $scale
    let $rLRx := $rULx + (xs:float($rect/@width) div $scale)
    let $rLRy := $rULy + (xs:float($rect/@height) div $scale)
    return
    if (($bULx gt $rLRx) or ($rULx gt $bLRx) or ($bULy gt $rLRy) or ($rULy gt $bLRy)) then
        false()
    else 
        true()
};

declare function teigeneration:get_ref_at_level($urn as xs:string, $ref_level as xs:int) as xs:string {
        let $first_part := functx:substring-before-last($urn,":")
        let $last_part : = fn:string-join(fn:subsequence(fn:tokenize(functx:substring-after-last($urn,":"),"\."),1, $ref_level),".")
        return $first_part || ":" || $last_part

};

declare function teigeneration:get_milestones_that_change_ref_level($spans as node()+, $ref_level as xs:int, $doc_ref as xs:string) as node()* {
    try {
    for $ms at $count in $spans[@class="cts_picker"]
    where (ctsurns:ctsUrnReference($ms/@data-ctsurn/string()) = $doc_ref) and (($count = 1) or (teigeneration:get_ref_at_level($ms/@data-ctsurn,$ref_level) !=  teigeneration:get_ref_at_level($spans[@class='cts_picker'][$count -1]/@data-ctsurn, $ref_level)))
    order by $ms/@data-ctsurn
        return $ms
    }
    catch * {
        ()
    }
};

declare function teigeneration:get_length_to_next_mile_or_last($spans as node()+, $miles as node()+, $count as xs:int, $start_index as xs:int) as xs:int {
        if ($count = count($miles)) then
          count($spans)
        else
           functx:index-of-node($spans, $miles[$count+1])-$start_index
            
};


declare function teigeneration:make_divs_from_changed_ref_level($spans as node()*, $ref_level as xs:int, $doc_ref as xs:string) as node()* {
    (: not sure the following is necessary :)
        if (count($spans) = 0) then
            <empty/>
        else
            let $lowest_level := 1
            let $miles := teigeneration:get_milestones_that_change_ref_level($spans, $ref_level, $doc_ref)
            let $count_of_ms := count($miles)
            for $ms at $count in $miles
                let $ref := teigeneration:get_ref_at_level($ms/@data-ctsurn,$ref_level)
                let $start_index := functx:index-of-node($spans, $ms)+1
                return
                    if ($ref_level = $lowest_level) then
                    <tei:div  type="textpart"  subtype="{$ref_level}" n="{$ref}" >
                    <tei:p>
                    {subsequence($spans,$start_index, teigeneration:get_length_to_next_mile_or_last($spans , $miles, $count, $start_index))}
                    </tei:p>
                    </tei:div>
                else
                    <tei:div type="textpart" subtype="{$ref_level}" n="{$ref}" >
                    {teigeneration:make_divs_from_changed_ref_level(subsequence($spans,functx:index-of-node($spans, $ms), teigeneration:get_length_to_next_mile_or_last($spans , $miles, $count, $start_index) ), $ref_level + 1, $doc_ref)}
                    </tei:div>
};

declare function teigeneration:milestones_to_divs_widows($spans as node()+) as node()* {
      let $miles := $spans[@class="cts_picker"]
      let $first_milestone := $miles[1]
      let $count_of_ms := count($miles)
      let $last_milestone := $miles[$count_of_ms]
      let $count_of_all_spans :=count($spans)
      return 
            if ($spans[1] !=  $first_milestone) then
                <tei:div type="widow"><tei:p n="">{subsequence($spans,1,functx:index-of-node($spans, $first_milestone)-1)}</tei:p></tei:div>
            else
                ()
};

declare function teigeneration:milestones_to_divs($spans as node()+) as node()* {
    let $count_of_ms := count($spans[@class="cts_picker"])
    return
    for $ms at $count in $spans[@class="cts_picker"]
        let $start_index := functx:index-of-node($spans, $ms)+1
        return
            if ($count ne $count_of_ms) then
            (: subsequence's last argument is 'length', not 'end position', so 
             : we have to subtract the start_index from the end position.
             :)
            <tei:div type="textpart" subtype="urn" n="{$ms/@data-ctsurn}"><tei:p>{subsequence($spans,$start_index, functx:index-of-node($spans, $spans[@class='cts_picker'][$count + 1])-$start_index)}</tei:p></tei:div>
            else
                (: this is the last milestone, dealing with 'orphans':)
                if (functx:index-of-node($spans, $ms) ne count($spans)) then
                    (: if no 'length' is passed to subsequence, it gives all to the end
                     : of the sequence
                     :)
                    <tei:div type="textpart" n="{$ms/@data-ctsurn}"><tei:p>{subsequence($spans,$start_index)}</tei:p></tei:div>
                else
                    ()

};

declare function teigeneration:make_all_tei($my_collection as xs:string, $ref as xs:string) as node()* {
        if ($my_collection = '' or $ref = '')
        then
           error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $my_collection || '"')
        else 
            <tei:body>
                {
        for $type in $teigeneration:svg_zone_types
            order by index-of($teigeneration:svg_zone_types, $type)
            return <tei:div type="{$type}">{teigeneration:make_tei_zone($my_collection, $type, $ref)}</tei:div>
                }
            </tei:body>
};

declare function teigeneration:make_tei_zone($my_collection as xs:string, $zone as xs:string, $ref as xs:string) as node()* {
    let $raw := teigeneration:strip_zone_of_following_other_doc(teigeneration:make_tei_zone_raw($my_collection, $zone), $ref)
    return
    if (count($raw[@class="cts_picker"]) eq 0) then
        ()
    else 
      teigeneration:make_divs_from_changed_ref_level($raw,1, $ref)
};

declare function teigeneration:strip_zone_of_following_other_doc($raw as node()*, $this_doc_ref as xs:string) {
  <wrap>{$raw}</wrap>/html:span[@data-ctsurn][not(ctsurns:ctsUrnReference(@data-ctsurn/string())=$this_doc_ref)]/preceding-sibling::*
};

declare function teigeneration:make_tei_zone_raw($my_collection as xs:string, $zone as xs:string) as node()* {
            for $rect in collection($my_collection)//svg:rect[@data-rectangle-type=$zone]
            order by util:document-name($rect), $rect/@data-rectangle-ordinal 
                return 
                        for $element in teigeneration:html_node_corresponding_to_svg_node($rect, $my_collection)//html:span[@class="ocr_word" or @class="cts_picker"]
                       where teigeneration:intersect_bbox_and_rect($rect, $element)
                        return 
                           $element
};



declare function teigeneration:make_tei($my_collection as xs:string) as node()* {
    if ($my_collection = '')
        then
           error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $my_collection || '"')
        else 
        for $type in $teigeneration:svg_zone_types
            order by index-of($teigeneration:svg_zone_types, $type)
        for $rect in collection($my_collection)//svg:rect[@data-rectangle-type=$type]
            order by util:document-name($rect), $rect/@data-rectangle-ordinal 
                return (
                        for $element in teigeneration:html_node_corresponding_to_svg_node($rect, $my_collection)//html:span[@class="ocr_word" or @class="cts_picker"]
                       where teigeneration:intersect_bbox_and_rect($rect, $element)
                        return 
                           $element
                    
            )  
};


declare function teigeneration:strip_spans($input as node()?) {
    let $xslt := <xsl:stylesheet version="1.0" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" version="1.0" encoding="UTF-8"/>
<!--Identity template,
        provides default behavior that copies all content into the output -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
<xsl:template match="html:span">
    <xsl:apply-templates/>
</xsl:template>
<xsl:template match="*[@data-dehyphenatedform]">
    <xsl:if test="@data-dehyphenatedform!=''">
        <xsl:value-of select="concat(normalize-space(@data-dehyphenatedform), ' ')"/>
    </xsl:if>
</xsl:template>
<xsl:template match="node/@TEXT | text()">
  <xsl:if test="normalize-space(.)">
    <xsl:value-of select="concat(normalize-space(.), ' ')"/>
  </xsl:if>
</xsl:template>
</xsl:stylesheet>
return transform:transform($input, $xslt, ())
};

declare function teigeneration:wrap_tei($body as node()) as node() {
        <TEI xml:space="preserve" xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>title of document</title>
            </titleStmt>
            <publicationStmt>
                <authority/>
                <idno type="filename"/>
            </publicationStmt>
            <sourceDesc>
                <msDesc>
                    <msIdentifier>
                        <repository>museum/archive</repository>
                        <idno>inventory number</idno>
                    </msIdentifier>
                </msDesc>
            </sourceDesc>
        </fileDesc>
    </teiHeader>
    <text>
        {$body}
        </text>
        </TEI>
};



