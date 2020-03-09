xquery version "3.1";
declare namespace html="http://www.w3.org/1999/xhtml";
import module namespace functx="http://www.functx.com";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare option exist:serialize "method=text media-type=text/csv omit-xml-declaration=yes";

declare function local:clear_extra_bbox_data($in as xs:string) as xs:string {
  let $out := replace(functx:substring-before-if-contains($in,";"),'"','')
  return
      $out
};

(:  some come in form
 : image /tmp/tmp.GqcDgZU6kDactaphilippietac00bonnuoft_0061/0001.bin.png
 : others image "actaphilippietac00bonnuoft_0061.png" 
 : So this code formats both into 
 : actaphilippietac00bonnuoft_0061.png
 : :)
declare function local:get_image_title_for_div($div as node()) as xs:string {
    let $title := local:clear_extra_bbox_data($div/ancestor::html:div[@class="ocr_page"]/@title)
    
    let $title := functx:substring-after-if-contains($title,"image ")

    return if (starts-with($title,'/tmp'))
        then 
            concat(substring-before(substring($title, 20),'/0001.bin.png'), '.png')
         else
             $title

};


declare function local:get_bbox_for_div($div as node()) as xs:string {
    let $out := substring(local:clear_extra_bbox_data($div/@title), 6)
    return $out
};

declare function local:clean_line_string($div as node())  as xs:string {
    let $out := normalize-unicode(normalize-space($div),"NFD")
    return $out
};

declare function local:make_trainingset($collectionUri as xs:string) as xs:string* {
    if ($collectionUri = '')
        then
           error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $collectionUri || '"')
        else 
        for $hit in collection($collectionUri)//html:span[@class="ocr_line"][not (html:span/@data-manually-confirmed = 'false')]
            let $tab := "&#x9;"
            let $newline := "&#10;"
            let $clean_line := local:clean_line_string($hit)
            where $clean_line != ""
                return (
                    concat(local:get_image_title_for_div($hit), $tab, local:get_bbox_for_div($hit),$tab,$clean_line,$newline)
            )  
};

let $collectionUri := xs:string(request:get-parameter('collectionUri', ''))
let $format := xs:string(request:get-parameter('format','csv'))
let $collectionName := collection($collectionUri)//dc:identifier
let $set-content-type := response:set-header('Content-Type', 'text/tab-separated-values')
let $filename := $collectionName || '_training.tsv'
let $set-file-name := response:set-header('Content-Disposition',  'attachment; filename="' || $filename || '"')
let $streaming_options := ''
return 
    response:stream(local:make_trainingset($collectionUri),$streaming_options)
