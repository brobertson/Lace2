xquery version "3.1";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace dc="http://purl.org/dc/elements/1.1/";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "modules/app.xql";
declare function local:get_image_title_for_div($div as node()) as xs:string {
    let $title := (# exist:timer #) {$div/ancestor::html:div[@class="ocr_page"]/@title}
    return if (contains($title,'tmp'))
        then 
            concat(substring-before(substring($title, 26),'/0001.bin.png'), '.png')
         else
             $title
};

declare function local:get_bbox_for_div($div as node()) as xs:string {
    let $out := substring($div/@title, 6)
    return $out
};

declare function local:clean_line_string($div as node())  as xs:string {
    let $out := normalize-unicode(normalize-space($div),"NFD")
    return $out
};

declare function local:make_trainingset($my_collection as xs:string) as node()* {
    
    if ($my_collection = '')
        then
           error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $my_collection || '"')
        else 
        for $hit at $pos in (# exist:timer #) {collection($my_collection)//html:span[@class="ocr_line"][not (html:span/@data-manually-confirmed = 'false')]}
            let $formatted_pos := format-number($pos, '0000') 
            let $clean_line := local:clean_line_string($hit)
            (: now image stuff for this line :)
            let $image_collection := app:imageCollectionFromCollectionUri($my_collection)
            let $my_document_name := util:document-name($hit)
            let $my_bare_document_name := replace($my_document_name,".html","")
            let $this_line_id := $my_bare_document_name || "_" || $formatted_pos
            let $my_image_name := $my_bare_document_name || ".png"
            let $image := util:binary-doc($image_collection || "/" || $my_image_name)
            let $bbox := string($hit/@title)
            let $bbox_stripped := fn:tokenize($bbox, ';')[1]
            let $bbox_tokens := fn:tokenize($bbox_stripped,'\s+')
            
            let $cropping_dimensions := (xs:integer($bbox_tokens[2]), xs:integer($bbox_tokens[3]), xs:integer($bbox_tokens[4]), xs:integer($bbox_tokens[5]))
            let $croppedImage := image:crop($image,$cropping_dimensions,"image/jpeg")
            where $clean_line != ""
                return (
                    <entry name="{$this_line_id}.gt.txt" type='text' method='deflate'>
                        {$clean_line}
                    </entry>,
                    <entry name="{$this_line_id}.bin.png" type="binary" method='deflate'>
                    {$croppedImage}
                    </entry>
                    
            )  
};

let $collectionUri := xs:string(request:get-parameter('collectionUri', ''))
(:  
let $my_collection := concat($dbroot, "632874144/2019-05-30-10-58_wells_2019-05-28-08-22-00025400.pyrnn.gz_selected_hocr_output")
:)
let $collectionName := collection($collectionUri)//dc:identifier
let $col :=  local:make_trainingset($collectionUri)
return
    response:stream-binary(
        xs:base64Binary(compression:zip($col, true()) ),
        'application/zip',$collectionName || "_training_images.zip")
