xquery version "1.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace lacesvg="http://heml.mta.ca/Lace2/svg" at "/db/apps/lace/modules/laceSvg.xql";
import module namespace app="http://heml.mta.ca/Lace2/templates";
(: The following external variables are set by the repo:deploy function :)
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xh="http://www.w3.org/1999/xhtml";
declare namespace lace="http://heml.mta.ca/2019/lace";
(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

let $total_words := count(collection($target)//xh:span[@class="ocr_word"])
let $total_accurate_words := count(collection($target)//xh:span[@class="ocr_word" and @data-spellcheck-mode = "True"])
let $report := <lace:totals><lace:total_words>{$total_words}</lace:total_words><lace:total_accurate_words>{$total_accurate_words}</lace:total_accurate_words></lace:totals>
let $store := xmldb:store($target, "totals.xml", $report)
let $bogus :=
    for $page in collection($target)//xh:div[@class='ocr_page']
  (:
        let $span_count := count($page//xh:span[@class="ocr_word"])
        let $confirmed_count := count($page//xh:span[@data-manually-confirmed="true"])
        let $empty_count := count($page//xh:span[@class="ocr_word"]/text() = "")
:)
        let $image_position_results := app:getSideBySideViewDataForDocumentElement($page)
        let $docCollectionUri := $image_position_results[1]
        let $positionInImageCollection := $image_position_results[2]
        let $unused1 :=
(:            if (exists($page/@data-word-count)) then
                update value $page/@data-word-count with $span_count
            else
                update insert attribute data-word-count {$span_count} into $page
        let $unused2 :=
            if (exists($page/@data-confirmed-word-count)) then
                update value $page/@data-confirmed-word-count with $confirmed_count
            else
                update insert attribute data-confirmed-word-count {$confirmed_count} into $page

       let $unused3 :=
            if (exists($page/@data-empty-word-count)) then
                update value $page/@data-empty-word-count with $empty_count
            else
                update insert attribute data-empty-word-count {$empty_count} into $page
:)
        let $unused4 :=
            if (exists($page/@data-doc-collection-uri)) then
                update value $page/@data-doc-collection-uri with $docCollectionUri
            else
                update insert attribute data-doc-collection-uri {$docCollectionUri} into $page
        let $unused5 :=
            if (exists($page/@data-image-position)) then
                update value $page/@data-image-position with $positionInImageCollection
            else
                update insert attribute data-image-position {$positionInImageCollection} into $page
        return $unused5
    
 :)     
let $width := 2 * count(collection($target))
let $report := <svg:svg id="svg_accuracy_report" width="{$width}" height="20">
  {lacesvg:getCollectionAccuracyRatios($target)}
</svg:svg>
let $store := xmldb:store($target, "accuracyReport.svg", $report)
return 
    $store
