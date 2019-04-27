xquery version "3.0";

module namespace app="http://heml.mta.ca/Lace2/templates";

import module namespace file="http://exist-db.org/xquery/file";
import module namespace image="http://exist-db.org/xquery/image";
import module namespace markdown="http://exist-db.org/xquery/markdown";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace compression="http://exist-db.org/xquery/compression";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace xh="http://www.w3.org/1999/xhtml";

declare variable $app:dataPath :="/db/Lace2Data/";
declare variable $app:textDataPath := $app:dataPath || "texts/";
declare variable $app:imageDataPath := $app:dataPath || "images/";
declare variable $app:catalogFile := doc($app:dataPath || "metadata/laceTexts.xml");

(: 
 : General Helper Functions
 : 
 : Use a markdown renderer to convert the markdown in a given node into html. 
 : It can be evoked like this:
 : <div class="app:renderMarkdown">
 : ###Bruce Robertson
 : Bruce Robertson is Head of the Department of Classics at [Mount Allison University](http://www.mta.ca) in Canada. He received his PhD in Classics   : at the University of Toronto, and has worked on several digital initiatives.
 : </div>
 :)
declare
 function app:renderMarkdown($node as node(), $model as map(*), $name as xs:string?) {
    if ($name) then
        markdown:parse("This is a *fine* howdydo.")
    else
        (markdown:parse(fn:string($node)))
};

declare function app:count-collection($node as node(), $model as map(*), $dir as xs:string?) {
   let $count := count(xmldb:get-child-resources($dir))
   return $count
};

(: End of General Helper Functions
 : 
 : Functions used to present the catalogs of works.
 : This is the highest level view of the data.
 :  
 : Count the number of 'archive texts', that is, volumes, in the 
 : catalog file
 :)
declare function app:countCatalog($node as node(), $model as map(*)) {
        count($app:catalogFile/texts/archivetext) || " "
};

(: 
 : For a given archive_text node, format the contents 
 :)
declare function app:formatCatalogEntry($text as node()) {
    <span class="catalogueEntry">{$text/creator/text()} ({$text/date/text()}). <i>{fn:substring($text/title/text(),1,80)}</i>. {$text/volume/text()}</span>
};

(: 
 : for a given archive_text node, format the contents and link to 
 : its 'runs'
 :)
declare function app:formatCatalogEntryWithRunsLink($text as node()) {
    <a href="{concat("runs.html?archive_number=",$text/archive_number)}">
        {app:formatCatalogEntry($text)}
    </a>
};

(: 
 : This uses the "archive number" string as a key to the catalog entry, then formats
 : the resulting catalog information
 : TODO: the xpath here is a bit wonky. Clean up to not require a loop, since there
 : should be only one $text for each $archive_number
 : Once it's cleaned up, this function can be removed and the xpath put in the call.
 : 
 : TODO: make an index to optimize the xpath below
 :)
declare function app:formatCatalogEntryForArchiveNumber($archive_number as xs:string) {
for $text in $app:catalogFile/texts/archivetext[archive_number=$archive_number][1]
return
app:formatCatalogEntryWithRunsLink($text)
};

(: 
 : loop through all the 'archivetext' nodes in the catalogue xml file and 
 : lay them out in a table, linked to their runs. If there are not runs, then
 : don't link them, and assign css class 'notAvailable' 
 :)
declare function app:catalog($node as node(), $model as map(*)) {
    for $text in $app:catalogFile/texts/archivetext
        order by $text/creator
        return 
            if  (xmldb:collection-available($app:textDataPath || $text/archive_number)) 
            then
                <tr>
                    <td>
                        {app:formatCatalogEntryWithRunsLink($text)}
                    </td>
                </tr>
            else 
                <tr class="notAvailable">
                <td>{app:formatCatalogEntry($text)}</td></tr>
 };
 
(: 
 : Provide a catalog of the $count most recently processed volumes, or archivetexts, 
 : ordered from most recently processed to least. 
 :)
declare function app:latest($node as node(), $model as map(*), $count as xs:string?) {
    let $sorted-runs :=
        for $run in $app:catalogFile/texts/archivetext/run
            order by $run/date descending
                  return $run
    for $run at $counting in subsequence($sorted-runs, 1, $count)
        return
            <tr>
                <td>
                {$run/date}{app:formatCatalogEntryWithRunsLink($run/..)}
                </td>
            </tr>
 };

(: 
 : End of functions relating to catalog entries.
 : 
 : The following functions format and present 'runs', 
 : that is, OCR jobs on a given text
 :  :)
 
declare function app:runsAvailable($text as xs:string) {
  xmldb:collection-available($app:textDataPath || $text)
};

(: For a given $archive_number, chronologically list all the runs, in descending order :)
declare function app:runs($node as node(), $model as map(*),  $archive_number as xs:string?) {
    for $run in $app:catalogFile/texts/archivetext[archive_number=$archive_number][1]/run
    order by $run/date descending
return
    <tr>
<td>{$run/date}</td><td>{$run/classifier}</td>{app:hocrTypes($run)}
</tr>
};

(: convert the $hocrTypeName, which is internally formatted as a number, to a user-friendly string :)
declare 
 %test:arg("hocrTypeName", "0") %test:assertEquals("raw")
 %test:arg("hocrTypeName", "3") %test:assertEquals("selected")
 %test:arg("hocrTypeName", "97") %test:assertEquals("HOCR Type '97'")
function app:hocrTypeStringForNumber($hocrTypeName as xs:string) {
    let   $name :=  switch ($hocrTypeName) 
    case "0" return "raw"
    case "1" return "combined"
    case "2" return "selected"
    case "3" return "selected"
    default return "HOCR Type '" || $hocrTypeName || "'"
    return $name
};

(:  Generate URL parameters that correspond to page number 25 of a specific hocrtype within a run
 :  TODO: This function does not exactly work as advertised, because it doesn't encode the $hocrTypeName! 
 :  Thus, it is impossible to roundtrip to the various run types within a run, and the viewer now always defaults
 :  to the 'selected' view.
 :  
 :  TODO: When the above is fixed, this is the key to a REST interface to these data, using eXist-db url rewriting. 
 :  /db/Lace2Data/historiaerecogno02thucuoft/2016-01-16-13-14_porson-2013-10-23-16-14-00100000.pyrnn.gz_selected_hocr_output/historiaerecogno02thucuoft_0023.html
 : 
 :  TODO: Don't blindly chose page 25, because we don't really know if there *are* 25 pages. Rather, 
 :  make a function that counts the number of pages and gets one a certain percentage through.
 :   :)
declare function app:hocrCollectionLinkForhocrTypeElement($hocrtype as node()) {
  concat("?documentId=",$hocrtype/../../archive_number,"&amp;runId=",$hocrtype/../date,"&amp;classifier=",$hocrtype/../classifier,"&amp;fileNum=25")
};

declare function app:hocrCollectionUriForHocrTypeElement($hocrtype as node()) {
  concat($app:textDataPath,$hocrtype/../../archive_number,"/",$hocrtype/../date,"_",$hocrtype/../classifier,"_selected_hocr_output/")
};

(: Every run can, and often does, have multiple HOCR types, representing various stages of the process.
 : These might be 'raw', 'combined', 'selected' and so forth.
 : This function formats these types with hocrTypeStringForNumber and, if files are indeed available for
 : that run, it makes a link to the side-by-side view of that hocr type's pages. :)
declare function app:hocrTypes($run as node()) {
    for $hocrtype in $run/hocrtype
    return 
        if (xmldb:collection-available(concat($app:textDataPath,$run/../archive_number)) and ($hocrtype = "3"))
        then
            <td>{app:hocrTypeStringForNumber($hocrtype)}:
            <span>
                <a href="{concat("side_by_side_view.html?documentId=",$hocrtype/../../archive_number,"&amp;runId=",$hocrtype/../date,"_",$hocrtype/../classifier,"_selected_hocr_output","&amp;positionInCollection=2")}">Edit</a><span> | </span> <a href="{concat("getZippedCollection.xq?collectionUri=",app:hocrCollectionUriForHocrTypeElement($hocrtype))}">Download XML zip </a>| <a href="{concat("getZippedCollection.xq?collectionUri=",app:hocrCollectionUriForHocrTypeElement($hocrtype), "&amp;format=text")}">Download Plain text zip </a>
                </span>
            </td>
        else
            <span/>
            (:
            <td>{app:hocrTypeStringForNumber($hocrtype)}</td>
    :)                    
};



(: 
 : End functions relating to runs
 : 
 : The following functions preprocess and lay out ocr result pages.
 : 
 : Apply xslt to add an attribute to every <xh:span class="ocr_word"> element, assigning the $attributeValue
 : Used below to add "content-editable='true'" to the final xhtml output.
 :)
declare function app:add-attribute-to-ocrword($input as node()?, $attributeName as xs:string, $attributeValue as xs:string?) {
    let $xslt := <xsl:stylesheet  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xh="http://www.w3.org/1999/xhtml" version="1.0">
    <xsl:template match="xh:span[@class='ocr_word']">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="{$attributeName}">{$attributeValue}</xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
return transform:transform($input, $xslt, ())
};

(: 
 : TODO: Index by class to optimize this xpath search
 : 
 :)
declare function app:fixHocrPageNode($hocrPageNode as node(), $innerAddress as xs:string) {
    <xh:div class="ocr_page" title="{$innerAddress}">
        {$hocrPageNode/xh:html/xh:body/xh:div[@class="ocr_page"]/*}
    </xh:div>
};

(: 
 : generate a <img> tag for a given $imageFile in the database 
 :)
declare 
%test:arg('imageFile', "/db/Lace2Data/images/myname 4athing/myname 4athing_0020.jpg") %test:assertEquals('<img width="500" class="img-responsive" onclick="return page_back()" id="page_image" src="/db/Lace2Data/images/myname 4athing/myname 4athing_0020.jpg" alt="photo"/>')
function app:getImageLink($imageFile as xs:string?) {
    (: if (util:binary-doc-available) works with these binary files, but we need to get at it before the /rest path is put on. :)
    <img width="500"  class="img-responsive" onclick="return page_back()" id="page_image" src="{$imageFile}" alt="photo"/>

};

(:  
 : generate an <ul> for pagination based on the params for a text  collection and the fileNum 
 : 
 : TODO: This needs to be replaced with one that goes to an arbitrary collection in the database and counts 
 : the files within it.
 :  :)
 declare function app:navButton($collectionUri, $positionInCollection as xs:integer, $skipBy as xs:integer, $label as xs:string) {
    let $targetIndex := $positionInCollection + $skipBy
    let $documentId :=  app:documentIdFromCollectionUri($collectionUri)
    let $runId := app:runIdFromCollectionUri($collectionUri)
    return
    if ($skipBy = 0)
    then
        <li class="page-item active">
      <a class="page-link" href="#">{$positionInCollection}</a>
    </li>
    else if (($targetIndex >= count(collection($collectionUri))) or ($targetIndex <= 0))
    then
        <li class="page-item">
      <span class="notAvailable">{$label}</span>
    </li>
    else
        <li class="page-item">
      <a class="page-link" href="{concat("?documentId=", $documentId, "&amp;runId=", $runId, "&amp;positionInCollection=", $targetIndex)}">{$label}</a>
    </li>
};

 declare function app:paginationWidget($collectionUri, $positionInCollection as xs:integer) {
<nav aria-label="...">
  <ul class="pagination">
   {app:navButton($collectionUri,$positionInCollection,-20,"-20")}
    {app:navButton($collectionUri,$positionInCollection,-5,"-5")}
    {app:navButton($collectionUri,$positionInCollection,-1,"Previous")}
    {app:navButton($collectionUri,$positionInCollection,0,"")}
    {app:navButton($collectionUri,$positionInCollection,1,"Next")}
        {app:navButton($collectionUri,$positionInCollection,5,"+5")}
        {app:navButton($collectionUri,$positionInCollection,20,"+20")}
  </ul>
  </nav>
};

(:
 : not currently used  
declare 
 %test:args("12882192", 5) %test:assertEquals("/exist/rest/db/Lace2Data/images/12882192/12882192_0005.jpg")
function app:getImageFilePath($documentId as xs:string, $fileNum as xs:integer) {
     let $fileNumFormat := format-number($fileNum, '0000')
     let $imageCollectionPath :=  $app:imageDataPath || $documentId 
     return 
         if (util:binary-doc-available($imageCollectionPath || "/" || $documentId || "_" || $fileNumFormat || ".jpg")) then
            concat('/exist/rest',$app:imageDataPath,$documentId,"/",$documentId,"_",$fileNumFormat,".jpg")
         else
             "wow"
};

:)


declare 
(: 
 %test:args(collectionUri, "/db/Lace2Data/texts/ajax00soph") %test:assertEquals("/exist/rest/db/Lace2Data/images/12882192/12882192_0005.jpg")
 :)
 function app:documentIdFromCollectionUri($collectionUri as xs:string) {
  let $stripped := substring($collectionUri, string-length($app:textDataPath))
  let $documentId := tokenize($stripped, "/")
  (: The first element of the sequence is the string before '/', namely '' :)
  return $documentId[2]
};

declare 
(: 
 %test:args(collectionUri, "/db/Lace2Data/texts/ajax00soph") %test:assertEquals("/exist/rest/db/Lace2Data/images/12882192/12882192_0005.jpg")
 :)
 function app:runIdFromCollectionUri($collectionUri as xs:string) {
  let $stripped := substring($collectionUri, string-length($app:textDataPath))
  let $documentId := tokenize($stripped, "/")
  (: The first element of the sequence is the string before '/', namely '' :)
  return $documentId[3]
};

(: 
 : Because the sequence of filenames that comes from the 'collection' function
 : is unordered, we use this function to make sure it is ordered by the names
 : of the files, which should be standardized to something like volumeidentifier_0123.html
 :)

declare 
(: 
 %test:args(collectionUri, "/db/Lace2Data/texts/ajax00soph") %test:assertEquals("/exist/rest/db/Lace2Data/images/12882192/12882192_0005.jpg")
 TODO: we need to pass to the function a collection in order to unit test this properly. 
 : :)
function app:sortCollection($collectionUri as xs:string) {
    for $item in collection($collectionUri)
    order by util:document-name($item)
    return $item
};

(: 
 : generate html for a page which contains, on its left side, an image of the page, and on the right, the 
 : editable content of this run/hocrtype
 : Additionally, the page has a pagination widget on the top.
 : 
 : TODO: We should factor out the pagination stuff, so it can be used for other views. This refactored 
 : pagination widget should be a heck of a lot smarter, knowing the number of pages in the collection it is viewing 
 : and the position of the current page in that collection.
 : 
 :  :)



declare function app:getCollectionUri($documentId as xs:string, $runId as xs:string) {
  (: /db/Lace2Data/texts/evangeliaapocry00tiscgoog/2018-07-12-09-33_tischendorf-2018-06-18-12-36-00008100.pyrnn.gz_selected_hocr_output :)
  concat($app:textDataPath,$documentId,'/',$runId)  
};

declare function app:sidebyside($node as node(), $model as map(*), $documentId as xs:string, $runId as xs:string, $positionInCollection as xs:integer?) {
let $collectionUri := app:getCollectionUri($documentId,$runId)
 let $me := util:document-name(app:sortCollection($collectionUri)[$positionInCollection])
 let $meAsJpeg := replace($me,"html","jpg")
let $rawHocrNode := app:sortCollection($collectionUri)[$positionInCollection]
let $innerAddressWithHead := $collectionUri || '/' || util:document-name($rawHocrNode)
let $innerAddress := replace($innerAddressWithHead,$app:textDataPath, "")
 let $hocrPageNode := app:fixHocrPageNode(app:sortCollection($collectionUri)[$positionInCollection], $innerAddress)
     return
         <div xmlns="http://www.w3.org/1999/xhtml">
         <div class="text-center">
             {app:formatCatalogEntryForArchiveNumber($documentId)}
             {app:paginationWidget($collectionUri, $positionInCollection)}
  </div>
  <div class="row">
  <div class="col-sm-6">{app:getImageLink(concat('/exist/rest',$app:imageDataPath,$documentId,"/",$meAsJpeg))}</div>
  <div class="col-sm-6">{app:add-attribute-to-ocrword($hocrPageNode, "contenteditable", 'true')}</div>
</div>
</div>
};

