xquery version "3.1";
import module namespace image = "http://exist-db.org/xquery/image";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "modules/app.xql";
import module namespace util = "http://exist-db.org/xquery/util";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace lace="http://heml.mta.ca/2019/lace";

(:~
: Retrieve a JPEG image from the database collection $local:image-collection
:
: @param $image-name The filename of the JPEG image
:
: @return The base64binary data comprising the JPEG image,
:   or the empty sequence if the image does not exist
:)

declare variable $response:BAD-REQUEST := 400;
declare variable $response:NOT-FOUND := 404;

declare function local:scaleDimension($pixel as xs:string) {
    let $scale := 1.0 (: not 0.3 :)
     let   $float := xs:float($pixel) * $scale
     return 
         xs:int($float)
};

(:  this does nothing to the final size of the popup, but it does
 : change the number of bytes in the payload. So it's a trade off between
 : server processing power and network snappiness :)
declare function local:scaleDimensionPostCrop($pixel as xs:string) {
    let $scale := 0.5
     let   $float := xs:float($pixel) * $scale
     return 
         xs:int($float)
};

declare function local:fudge($in as xs:float, $right as xs:boolean) {
    let $factor := 10.0 (: not 5.0 :)
     return 
         if (not($right)) then
             $in + ($factor * -1.0)
        else
            $in + $factor
};

declare function local:prepareXDimension($in as xs:float, $right as xs:boolean) {
    local:fudge(local:scaleDimension($in), $right)
};


let $bbox:= request:get-parameter('bbox', '')
let $collectionUri := request:get-parameter('collectionUri','')
let $imageCollection := app:imageCollectionFromCollectionUri($collectionUri)
let $file := request:get-parameter('file','')
let $imageFile := concat(fn:substring-before($file,'.'),'.png')
let $imageFilePath:= concat($imageCollection,'/',$imageFile)
let $image := util:binary-doc($imageFilePath)
let $bbox_tokens := fn:tokenize($bbox,'\s+')
let $cropping_dimensions := (local:prepareXDimension($bbox_tokens[2], false()),local:scaleDimension($bbox_tokens[3]),local:prepareXDimension($bbox_tokens[4], true()),local:scaleDimension($bbox_tokens[5]))
let $croppedImage := image:crop($image,$cropping_dimensions,"image/jpeg")
let $image_height :=image:get-height($croppedImage)
let $image_width := image:get-width($croppedImage) 
(: 
 : Dimensions for scaling are (height, width), not the other way around
 : See: https://exist-db.org/exist/apps/fundocs/view.html?uri=http://exist-db.org/xquery/image&location=java:org.exist.xquery.modules.image.ImageModule
 :   :)
 (::)
let $scaling_dimensions := (local:scaleDimensionPostCrop($image_height), local:scaleDimensionPostCrop($image_width))
let $scaled_image := image:scale($croppedImage, $scaling_dimensions, "image/jpeg")
(:  ::)
return
if(request:get-method() eq "GET") then
    response:stream-binary($scaled_image, "image/jpeg", "cropped_image.jpg")
else
            (
                response:set-status-code($response:NOT-FOUND),
                <image-not-found>{$imageFile}</image-not-found>
            )
            

