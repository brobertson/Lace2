xquery version "3.1";
import module namespace image = "http://exist-db.org/xquery/image";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace util = "http://exist-db.org/xquery/util";
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
    let $scale := 0.3
     let   $float := xs:float($pixel) * $scale
     return 
         xs:int($float)
};

let $imageBase := '/db/Lace2data/images/'
let $bbox:= request:get-parameter('bbox', '')
let $book := request:get-parameter('book','')
let $file := request:get-parameter('file','')
let $imageFile := concat(fn:substring-before($file,'.'),'.jpg')
let $imageDir := concat($imageBase,$book)
let $imageFilePath:= concat($imageDir,'/',$imageFile)
let $image := util:binary-doc($imageFilePath)
let $bbox_tokens := fn:tokenize($bbox,'\s+')
let $dimensions := (local:scaleDimension($bbox_tokens[2]),local:scaleDimension($bbox_tokens[3]),local:scaleDimension($bbox_tokens[4]),local:scaleDimension($bbox_tokens[5]))
let $croppedImage := image:crop($image,$dimensions,"image/jpeg")
(:  
let $user := "admin"
let $pass := "foo"
let $login := xmldb:login($imageDir, $user, $pass)

let $foo1 := response:set-header("Access-Control-Allow-Origin", "*")
:)
return
if(request:get-method() eq "GET") then
    (::)
response:stream-binary($croppedImage, "image/jpeg", "cropped_image.jpg")
(:  ::)
(:  
<p>{$dimensions}</p>
  ::)
else
            (
                response:set-status-code($response:NOT-FOUND),
                <image-not-found>{$imageFile}</image-not-found>
            )
            

