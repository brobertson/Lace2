xquery version "3.0";

module namespace app="http://heml.mta.ca/Lace2/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://heml.mta.ca/Lace2/config" at "config.xqm";
import module namespace file="http://exist-db.org/xquery/file";
import module namespace image="http://exist-db.org/xquery/image";
import module namespace markdown="http://exist-db.org/xquery/markdown";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace ls="ls";
declare namespace local="http://heml.mta.ca/Namespace/local";
declare namespace xh="http://www.w3.org/1999/xhtml";
declare variable $app:dataPath :="/db/Lace2Data";

declare variable $app:textDataPath := $app:dataPath || "texts/";
declare variable $app:imageDataPath := $app:dataPath || "images/";
declare variable $app:catalogFile := doc($app:dataPath || "metadata/laceTexts.xml");
(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute data-template="app:test" 
 : or class="app:test" (deprecated). The function has to take at least 2 default
 : parameters. Additional parameters will be mapped to matching request or session parameters.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
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
{$run/date}<a href="{concat("runs.html?archive_number=",$run/../archive_number)}">{$run/../creator} ({$run/../date}). <i>{fn:substring($run/../title,1,80)}</i>. {$run/../volume}</a>
</td>
</tr>
 };


declare function app:countCatalog($node as node(), $model as map(*)) {
        count($app:catalogFile/texts/archivetext) || " "
};

declare function app:catalog($node as node(), $model as map(*)) {
for $text in $app:catalogFile/texts/archivetext
order by $text/creator
return if  (xmldb:collection-available($app:textDataPath || $text/archive_number)) 
then
<tr>
    <td>
<a href="{concat("runs.html?archive_number=",$text/archive_number)}">{$text/creator/text()} ({$text/date/text()}). <i>{fn:substring($text/title/text(),1,80)}</i>. {$text/volume/text()}</a>
</td>
</tr>
else 
    <tr class="notAvailable">
    <td>{$text/creator/text()} ({$text/date/text()}). <i>{fn:substring($text/title/text(),1,80)}</i>. {$text/volume/text()}</td></tr>
 };

declare function app:runsAvailable($text as xs:string) {
  xmldb:collection-available($app:textDataPath || $text)
};

declare function app:formatWorkAndLinkToRuns($archive_number as xs:string) {
for $text in $app:catalogFile/texts/archivetext[archive_number=$archive_number][1]
return
<a href="{concat("runs.html?archive_number=",$archive_number)}">{$text/creator} ({$text/date}). <i>{fn:substring($text/title,1,80)}</i>. {$text/volume}</a>
};

declare function app:runs($node as node(), $model as map(*),  $archive_number as xs:string?) {
    for $run in $app:catalogFile/texts/archivetext[archive_number=$archive_number][1]/run
    order by $run/date descending
return
    <tr>
<td>{$run/date}</td> <td>{$run/classifier}</td><td>{app:hocrTypes($run)}</td>
</tr>
};

declare function app:hocrTypeStringForNumber($hocrTypeName as xs:string) {
     let   $name :=  switch ($hocrTypeName) 
   case "0" return "raw"
   case "1" return "combined"
   case "2" return "selected"
   case "3" return "selected"
   default return "HOCR Type *Out of bounds*"
   return $name
};

declare function app:cropImage() {
  let $bin := file:read-binary('data/images/624438295/624438295_0036.jpg')
  return image:crop($bin,(100,100,200,200),"image/jpeg")  
};

declare function app:hocrTypes($run as node()) {
    for $hocrtype in $run/hocrtype
    return 
        if (xmldb:collection-available(concat($app:textDataPath,$run/../archive_number)))
        then
            <td><a href="{concat("side_by_side_view.html",app:hocrCollectionLinkForhocrTypeElement($hocrtype))}">{app:hocrTypeStringForNumber($hocrtype)}</a></td>
        else
            <td>{app:hocrTypeStringForNumber($hocrtype)}</td>
};

declare function app:hocrCollectionLinkForhocrTypeElement($hocrtype as node()) {
  let $reply := concat("?documentId=",$hocrtype/../../archive_number,"&amp;runId=",$hocrtype/../date,"&amp;classifier=",$hocrtype/../classifier,"&amp;fileNum=25")

  return 
      $reply
  (:Example: /db/laceData/historiaerecogno02thucuoft/2016-01-16-13-14_porson-2013-10-23-16-14-00100000.pyrnn.gz_selected_hocr_output/historiaerecogno02thucuoft_0023.html
  
  /db/laceData/25965323/2018-05-15-08-55_loeb_2016-03-20-14-17-00128200.pyrnn.gz_selected_hocr_output/25965323_0025.html
  :)
};

declare function app:formatWork($archive_number as xs:string) {
for $text in $app:catalogFile/texts/archivetext[archive_number=$archive_number][1]
return
<p>{$text/creator} ({$text/date}). <i>{fn:substring($text/title,1,80)}</i>. {$text/volume}</p>
};

declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the class attribute <code>class="app:test"</code>.</p>
};

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

