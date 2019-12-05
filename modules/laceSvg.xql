xquery version "3.1";
module namespace lacesvg="http://heml.mta.ca/Lace2/svg";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace functx="http://www.functx.com";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "app.xql";
declare function lacesvg:percentageToHSLString($percentage as xs:int) as xs:string {
    let $saturation := "50%"
    let $lightness := "80%"
    let $burgundy := "1, 94%, 32%"
   return  
       if ($percentage = 0) then
           $burgundy
        else
            "hsl(" ||  xs:string($percentage * 2) || ", " || $saturation || ", " || $lightness || ")"
};

declare function lacesvg:getResourceAccuracyRatio($resource as node()) as xs:string {
    let $spans : = $resource//*[@data-spellcheck-mode]
    let $number_of_spans := count($spans)
    let $number_of_accurate :=  count($resource//*[@data-spellcheck-mode = 'True'])
    let $percentage := 
        if ($number_of_spans = 0) then
            0
        else
            ( 100 * $number_of_accurate div  $number_of_spans)
    return
    lacesvg:percentageToHSLString($percentage)
};

declare function lacesvg:sortHocrByName($my_collection as xs:string) as node()* {
    let $sortedResources := for $resource in collection($my_collection)
                    where exists($resource/xh:html)
                    order by util:document-name($resource)
                    return $resource
    return $sortedResources
};

declare function lacesvg:getCollectionAccuracyRatios($my_collection as xs:string) as node()* {
  let $sortedResources := lacesvg:sortHocrByName($my_collection)   
  for $resource at $count in $sortedResources
    let $x := $count * 2
    let $page := $resource/xh:html/xh:body/xh:div[@class="ocr_page"]
    let $docCollectionUri := $page/@data-doc-collection-uri
    let $position := $page/@data-image-position

  return 
 
      <svg:a href="side_by_side_view.html?collectionUri={$docCollectionUri}&amp;positionInCollection={$position}">
      <svg:rect data-doc-name="{util:document-name($resource)}" x="{$x}" y="0" width="2" height="20" style="fill:{lacesvg:getResourceAccuracyRatio($resource)}">
  <svg:title>{$position}</svg:title>
  </svg:rect>
  </svg:a>
 
 (:) 
  return
      <p>{util:document-name($resource)}</p>
   :)  
};

declare function lacesvg:getResourceEditRatio($resource as node()) as xs:string {
    
    let $spans : = $resource//xh:span[@data-manually-confirmed]
    let $number_of_spans := count($spans)
    let $number_of_edited :=  count($resource//xh:span[@data-manually-confirmed = 'true'])

    let $percentage := 
        if ($number_of_spans = 0) then
            0
        else
            ( 100 * $number_of_edited div  $number_of_spans)
    return
    lacesvg:percentageToHSLString($percentage)
};

declare function lacesvg:getCollectionEditRatios($my_collection as xs:string) as node()* {
    let $sortedResources := lacesvg:sortHocrByName($my_collection) 
    for $resource at $count in $sortedResources
    let $x := $count * 2
    let $page := $resource//xh:div[@class="ocr_page"]
    let $docCollectionUri := $page/@data-doc-collection-uri
    let $position := $page/@data-image-position

  return 
      <svg:a href="side_by_side_view.html?collectionUri={$docCollectionUri}&amp;positionInCollection={$position}">
      <svg:rect data-doc-name="{util:document-name($resource)}" x="{$x}" y="0" width="2" height="20" style="fill:{lacesvg:getResourceEditRatio($resource)}">
  <svg:title>{$position}</svg:title>
  </svg:rect>
  </svg:a>
  (:
  return
      <p>{util:document-name($resource)}</p>
      :)
};