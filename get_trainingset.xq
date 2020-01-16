xquery version "3.1";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace functx = "http://www.functx.com";
declare option exist:serialize "method=text media-type=text/csv omit-xml-declaration=yes";


declare function functx:substring-before-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-before($arg,$delim)
   else $arg
 };
 
 declare function functx:substring-after-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-after($arg,$delim)
   else $arg
 };
 
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

declare function local:make_trainingset($my_collection as xs:string) as xs:string* {
    if ($my_collection = '')
        then
           error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $my_collection || '"')
        else 
        for $hit in collection($my_collection)//html:span[@class="ocr_line"][not (html:span/@data-manually-confirmed = 'false')]
            let $tab := "&#x9;"
            let $newline := "&#10;"
            let $clean_line := local:clean_line_string($hit)
            where $clean_line != ""
                return (
                    concat(local:get_image_title_for_div($hit), $tab, local:get_bbox_for_div($hit),$tab,$clean_line,$newline)
            )  
};

let $my_collection := xs:string(request:get-parameter('collectionUri', ''))
let $format := xs:string(request:get-parameter('format','csv'))

let $set-content-type := response:set-header('Content-Type', 'text/csv')
let $set-file-name := response:set-header('Content-Disposition',  'attachment; filename="training.csv"')
(:  
let $my_collection := concat($dbroot, "632874144/2019-05-30-10-58_wells_2019-05-28-08-22-00025400.pyrnn.gz_selected_hocr_output")
:)
let $streaming_options := ''
return 
    response:stream(local:make_trainingset($my_collection),$streaming_options)


