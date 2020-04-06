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
            (: this tries to chose the following one to which it is bound. The problem 
            with this is that it's maybe not in the bounds. You almost certainly want a picker to be 
            selected, so we'll use the bbox of the *line* instead
            
            $node/following::*[@id=$node/@data-starting-span]
            :)
            $node/..[@class="ocr_line"]
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
    try {
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
    }
    (: deal with cases where either are null, for instance if an element has no @title attribute.
    :)
    catch * {
        false()
    }

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


declare function teigeneration:make_divs_from_changed_ref_level($spans as node()*, $ref_level as xs:int, $doc_ref as xs:string, $ref_depth) as node()* {
    (: not sure the following is necessary :)
        if (count($spans) = 0) then
            <empty/>
        else
            let $miles := teigeneration:get_milestones_that_change_ref_level($spans, $ref_level, $doc_ref)
            let $count_of_ms := count($miles)
            for $ms at $count in $miles
                let $ref := teigeneration:get_ref_at_level($ms/@data-ctsurn,$ref_level)
                let $start_index := functx:index-of-node($spans, $ms)+1
                return
                    if ($ref_level = $ref_depth) then
                    <tei:div  type="textpart"  subtype="{$ref_level}" n="{$ref}" >
                    <tei:p>
                    {subsequence($spans,$start_index, teigeneration:get_length_to_next_mile_or_last($spans , $miles, $count, $start_index))}
                    </tei:p>
                    </tei:div>
                else
                    <tei:div type="textpart" subtype="{$ref_level}" n="{$ref}" >
                    {teigeneration:make_divs_from_changed_ref_level(subsequence($spans,functx:index-of-node($spans, $ms), teigeneration:get_length_to_next_mile_or_last($spans , $miles, $count, $start_index) ), $ref_level + 1, $doc_ref, $ref_depth)}
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
            let $reference_depth := ctsurns:ctsUrnPassageCitationDepth($raw[@class="cts_picker"][1]/@data-ctsurn/string())
            return
                teigeneration:make_divs_from_changed_ref_level($raw,1, $ref, $reference_depth)
};

declare function teigeneration:strip_zone_of_following_other_doc($raw as node()*, $this_doc_ref as xs:string) {
    (: According to the teiPreflight check, all doc refs within a given zone have to come in blocks.
    That is, they cant be interleaved, like AABBA. So we can get the pertinent matter for this zone by 
    pruning what is comes before the first doc ref that matches this and by optionally pruning all that comes 
    after that *doesn't* match this.
    
    This strips all content before the first doc ref that matches. :)
    let $strip_preceding := <wrap>{$raw}</wrap>/html:span[@data-ctsurn][ctsurns:ctsUrnReference(@data-ctsurn/string())=$this_doc_ref][1]/(self::*, following-sibling::*)
    (: this removes all material following the first non-this doc_ref. In the case that there is no 
    non-this following doc_ref, though, it returns nothing, so we need the conditional that follows it
    :)
    let $strip_following := <wrap>{$strip_preceding}</wrap>/html:span[@data-ctsurn][not(ctsurns:ctsUrnReference(@data-ctsurn/string())=$this_doc_ref)][1]/preceding-sibling::*
    return
        if ($strip_following) then
            $strip_following
        else
            $strip_preceding
};

declare function teigeneration:is_first_rectangle_of_type_in_doc($rect as node()) as xs:boolean {
    let $ordinal := $rect/@data-rectangle-ordinal
    let $type := $rect/@data-rectangle-type
    return 
       not(fn:exists($rect/../svg:rect[@data-rectangle-type=$type][@data-rectangle-ordinal < $ordinal]))
};

declare function teigeneration:raw_in_rect($my_collection as xs:string, $rect as node()) as node()* {
    for $element in teigeneration:html_node_corresponding_to_svg_node($rect, $my_collection)//html:span[@class="ocr_word" or @class="cts_picker" or @class="index_word" or @class="inserted_line"]
    where teigeneration:intersect_bbox_and_rect($rect, $element) return 
        $element
};

declare function teigeneration:make_tei_zone_raw($my_collection as xs:string, $zone as xs:string) as node()* {
            (: TODO add <pb/> milestones by 1) a function that checks if this $rect is the 
            smallest ordinal of all the similar rect types in this docoument; 2) if that is fulfilled AND
            the $element is the first in the 'for' loop, we prepend a <pb/>
            :)
            
            for $rect in collection($my_collection || "/SVG")//svg:rect[@data-rectangle-type=$zone]
            let $is_first_rect := teigeneration:is_first_rectangle_of_type_in_doc($rect)
            order by util:document-name($rect), $rect/@data-rectangle-ordinal 
                return 
                if ($is_first_rect) then
                (<tei:pb facs="{functx:substring-before-last(util:document-name($rect),'.')}"/>,teigeneration:raw_in_rect($my_collection, $rect))
                else
                    teigeneration:raw_in_rect($my_collection, $rect)
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


