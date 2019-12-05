xquery version "3.1";
declare namespace html="http://www.w3.org/1999/xhtml";
declare option exist:serialize "method=text media-type=text/csv omit-xml-declaration=yes";
declare function local:get_image_title_for_div($div as node())
as xs:string
{
    let $title := (# exist:timer #) {$div/ancestor::html:div[@class="ocr_page"]/@title}
    return if (contains($title,'tmp'))
        then 
            concat(substring-before(substring($title, 26),'/0001.bin.png'), '.png')
         else
             $title
};

declare function local:get_bbox_for_div($div as node())
as xs:string
{
    let $out := substring($div/@title, 6)
    return $out
};

declare function local:clean_line_string($div as node()) 
as xs:string
{
    let $out := normalize-unicode(normalize-space($div),"NFD")
    return $out
};

declare function local:make_trainingset($my_collection as xs:string) as xs:string*
{

if ($my_collection = '')
then
   error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $my_collection || '"')
else 
for $hit in (# exist:timer #) {collection($my_collection)//html:span[@class="ocr_line"][not (html:span/@data-manually-confirmed = 'false')]}
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

let $dbroot := "/db/Lace2Data/texts/"
let $set-content-type := response:set-header('Content-Type', 'text/csv')
let $set-file-name := response:set-header('Content-Disposition',  'attachment; filename="training.csv"')
(:  
let $my_collection := concat($dbroot, "632874144/2019-05-30-10-58_wells_2019-05-28-08-22-00025400.pyrnn.gz_selected_hocr_output")
:)
let $streaming_options := ''
return 
    response:stream((# exist:timer #) {local:make_trainingset($my_collection)},$streaming_options)


