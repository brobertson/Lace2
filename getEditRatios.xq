xquery version "3.1";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace functx="http://www.functx.com";
import module namespace lacesvg="http://heml.mta.ca/Lace2/svg" at "modules/laceSvg.xql";

let $my_collection := xs:string(request:get-parameter('collectionUri', ''))
let $position := xs:int(xs:string(request:get-parameter('positionInCollection', '0')))
return 
lacesvg:getCollectionEditRatios($my_collection, $position)

