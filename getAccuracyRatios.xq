xquery version "3.1";

declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace functx="http://www.functx.com";
import module namespace lacesvg="http://heml.mta.ca/Lace2/svg" at "modules/laceSvg.xql";


let $my_collection := xs:string(request:get-parameter('collectionUri', ''))
(:  
let $dbroot := "/db/Lace2Data/texts/"
  
let $my_collection := concat($dbroot, "632874144/2019-05-30-10-58_wells_2019-05-28-08-22-00025400.pyrnn.gz_selected_hocr_output")
:)
let $width := 2 * count(collection($my_collection))
return 

  
<svg:svg id="svg_accuracy_report" width="{$width}" height="20">
  {lacesvg:getCollectionAccuracyRatios($my_collection)}
</svg:svg>


(:  
<div>
   {local:getCollectionEditRatios($my_collection)}
</div>
:)