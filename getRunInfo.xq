xquery version "3.1";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "modules/app.xql";
let $my_collection := xs:string(request:get-parameter('collectionUri', ''))

return app:collectionInfo($my_collection)


