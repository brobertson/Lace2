xquery version "1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(: store the collection configuration :)
local:mkcol("/db/system/config", $target),
xdb:store-files-from-pattern(concat("/system/config", $target), $dir, "*.xconf"),
(:  Added by BGR to usual stuff, this changes the public repository to the one
 : that contains Lace stuff  :)
update replace doc("/db/apps/packageservice/configuration.xml")/settings/repositories/repository with <repository active="true" default="true">http://heml.ddns.net:8080/exist/apps/public-repo/public</repository>