declare function app:fixHocrPageNode($hocrPageNode as node(), $innerAddress as xs:string) {
       let $foo := "abr"
       return
        <xh:div class="ocr_page" title="{$innerAddress}">
        {$hocrPageNode/xh:html/xh:body/xh:div[@class="ocr_page"]/*}
        </xh:div>
};

declare function app:sidebyside($node as node(), $model as map(*), $fileNum as xs:integer?, $documentId as xs:string?, $runId as xs:string?, $classifier as xs:string) {
         let $fileNumFormat := format-number($fileNum, '0000')
         let $imageFile := concat("http://heml.mta.ca/ocrchallenge/static/Images/Color/",$documentId,"_color/",$documentId,"_",$fileNumFormat,".jpg")
 let $nextFileNum := $fileNum + 1
 let $previousFileNum := $fileNum -1 
 let $file := "/db/laceData/894469813v1/2017-06-30-09-00_bude-2017-06-15-13-39-00040500.pyrnn.gz_selected_hocr_output/894469813v1_0031.html"
 let $innerAddress := concat($documentId,"/",$runId,"_",$classifier,"_selected_hocr_output/",$documentId,"_",$fileNumFormat,".html")
 let $htmlFile := concat($app:textDataPath,$innerAddress)
 let $hocrPageNode := app:fixHocrPageNode(doc($htmlFile), $innerAddress)
 let $imageFile := concat("http://heml.mta.ca/ocrchallenge/static/Images/Color/",$documentId,"_color/",$documentId,"_",$fileNumFormat,".jpg")
 let $imageFile := concat('data/images/',$documentId,"/",$documentId,"_",$fileNumFormat,".jpg")
 let $paramsWithoutFileNum := concat("?documentId=",$documentId,"&amp;runId=",$runId,"&amp;classifier=",$classifier,"&amp;fileNum=")
     return
         <div xmlns="http://www.w3.org/1999/xhtml">
         <div class="text-center">
         {app:formatWorkAndLinkToRuns($documentId)}
  <nav aria-label="...">
  <ul class="pagination">
    <li class="page-item">
      <a class="page-link" href="{concat($paramsWithoutFileNum,$previousFileNum)}" tabindex="-1">Previous</a>
    </li>
    <li class="page-item"><a class="page-link" href="{concat($paramsWithoutFileNum,1)}">1</a></li>
     <li class="page-item"><a class="page-link" href="{concat($paramsWithoutFileNum,$fileNum -5 )}">-5</a></li>
    <li class="page-item active">
      <a class="page-link" href="#">{$fileNum}<span class="sr-only">(current)</span></a>
    </li>
    <li class="page-item"><a class="page-link" href="{concat($paramsWithoutFileNum,$fileNum + 5)}">+5</a></li>
    <li class="page-item">
      <a class="page-link" href="{concat($paramsWithoutFileNum,$nextFileNum)}">Next</a>
    </li>
  </ul>
  </nav>
  </div>
  <div class="row">
  <div class="col-sm-6">{app:getImageLink($imageFile)}</div>
  <div class="col-sm-6">      {app:add-attribute-to-ocrword($hocrPageNode, "contenteditable", 'true')}</div>
</div>
</div>
};

declare function app:getImageLink($imageFile as xs:string?) {
    (: if (doc:available()) doesn't work with these binary files. Find another approach :)
    <img width="500"  class="img-responsive" onclick="return page_back()" id="page_image" src="{$imageFile}" alt="photo"/>
};


declare function app:hocr($node as node(), $model as map(*),  $file as xs:string?) {
  <div>
   doc("/db/laceData/historiaerecogno02thucuoft/2016-01-16-13-14_porson-2013-10-23-16-14-00100000.pyrnn.gz_selected_hocr_output/historiaerecogno02thucuoft_0023.html")/xh:html/xh:body/xh:div[@class="hocr_page"]
  Hi there.
      
  </div>

};

declare function app:helloworld($node as node(), $model as map(*), $name as xs:string?) {
    if ($name) then
        <p>Hello {$name}!</p>
    else
        ()
};

declare function app:renderMarkdown($node as node(), $model as map(*), $name as xs:string?) {
    if ($name) then
        markdown:parse("This is a *fine* howdydo.")
    else
        (markdown:parse(fn:string($node)))
};

declare function app:ls($node as node(), $model as map(*), $dir as xs:string?) {
    if ($dir) then
        <p>{ls:ls($dir)}</p>
    else
        ()
};

declare function app:count-collection($node as node(), $model as map(*), $dir as xs:string?) {
   let $count := count(xmldb:get-child-resources($dir))
   return $count
};



declare function ls:ls($collection as xs:string) as element()* {

  if (xmldb:collection-available($collection)) then
    (         
      for $child in xmldb:get-child-collections($collection)
      let $path := concat($collection, '/', $child)
      order by $child 
      return
        <collection name="{$child}" path="{$path}">
          {
            if (xmldb:collection-available($path)) then (  
              attribute {'files'} {count(xmldb:get-child-resources($path))},
              attribute {'cols'} {count(xmldb:get-child-collections($path))},
              sm:get-permissions(xs:anyURI($path))/*/@*
            )
            else 'no permissions'
          }
          {ls:ls($path)}
        </collection>,

        for $child in xmldb:get-child-resources($collection)
        let $path := concat($collection, '/', $child)
        order by $child 
        return
          <resource name="{$child}" path="{$path}" mime="{xmldb:get-mime-type(xs:anyURI($path))}" size="{fn:ceiling(xmldb:size($collection, $child) div 1024)}">
            {sm:get-permissions(xs:anyURI($path))/*/@*}
          </resource>
          
    )
  else ()    
};
