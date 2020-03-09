xquery version "3.1";

module namespace app="http://heml.mta.ca/Lace2/templates";

import module namespace file="http://exist-db.org/xquery/file";
import module namespace image="http://exist-db.org/xquery/image";
import module namespace markdown="http://exist-db.org/xquery/markdown";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace compression="http://exist-db.org/xquery/compression";
import module namespace functx="http://www.functx.com";
import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace xh="http://www.w3.org/1999/xhtml";
declare namespace lace="http://heml.mta.ca/2019/lace";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace package="http://expath.org/ns/pkg";
declare namespace xi="http://www.w3.org/2001/XInclude";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
(: 
 : General Helper Functions
 
 :)

declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;

declare  function app:app-version-number($node as node(), $model as map(*)) as xs:string {
    let $pkg := collection(repo:get-root())//package:package[@name='http://heml.mta.ca/Lace/application']
   return $pkg/@abbrev || " v. " || $pkg/@version  
};

 (: 

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

declare function app:get-lace-version($node as node(), $model as map(*)) {
        <xh:span>
        {string(collection('/db/apps/')//package:package[@name = "http://heml.mta.ca/Lace"]/@version)}
        </xh:span>
};

declare function app:contains-collection-starting-with($collection as xs:string, $starting as xs:string) as xs:boolean {
    (: if $child, namely a collection name that starts with $starting, exists then we return true
    otherwise, false 
    :)
exists(for $child in xmldb:get-child-collections($collection)
           where fn:starts-with($child, $starting)
           return $child)
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
        count(collection('/db/apps')//lace:imagecollection/dc:identifier)
};

(: 
 : For a given dc:identifier node, format the contents 
 : TODO: format separator between creators better
 :)
declare function app:formatCatalogEntry($text as node()) {
    let $creator_string :=
    for $creator in $text/../dc:creator
    return 
        $creator/text() || " "
    return
    <xh:span class="catalogueEntry">{$creator_string} ({$text/../dc:date/text()}). <xh:i>{fn:substring($text/../dc:title/text(),1,80)}</xh:i>.</xh:span>
};

(:  Variant of above for use in templates :)
declare function app:formatCatalogEntry($node as node(), $model as map(*), $archive_number as xs:string) {
    let $text := collection('/db/apps')//lace:imagecollection/dc:identifier[text() = $archive_number]
    let $creator_string :=
    for $creator in $text/../dc:creator
    return 
        $creator/text() || " "
    return
    <xh:span class="catalogueEntry">{$creator_string} ({$text/../dc:date/text()}). <xh:i>{fn:substring($text/../dc:title/text(),1,80)}</xh:i>.</xh:span>
};
(: 
 : for a given dc:identifier node, format the contents and link to 
 : its 'runs'
 :)
declare function app:formatCatalogEntryWithRunsLink($text as node()) {
    <xh:a href="{concat("runs.html?archive_number=",$text)}">
        {app:formatCatalogEntry($text)}
    </xh:a>
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

declare function app:formatCatalogEntryForCollectionUri($collectionUri as xs:string) {
for $text in collection($collectionUri)//dc:identifier[1]
return
app:formatCatalogEntryWithRunsLink($text)
};
(: 
 : loop through all the 'archivetext' nodes in the catalogue xml file and 
 : lay them out in a table, linked to their runs. If there are not runs, then
 : don't link them, and assign css class 'notAvailable' 
 : 
 : Rewrite this to look for metadata files, not collection names
 :)

declare function app:catalog($node as node(), $model as map(*)) {
    if (app:countCatalog($node, $model) = 0) then 
        <xh:tr><xh:td>There are no installed texts. Please add them by using the eXist <xh:a href="/exist/apps/dashboard/admin#/packagemanager">package manager</xh:a>. You may need to sign into your 'admin' account first.</xh:td></xh:tr>
    else
    for $text in collection('/db/apps')//lace:imagecollection/dc:identifier
        order by $text/../dc:creator[0]
        return 
            if (exists(collection('/db/apps')//lace:run[dc:identifier/text() = $text/text()]))
            then
                <xh:tr>
                    <xh:td>
                        {app:formatCatalogEntryWithRunsLink($text)}
                    </xh:td>
                </xh:tr>
            else 
                <xh:tr class="notAvailable">
                    <xh:td>{app:formatCatalogEntry($text)}  <xh:span class="text-warning"> (Only this text's image package is installed, with no corresponding text packages.)</xh:span></xh:td>
                </xh:tr>
                
 };
 
 (:
declare function app:catalog($node as node(), $model as map(*)) {
        <xh:p>{collection('/db/apps')//dc:identifier}</xh:p>
};
:)



declare function app:collectionInfo($collectionUri as xs:string) {
let $coll := collection($collectionUri)
let $number_of_spans : = doc($collectionUri || "/totals.xml")/lace:totals/lace:total_words
let $number_of_accurate :=  doc($collectionUri || "/totals.xml")/lace:totals/lace:total_accurate_words
let $percentage_accuracy := format-number($number_of_accurate div  $number_of_spans, '0.0%')
let $number_of_edited := count($coll//xh:span[@data-manually-confirmed = 'true'])
let $percentage_edit := format-number($number_of_edited div  $number_of_spans, '0.00%')
return 
<xh:div>
    <xh:div>Dictionary Words: {$percentage_accuracy}</xh:div>
    <xh:div>Completion: {$percentage_edit}</xh:div>
    <xh:div>Engine: {$coll//lace:ocrengine/text()}</xh:div>
    <xh:div>Classifier: {$coll//lace:classifier/text()}</xh:div>
    <xh:div>Date: {$coll//dc:date/text()}</xh:div>

</xh:div>
};

declare function app:collectionInfo($node as node(), $model as map(*), $collectionUri as xs:string) {
    app:collectionInfo($collectionUri)
};
 (: 
 : Provide a catalog of the $count most recently processed volumes, or archivetexts, 
 : ordered from most recently processed to least. 

 :)
declare function app:latest($node as node(), $model as map(*), $count as xs:string?) {
    let $sorted-runs :=
        for $run in collection('/db/apps')//lace:run/dc:identifier
            order by $run/../dc:date descending
                  return $run
    for $run at $counting in subsequence($sorted-runs, 1, $count)
    let $image_identifier := app:image-identifier-node-for-doc-identifier-node($run)
        return
            <xh:tr>
                <xh:td>{$run/../dc:date}</xh:td> <xh:td>{app:formatCatalogEntryWithRunsLink($image_identifier)}</xh:td>
            </xh:tr>
 };
 
 declare function app:parent-collection-string($collection as xs:string) as xs:string? {
        replace(replace($collection, "^(.*)/[^/]+/?$", "$1"), "/db/Lace2Data/texts/", "")
};

 declare function app:page-number-from-document-name($document-name as xs:string) as xs:string? {
       xs:string(xs:int(substring-before(functx:substring-after-last($document-name, '_'), '.')))
};

declare function app:image-identifier-node-for-doc-identifier-node($doc_identifier_node as node()) {
    collection('/db/apps')//lace:imagecollection/dc:identifier[text() = $doc_identifier_node]
};

(:  TODO this is a duplicate of a function in lacesvg module
 :  It should be faster to just poll the numbers in the running totals,
 :  but it isn't. Maybe they aren't properly indexed.  :)
declare function app:hocrPageCompletion($document_node as node()) {
    format-number(app:hocrPageCompletionFloat($document_node), '0.0%')
};

declare function app:hocrPageCompletionFloat($document_node as node()) {
    let $spans : = $document_node//*[@data-spellcheck-mode]
    let $number_of_spans := count($spans)
    let $edited : = $document_node//*[@data-manually-confirmed = 'true']
    let $number_of_edited := count($edited)
     let $percentage := 
        if ($number_of_spans = 0) then
            0
        else
            ( $number_of_edited div  $number_of_spans)
    return $percentage
};

 declare function app:getDocsAfter($coll as xs:string, $since as xs:dateTime) as node()*
{
    (: we were doing this xmldb:find-last-modified-since(collection($coll), $since) 
    : but since we were getting the last-modified, it made sense to evaluate this in the where clause
    : instead of duplicating the effort
    :)
for $c in collection($coll) 
    let $collectionUri :=   util:collection-name( $c )
    let $last-modified := xmldb:last-modified(util:collection-name($c), util:document-name($c))
	order by $last-modified descending
(:  check that the page has had its span modified, not just the pre-processing we do on install :)
	where (exists($c//xh:span[@data-manually-confirmed = "true"])) and ($last-modified gt $since)
        let $image_identifier := app:getImageIdentifierForDocumentNode($c)
        let $image_position_results := app:getSideBySideViewDataForDocumentElement($c)
        let $docCollectionUri := $image_position_results[1]
        let $position := $image_position_results[2]
        (: get completion percentage of document node :)
        let $completion_percentage := app:hocrPageCompletion($c)
		    return
		       <xh:tr><xh:td class="date">{format-dateTime($last-modified, "[H01]:[m01]:[s01] [Y0001]-[M01]-[D01]")}</xh:td>
		       <xh:td>{app:formatCatalogEntry($image_identifier)}</xh:td>
		       <xh:td><xh:a href="side_by_side_view.html?collectionUri={$docCollectionUri}&amp;positionInCollection={$position}">{$position}</xh:a></xh:td><xh:td>{$completion_percentage}</xh:td>
		       </xh:tr>
	    
};

declare function app:getImageIdentifierForDocumentNode($c as node()) {
    	let $identifier := collection(util:collection-name( $c ))//dc:identifier[1]
        return app:image-identifier-node-for-doc-identifier-node($identifier)
};

declare function app:getSideBySideViewDataForDocumentElement($c as node()) {
    let $collectionUri :=   util:collection-name( $c )
    let $image_identifier := app:getImageIdentifierForDocumentNode($c)
    let $image_collection := util:collection-name($image_identifier)
    let $image_name :=  replace(util:document-name($c),"html","png")
    let $imageNode := util:binary-doc($image_collection || "/" || $image_name)
    let $document-number := app:page-number-from-document-name(util:document-name($c))
    let $sortedImageCollection := app:sortPngCollection($image_collection)
    let $positionInCollection := index-of($sortedImageCollection, $image_name) 
    return ( $collectionUri, $positionInCollection)
};

declare function app:getRecentlyModifiedPages($node as node(), $model as map(*), $days_ago as xs:string?) as node()*
{
let $coll := "/db/apps/"
let $days_string := concat('P', xs:string($days_ago), 'D')
let $since := xs:dateTime(current-dateTime()) - xs:dayTimeDuration($days_string)
   return 
   <xh:table class="table">
      <xh:thead>
        <xh:tr>
            <xh:th scope="col">Date</xh:th>
            <xh:th scope="col">Volume</xh:th>
            <xh:th scope="col">Page</xh:th>
            <xh:th scope="col">Page Completion</xh:th>
        </xh:tr>
      </xh:thead>
      <xh:tbody>
         {app:getDocsAfter($coll, $since)}
      </xh:tbody>
    </xh:table>
};

(: 
 : End of functions relating to catalog entries.
 : 
 : The following functions format and present 'runs', 
 : that is, OCR jobs on a given text
 :  :)
 
(: For a given $archive_number, chronologically list all the runs, in descending order :)
declare function app:runs($node as node(), $model as map(*),  $archive_number as xs:string?) {

    for $run in collection('/db/apps')//lace:run[dc:identifier/text() = $archive_number]
    order by $run/dc:date descending
return
    <xh:tr>
<xh:td><xh:a href="{concat("side_by_side_view.html?collectionUri=",app:hocrCollectionUriForRunMetadataFile($run),"&amp;positionInCollection=2")}">{$run/dc:date}</xh:a>{app:runDownloadsMenu($run)}</xh:td>
<xh:td>{app:collectionInfo(app:hocrCollectionUriForRunMetadataFile($run))}</xh:td>
</xh:tr>
};



declare function app:hocrCollectionUriForRunMetadataFile($run as node()) {
  util:collection-name($run)
};

(: Every run can, and often does, have multiple HOCR types, representing various stages of the process.
 : These might be 'raw', 'combined', 'selected' and so forth.
 : This function formats these types with hocrTypeStringForNumber and, if files are indeed available for
 : that run, it makes a link to the side-by-side view of that hocr type's pages. :)

declare function app:runDownloadsMenu($run as node()) {
    let $collectionUri :=   util:collection-name( $run )
    let $conditional_items :=
        if (exists(collection($collectionUri)//xh:span[@class="ocr_line"][not (xh:span/@data-manually-confirmed = 'false')])) then
            (
            <xh:li><xh:a id="download_training_csv" href="{concat("get_trainingset.xq?collectionUri=",app:hocrCollectionUriForRunMetadataFile($run), "&amp;format=csv")}">Download Training Set File</xh:a></xh:li>,
            <xh:li><xh:a id="download_training_images" href="{concat("get_trainingset_images.xq?collectionUri=",app:hocrCollectionUriForRunMetadataFile($run))}">Download Training Set Images</xh:a></xh:li>
            )
        else
            (<xh:li><xh:a onclick="error_message('A training set cannot be generated because there are no corrected lines')" href="#">Download Training Set File</xh:a></xh:li>,
            <xh:li><xh:a onclick="error_message('A training set cannot be generated because there are no corrected lines')" href="#">Download Training Set Images</xh:a></xh:li>)
        
    return
    <xh:span id="downloadsMenu">
                <xh:div class="btn-group">
              <xh:button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Downloads<xh:span class="caret"></xh:span>
              </xh:button>
              <xh:ul class="dropdown-menu">
                <xh:li><xh:a id="download_xar" href='{concat("getZippedCollection.xq?collectionUri=",$collectionUri, "&amp;format=xar")}'>Download XAR File</xh:a></xh:li>
                <xh:li><xh:a id="download_txt" href="{concat("getZippedCollection.xq?collectionUri=",app:hocrCollectionUriForRunMetadataFile($run), "&amp;format=text")}">Download Plain Text Zip File</xh:a></xh:li>
                {$conditional_items}
                <xh:li><xh:a id="download_tei" href='{concat("getTeiVolume.xq?collectionUri=",$collectionUri)}'>Download TEI File</xh:a></xh:li>
              </xh:ul>
            </xh:div>
            </xh:span>

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
    <!-- delete the breaks. They just mess up formatting -->
    <xsl:template match="xh:br"/>
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
     {$hocrPageNode/xh:html/xh:body/xh:div/*}
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
      <a class="page-link" href="{concat("?collectionUri=", $collectionUri, "&amp;positionInCollection=", $targetIndex)}">{$label}</a>
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

(:  TODO: handle the case where this does not return a collection :)
declare function app:imageCollectionFromCollectionUri($collectionUri as xs:string) {
        let $identifier := collection($collectionUri)//dc:identifier
        let $imageMetadata := collection('/db/apps')//lace:imagecollection[dc:identifier = $identifier]/dc:title
        let $imageCollection := util:collection-name($imageMetadata)
        return $imageCollection
};

declare function app:imageCollectionFromCollectionUriPublic($node as node(), $model as map(*), $collectionUri as xs:string) {
    <p>{app:imageCollectionFromCollectionUri($collectionUri)}</p>
};



(: 
 : Because the sequence of filenames that comes from the 'collection' function
 : is unordered, we use this function to make sure it is ordered by the names
 : of the files, which should be standardized to something like volumeidentifier_0123.html
 :)

declare function app:sortCollection($collectionUri as xs:string, $requiredSuffix as xs:string) {
    for $item in collection($collectionUri)
    (: There are other files in this collection, including repo.xml, etc. 
    :  So we filter it to include only the images. They must be pngs.
    :)
    where (functx:substring-after-last(util:document-name($item), '.') = $requiredSuffix) 
    order by util:document-name($item)
    return util:document-name($item)
    
};

declare function app:sortPngCollection($collectionUri as xs:string) {
    app:sortCollection($collectionUri,'png')
};

declare function app:sortHtmlCollection($collectionUri as xs:string) {
    app:sortCollection($collectionUri,'html')
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

declare function app:dropdownMenu() {
    <xh:span id="dropdownMenu">
                <xh:div class="btn-group">
              <xh:button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><xh:span class="caret"></xh:span>
              </xh:button>
              <xh:ul class="dropdown-menu">
                <xh:li><xh:a id="run_info" href='#'>Run Info</xh:a></xh:li>
                <xh:li><xh:a id="editing_view" href="#">Run Editing View</xh:a></xh:li>
                <xh:li><xh:a id="accuracy_view" href="#">Run Accuracy View</xh:a></xh:li>
              </xh:ul>
            </xh:div>
            <xh:div id="info_alert" class="panel panel-default">
            <xh:div class="panel-body">
            <xh:button type="button" id="info_close"  class="close" aria-label="Close">
            <xh:span aria-hidden="true">x</xh:span></xh:button>
            <xh:p class="text-center">Run Info</xh:p>
            <xh:p id="info_p"/>
            </xh:div>
            </xh:div>
            <xh:div class="panel panel-default">
            <xh:div id="svg_accuracy_report_holder" class="panel-body" >
            <xh:button type="button" id="accuracy_close"  class="close" aria-label="Close">
            <xh:span aria-hidden="true">x</xh:span></xh:button>
            <p class="text-center">Accuracy</p>
            <svg:svg id="svg_accuracy_report"/>
            </xh:div>
            </xh:div>
            <xh:div class="panel panel-default">
            <xh:div id="svg_edit_report_holder" class="panel-body">
            <xh:button type="button" id="edit_close"  class="close" aria-label="Close">
            <xh:span aria-hidden="true">x</xh:span></xh:button>
                <p class="text-center">Editing Progress</p>
            <svg:svg id="svg_edit_report"/>
            </xh:div>
            </xh:div>
<!-- a CSS-only spinner to show the user that the svg report is loading -->
                <xh:div id="bars3">
                </xh:div>
                <!-- end dropdownMenu -->
                </xh:span>
};

declare function local:generate-zone-item-from-map($key, $value) {
  (: deciding what to put here is your problem, not mine :)
  <xh:li class="dropdown-item" id="{$value}">{$key}</xh:li>
};

declare function app:makeZoningMenu() {
    let $zoning_items := map{ 'Title':'title', 'Page Number':'page_number', 'Primary Text':'primary_text','App. Crit.':'app_crit', 'Commentary':'commentary', 'Translation':'translation'}
    let $zoning_items_order := map{'Title':1, 'Page Number':2, 'Primary Text':3, 'App. Crit.':4, 'Commentary':5, 'Translation':6}
    let $items :=
        for $key in map:keys($zoning_items)
        order by $zoning_items_order($key)
        return <xh:li class="dropdown-item zoning-dropdown-item" id="{$zoning_items($key)||'_button'}">{$key}</xh:li>

    return
        <xh:div class="btn-group">
      <xh:button class="btn btn-secondary dropdown-toggle btn-sm" type="button" id="dropdownMenuButton2" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
        Zone Type
      </xh:button>
      <xh:ul id="zoning_choice" class="dropdown-menu">
    {$items}
       </xh:ul>
      </xh:div>
};

(:  Given an IMAGE position within a Document / Run, provide the editing view 
 : We've swapped over to image positions so that we can easily compare run to run
 : and because image is the base unit of this work. 
 : Previously position referred to the position of the html file in this run collection
 :  :)
 
declare function app:sidebyside($node as node(), $model as map(*), $collectionUri as xs:string, $positionInCollection as xs:integer?) {
(:  The $collectionUri is for the run collection
 :  The $positionInCollection is an *image* position 
 :  Sorry for the confusion. :)
let $imageCollection := app:imageCollectionFromCollectionUri($collectionUri)
let $meAsPng := app:sortPngCollection($imageCollection)[$positionInCollection]
let $myImageHeight := image:get-height(util:binary-doc(concat($imageCollection,"/",$meAsPng)))
let $myImageWidth := image:get-width(util:binary-doc(concat($imageCollection,"/",$meAsPng)))
let $scaleWidth := 500
let $image_scale := $scaleWidth div $myImageWidth
let $scaledHeight := $myImageHeight * $image_scale
let $me := replace($meAsPng,"png","html")
let $me_as_svg := replace($meAsPng,"png","svg")
let $meAsDocumentNode := doc($collectionUri || "/" || $me)
let $svg_dir_name := "SVG"
let $meAsSvgFilePath := $collectionUri || "/" || $svg_dir_name || "/" || $me_as_svg
let $svg_canvas := 
if (doc-available($meAsSvgFilePath)) then
        doc($meAsSvgFilePath)
    else
        <svg xmlns="http://www.w3.org/2000/svg"  id="svg" width="500" height="{$scaledHeight}">
            <image xmlns:xlink="http://www.w3.org/1999/xlink" id="page_image" x="0" y="0" width="500" height="{$scaledHeight}" data-scale="{$image_scale}"
            xlink:href="{concat('/exist/rest',$imageCollection,"/",$meAsPng)}"/>
            <rect id="svg_focus_rect" x="10" y="10" height="130" width="500" fill-opacity="0.4"
        style="fill: #aaffff; stroke: #aaffff; stroke-width: 1; stroke-opacity: 0.5"/>
        </svg>


(: Scale the svg stuff :)

(:  It is possible that the hocr page corresponding to the JPG file doesn't exist.
 : This would be because the processing failed, for instance. In this case, 
 : we need to return an error page to that fact. :)
let $hocrPageNode := 
if (empty($meAsDocumentNode))
then
    <xh:div class="alert alert-warning">There is no OCR output for this page ({$collectionUri || "/" || $me}) in this run.</xh:div>
else 
    let $rawHocrNode := $meAsDocumentNode/xh:html/xh:body/xh:div
    let $innerAddressWithHead := $collectionUri || '/' || util:document-name($rawHocrNode)
    let $innerAddress := replace($innerAddressWithHead,'db/apps', "")
    return app:fixHocrPageNode($meAsDocumentNode, $innerAddressWithHead)
(:  Done getting $hocrPageNode variable :)
 (: Here's the output of the actual function :)    
     return
         <xh:div>
         <xh:div class="text-center" >
                         
<button type="button" class="btn btn-info btn-sm" data-toggle="modal" data-target="#editingInfo">?</button>{app:formatCatalogEntryForCollectionUri($imageCollection)}
             {app:dropdownMenu()}
             {app:paginationWidget($collectionUri, $positionInCollection)} 

<div id="editingInfo" class="modal fade" role="dialog">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal">x</button>
        <h4 class="modal-title">Editing Page</h4>
      </div>
      <div class="modal-body">
      <p>This is one of many editing pages for the OCR run you selected of this volume. Beside the volume title, a drop down menu gives you three bands of information about the run:
          <ol>
              <li>Run Info: text describing the run.</li>
              <li>Run Editing View: A colored band representing the sequence of pages in this volume. Black sections are unedited, blue ones are completely edited, the spectrum of colors from red to blue represent the stages in between. Pages for which there is no output is colored gray. This view is generated dynamically, and represents the current state of the volume. A caret shows this page's position in the volume.</li>
              <li>Run Accuracy View: Another colored band representing the sequence of pages in this volume, but in this case the colours show how accurate the OCR output in each page is, with accuracy measured by dictionary words per total words.</li>
        </ol>
        Mousing over either of the last two views will cause the page number corresponding to the section of the band to appear, and clicking on that part of the band will navigate to a new editing page.
      </p>
<p>Below this is a pagination bar with which you can navigate through the text's editing pages. The numbers do not necessarily indicate the printed page number or the number in the image file's name. Rather, they are the ordinal value of this image in the collection.</p>
<p>There is a separate page <a href="editing.html">explaining</a> how to zone the image and edit the text.</p>
      </div>
</div>
</div>
</div>

            <xh:div class="progress"> 
  <xh:div id="progress_bar" class="progress-bar" role="progressbar" aria-valuenow="2" aria-valuemin="0" aria-valuemax="100" style="width: 0%"></xh:div>
        </xh:div>
  <xh:div class="row">
  <!-- comprises the image on the left and text on right -->
  <xh:div id="left_side" class="col-sm-6">
    
  <!-- the div for the page image -->
 <div class="col-sm-1">
      </div>
<div class="row form-group">
    <div class="col-sm-3">
{app:makeZoningMenu()}
</div>
<div class="col-sm-1">
<button type="button" id="clear_zones_button" class="btn btn-sm">Clear Zones</button>
</div>
 <!--div class="col-sm-1">
      One</div>
    <div class="col-sm-3">
      Twho
    </div>
        <div class="col-sm-4">
      three
    </div-->
</div>
<div class="row">
<!-- svg 'canvas' for the page image -->
<!-- you need this div to keep this below the buttons -->
<xh:div id="svg_container">
{$svg_canvas}
</xh:div>
</div>

</xh:div>
  <!-- the old, non-svg way of doing things -->
  <!--xh:div class="col-sm-6">{app:getImageLink(concat('/exist/rest',$imageCollection,"/",$meAsPng))}</xh:div-->

  <xh:div class="col-sm-6 text-left" id="right_side">
  <!-- The hocr, which is layed out on the right of this page -->
  {app:add-attribute-to-ocrword($hocrPageNode, "contenteditable", 'true')}
  </xh:div>
</xh:div>

<!-- end interior coll and row -->
<!--/xh:div>
</xh:div-->

</xh:div>
</xh:div>
};


(:  
 : 
 : Functions related to search 
 :)

declare function app:convert-match-expanded-to-hocr($node as node()) {
    (: the util:exand function produces these ugly exist:match tags around the matched text. 
     : Here, we convert these to <xh:span class="match"/>
     :)
    typeswitch ($node)
        case $my as element(exist:match) return
            <xh:span class="match">{$my/text()}</xh:span>
        case $node as element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return app:convert-match-expanded-to-hocr($child)
            }
        default return
            $node
};


declare function app:formatSearchHit($hit as node()) as node() {
    let $expanded := app:convert-match-expanded-to-hocr(util:expand($hit, "expand-xincludes=no"))
    let $score as xs:float := ft:score($hit)
    let $image_position_results := app:getSideBySideViewDataForDocumentElement($hit)
    let $docCollectionUri := $image_position_results[1]
    let $position := $image_position_results[2]
    (: there's clearly a problem with namespacing on these cts_picker spans. TODO: FIX :)
    let $canonical_reference := $hit/preceding::*[@class="cts_picker"][1]
    let $canonical_reference_text :=
        if ($canonical_reference) then
            " (" || string($canonical_reference/@title) || ")"
            else
                ""
        return
            <xh:div>
        <xh:div class="search_results">{$expanded}<xh:code>p. <xh:a href="side_by_side_view.html?collectionUri={$docCollectionUri}&amp;positionInCollection={$position}#{string($hit/@id)}">{$position}</xh:a></xh:code></xh:div>
        <xh:div><xh:span> {$canonical_reference_text}</xh:span>
        </xh:div>
        </xh:div>
        
};

declare function app:search($node as node(), $model as map(*), $search as xs:string, $collectionUri as xs:string) {
    for $hit in collection($collectionUri)//xh:span[ft:query(.,$search)][@class="ocr_line"]
    order by xs:int($hit/ancestor::xh:div[@class="ocr_page"]/@data-image-position)
    return (
        <xh:tr><xh:td>
        {app:formatSearchHit($hit)}
        </xh:td>
        </xh:tr>
)
};

declare function app:searchAllCollections($node as node(), $model as map(*)) {
    (: TODO make a global variable $search_default, which is used here and in search.html :)
    let $search:= request:get-parameter('search', 'λαμβ*')
    for $run in collection("/db/apps")//lace:run
        let $collectionUri := util:collection-name($run)
        (: TODO: Order these alphabetically, or whatever :)
        return
            <xh:div>
            <xh:h3>{app:formatCatalogEntry(app:getImageIdentifierForDocumentNode($run))}</xh:h3>
            {app:collectionInfo($collectionUri)}
            <xh:div>    <table class="table table-hover table-dark">
            <tbody>
                {app:search($node, $model, $search, $collectionUri )}
            </tbody>
        </table>
            </xh:div>
            </xh:div>
};
