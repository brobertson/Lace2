xquery version "3.1";
module namespace lacesvg="http://heml.mta.ca/Lace2/svg";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace functx="http://www.functx.com";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "app.xql";

declare function lacesvg:percentageToHSLString($percentage as xs:int) as xs:string {
    let $saturation := "73%"
    let $lightness := "55%"
    let $burgundy := "hsl(1, 91%, 50%)"
    let $black := "hsl(0, 0%, 0%)"
   return  
       if ($percentage = 0) then
           $black
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

declare function lacesvg:sortCollectionByName($my_collection as xs:string) as node()* {
    let $sortedResources := for $resource in collection($my_collection)
                    order by util:document-name($resource)
                    return $resource
    return $sortedResources
};
 declare function lacesvg:getCollectionAccuracyRatios($my_collection as xs:string) as node()* {
 (: general dimension parameters :)
    let $x_scale_factor := 2
    let $strip_height := 20
    let $svg_height := 20
    let $carrot_y_offset := 21
    let $image_collection := app:imageCollectionFromCollectionUri($my_collection)
    let $svg_width := $x_scale_factor * count(collection($image_collection))
    let $sorted_images := lacesvg:sortCollectionByName($image_collection) 
    let $inner_svg_elements :=
        for $image_resource at $count in $sorted_images
            let $x := $count * $x_scale_factor
            let $image_name := util:document-name($image_resource)
            let $document_name := replace($image_name,"png","html")
            let $document_path := $my_collection || "/" || $document_name
            let $docCollectionUri := $my_collection
            let $position := $count
            let $fill := 
                if (fn:doc-available($document_path)) then
                    lacesvg:getResourceAccuracyRatio(doc($document_path))
                else
                    "hsl(0, 0%, 86%)" (: light grey :)
               
            return 
                <svg:a href="side_by_side_view.html?collectionUri={$docCollectionUri}&amp;positionInCollection={$position}">
                    <svg:rect data-doc-name="{$document_name}" x="{$x}" y="0" width="{$x_scale_factor}" height="{$strip_height}" style="fill:{$fill}">
                        <svg:title>{$position}</svg:title>
                    </svg:rect>
                </svg:a>
        
    return
        <svg:svg width="{$svg_width}" height="{$svg_height}" id="svg_accuracy_report">
            {$inner_svg_elements}
        </svg:svg>
};

declare function lacesvg:getCollectionAccuracyRatios2($my_collection as xs:string) as node()* {
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

declare function lacesvg:getCollectionEditRatios($my_collection as xs:string, $position as xs:string) as node()* {

    (: general dimension parameters :)
    let $x_scale_factor := 2
    let $strip_height := 20
    let $svg_height := 35let $carrot_y_offset := 21
    (: definitions related to position carrot :)
    let $carrot_position : = xs:int($position) *  $x_scale_factor 
    let $carrot_color := "red"
    let $carrot_height := 6
    let $carrot_spread := 5
 
    let $image_collection := app:imageCollectionFromCollectionUri($my_collection)
    let $svg_width := $x_scale_factor * count(collection($image_collection))
    let $sorted_images := lacesvg:sortCollectionByName($image_collection) 
    let $inner_svg_elements :=
        for $image_resource at $count in $sorted_images
            let $x := $count * $x_scale_factor
            let $image_name := util:document-name($image_resource)
            let $document_name := replace($image_name,"png","html")
            let $document_path := $my_collection || "/" || $document_name
            let $huh := fn:doc-available("/db/apps/actaphilippietac00bonnuoft_2019-10-31-12-09-00/actaphilippietac00bonnuoft_0000.html")
           (: let $page := $resource//xh:div[@class="ocr_page"] :)
            let $docCollectionUri := $my_collection
            let $position := $count
            let $fill := (:lacesvg:percentageToHSLString(30) lacesvg:getResourceEditRatio(doc($document_path)) :)
        
                if (fn:doc-available($document_path)) then
                    lacesvg:getResourceEditRatio(doc($document_path))
                else
                    "hsl(0, 0%, 86%)" (: light grey :)
               
            return 
                <svg:a href="side_by_side_view.html?collectionUri={$docCollectionUri}&amp;positionInCollection={$position}">
                    <svg:rect data-doc-name="{$document_name}" x="{$x}" y="0" width="{$x_scale_factor}" height="{$strip_height}" style="fill:{$fill}">
                        <svg:title>{$position}</svg:title>
                    </svg:rect>
                </svg:a>
        
    return
        <svg:svg width="{$svg_width}" height="{$svg_height}" id="svg_edit_report">
            {$inner_svg_elements}
            <!--svg:line x1="{$position}" y1="15" x2="{$position + 1}" y2="19" stroke="red" /-->
            <svg:polygon points="{$carrot_position},{$carrot_y_offset} {$carrot_position - $carrot_spread},{$carrot_height + $carrot_y_offset} {$carrot_position + $carrot_spread},{$carrot_height + $carrot_y_offset}" stroke="{$carrot_color}" fill="{$carrot_color}"/>
        </svg:svg>
};