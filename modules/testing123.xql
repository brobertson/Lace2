xquery version "3.0";
declare namespace xh="http://www.w3.org/1999/xhtml";
let $filePath := "/db/laceData/894469813v1/2017-06-30-09-00_bude-2017-06-15-13-39-00040500.pyrnn.gz_selected_hocr_output/894469813v1_0031.html"
(: 
let $user := "admin"
let $pass := "foo"

(:  logs into the collection :)
let $login := xmldb:login($filePath, $user, $pass)
:)
return doc($filePath)/xh:html/xh:body/xh:div[@class="ocr_page"]