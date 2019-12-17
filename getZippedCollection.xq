xquery version "3.1";
import module namespace transform = "http://exist-db.org/xquery/transform";
import module namespace compression = "http://exist-db.org/xquery/compression";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace functx="http://www.functx.com";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";
declare namespace deploy="http://heml.mta.ca/Lace/deploy";
declare namespace expath="http://expath.org/ns/pkg";

(::::::::::::
 : Start material copied from eXide's deployment.xql library. I'd rather import it, but
 : it has a local: namespace that needs to be declared, etc.
 : This is here to download an actual whole xar library. Unlike my code,
 : it deals with non-xml files and it works recursively.
 : My code, below, namespaced 'local' is for txt and xml output.
 :  
 :  :)

declare variable $deploy:app-root := request:get-attribute("app-root");



(: Handle difference between 4.x.x and 5.x.x releases of eXist :)
declare variable $local:copy-resource :=
    let $fnNew := function-lookup(xs:QName("xmldb:copy-resource"), 4)
    return
        if (exists($fnNew)) then
            $fnNew
        else
            let $fnOld := function-lookup(xs:QName("xmldb:copy"), 3)
            return
                function($sourceCol, $sourceName, $targetCol, $targetName) {
                    $fnOld($sourceCol, $targetCol, $sourceName)
                };

declare function deploy:select-option($value as xs:string, $current as xs:string?, $label as xs:string) {
    <option value="{$value}">
    { if (exists($current) and $value eq $current) then attribute selected { "selected" } else (), $label }
    </option>
};

declare function deploy:store-expath($collection as xs:string?, $userData as xs:string*, $permissions as xs:string?) {
    let $includeAll := request:get-parameter("includeall", ())
    let $descriptor :=
        <package xmlns="http://expath.org/ns/pkg"
            name="{request:get-parameter('name', ())}" abbrev="{request:get-parameter('abbrev', ())}"
            version="{request:get-parameter('version', ())}" spec="1.0">
            <title>{request:get-parameter("title", ())}</title>
            {
                if (empty($includeAll)) then
                    <dependency package="http://exist-db.org/apps/shared"/>
                else
                    ()
            }
        </package>
    return (
        xmldb:store($collection, "expath-pkg.xml", $descriptor, "text/xml"),
        let $targetPath := xs:anyURI($collection || "/expath-pkg.xml")
        return (
            sm:chmod($targetPath, $permissions),
            sm:chown($targetPath, $userData[1]),
            sm:chgrp($targetPath, $userData[2])
        )
    )
};

declare function deploy:repo-descriptor() {
    <meta xmlns="http://exist-db.org/xquery/repo">
        <description>
        {
            let $desc := request:get-parameter("description", ())
            return
                if ($desc) then $desc else request:get-parameter("title", ())
        }
        </description>
        {
            for $author in request:get-parameter("author", ())
            return
                <author>{$author}</author>
        }
        <website>{request:get-parameter("website", ())}</website>
        <status>{request:get-parameter("status", ())}</status>
        <license>GNU-LGPL</license>
        <copyright>true</copyright>
        <type>{request:get-parameter("type", "application")}</type>
        {
            let $target := request:get-parameter("target", ())
            return
                if (exists($target)) then
                    <target>{$target}</target>
                else
                    ()
        }
        <prepare>{request:get-parameter("prepare", ())}</prepare>
        <finish>{request:get-parameter("finish", ())}</finish>
        {
            if (request:get-parameter("owner", ())) then
                let $group := request:get-parameter("group", ())
                return
                    <permissions user="{request:get-parameter('owner', ())}"
                        password="{request:get-parameter('password', ())}"
                        group="{if ($group != '') then $group else 'dba'}"
                        mode="{request:get-parameter('mode', ())}"/>
            else
                ()
        }
    </meta>
};

declare function deploy:store-repo($descriptor as element(), $collection as xs:string?, $userData as xs:string*, $permissions as xs:string?) {
    (
        xmldb:store($collection, "repo.xml", $descriptor, "text/xml"),
        let $targetPath := xs:anyURI($collection || "/repo.xml")
        return (
            sm:chmod($targetPath, $permissions),
            sm:chown($targetPath, $userData[1]),
            sm:chgrp($targetPath, $userData[2])
        )
    )
};

declare function deploy:mkcol-recursive($collection, $components, $userData as xs:string*, $permissions as xs:string?) {
    if (exists($components)) then
        let $permissions :=
            if ($permissions) then
                deploy:set-execute-bit($permissions)
            else
                "rwxr-x---"
        let $newColl := xs:anyURI(concat($collection, "/", $components[1]))
        let $exists := xmldb:collection-available($newColl)
        return (
            xmldb:create-collection($collection, $components[1]),
            if (exists($userData) and not($exists)) then (
                sm:chmod($newColl, $permissions),
                sm:chown($newColl, $userData[1]),
                sm:chgrp($newColl, $userData[2])
            ) else
                (),
            deploy:mkcol-recursive($newColl, subsequence($components, 2), $userData, $permissions)
        )
    else
        ()
};

declare function deploy:mkcol($path, $userData as xs:string*, $permissions as xs:string?) {
    let $path := if (starts-with($path, "/db/")) then substring-after($path, "/db/") else $path
    return
        deploy:mkcol-recursive("/db", tokenize($path, "/"), $userData, $permissions)
};

declare function deploy:create-collection($collection as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $target := collection($collection)
    return
        if ($target) then
            $target
        else
            deploy:mkcol($collection, $userData, $permissions)
};

declare function deploy:check-group($group as xs:string) {
    if (sm:group-exists($group)) then
        ()
    else
        sm:create-group($group)
};

declare function deploy:check-user($repoConf as element()) as xs:string+ {
    let $perms := $repoConf/repo:permissions
    let $user := if ($perms/@user) then $perms/@user/string() else sm:id()//sm:real/sm:username/string()
    let $group := if ($perms/@group) then $perms/@group/string() else sm:get-user-groups($user)[1]
    let $create :=
        if (sm:user-exists($user)) then
            if (index-of(sm:get-user-groups($user), $group)) then
                ()
            else (
                deploy:check-group($group),
                sm:add-group-member($user, $group)
            )
        else (
            deploy:check-group($group),
            sm:create-account($user, $perms/@password, $group, ())
        )
    return
        ($user, $group)
};

declare function deploy:target-permissions($repoConf as element()) as xs:string {
    let $permissions := $repoConf/repo:permissions/@mode/string()
    return
        if ($permissions) then
            if ($permissions castable as xs:int) then
                sm:octal-to-mode($permissions)
            else
                $permissions
        else
            "rw-rw-r--"
};

declare function deploy:set-execute-bit($permissions as xs:string) {
    replace($permissions, "(..).(..).(..).", "$1x$2x$3x")
};

declare function deploy:copy-templates($target as xs:string, $source as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $null := deploy:mkcol($target, $userData, $permissions)
    return
    if (exists(collection($source))) then (
        for $resource in xmldb:get-child-resources($source)
        let $targetPath := xs:anyURI(concat($target, "/", $resource))
        return (
            $local:copy-resource($source, $resource, $target, $resource),
            let $mime := xmldb:get-mime-type($targetPath)
            let $perms :=
                if ($mime eq "application/xquery") then
                    deploy:set-execute-bit($permissions)
                else $permissions
            return (
                sm:chmod($targetPath, $perms),
                sm:chown($targetPath, $userData[1]),
                sm:chgrp($targetPath, $userData[2])
            )
        ),
        for $childColl in xmldb:get-child-collections($source)
        return
            deploy:copy-templates(concat($target, "/", $childColl), concat($source, "/", $childColl), $userData, $permissions)
    ) else
        ()
};

declare function deploy:store-templates-from-db($target as xs:string, $base as xs:string, $userData as xs:string+, $permissions as xs:string) {
    let $template := request:get-parameter("template", "basic")
    let $templateColl := concat($base, "/templates/", $template)
    return
        deploy:copy-templates($target, $templateColl, $userData, $permissions)
};


declare function deploy:shared-modules($includeTmpl, $target) {
    if ($includeTmpl) then
        let $templatesFile := repo:get-resource("http://exist-db.org/apps/shared", "content/templates.xql")
        let $templates := util:binary-to-string($templatesFile)
        return
                xmldb:store($target || "/modules", "templates.xql", $templates, "application/xquery")
    else
        ()
};








declare function deploy:package($collection as xs:string, $expathConf as element()) {
    let $name := concat($expathConf/@abbrev, "-", $expathConf/@version, ".xar")
    let $xar := compression:zip(xs:anyURI($collection), true(), $collection)
    let $mkcol := deploy:mkcol("/db/system/repo", (), ())
    return
        xmldb:store("/db/system/repo", $name, $xar, "application/zip")
};

declare function deploy:download($app-collection as xs:string, $expathConf as element(), $expand-xincludes as xs:boolean) {
    let $name := concat($expathConf/@abbrev, "-", $expathConf/@version, ".xar")
    let $entries :=
        dbutil:scan(xs:anyURI($app-collection), function($collection as xs:anyURI?, $resource as xs:anyURI?) {
            let $resource-relative-path := substring-after($resource, $app-collection || "/")
            let $collection-relative-path := substring-after($collection, $app-collection || "/")
            return
                if (empty($resource)) then
                    (: no need to create a collection entry for the app's root directory :)
                    if ($collection-relative-path eq "") then
                        ()
                    else
                        <entry type="collection" name="{$collection-relative-path}"/>
                else if (util:binary-doc-available($resource)) then
                    <entry type="uri" name="{$resource-relative-path}">{$resource}</entry>
                else
                    <entry type="xml" name="{$resource-relative-path}">{
                        util:declare-option("exist:serialize", "expand-xincludes=" || (if ($expand-xincludes) then "yes" else "no")),
                        doc($resource)
                    }</entry>
        })
    let $xar := compression:zip($entries, true())
    return (
        response:set-header("Content-Disposition", concat("attachment; filename=", $name)),
        response:stream-binary($xar, "application/zip", $name)
    )
};

declare function deploy:deploy($collection as xs:string, $expathConf as element()) {
    let $pkg := deploy:package($collection, $expathConf)
    let $null := (
        repo:remove($expathConf/@name),
        repo:install-and-deploy-from-db($pkg)
    )
    return
        ()
};

declare function deploy:downloadPackage($collectionUri as xs:string) {


let $expathConf := xmldb:xcollection($collectionUri)/expath:package

return
try {
            deploy:download($collectionUri, $expathConf, true())
}
         catch exerr:EXXQDY0003 {
        response:set-status-code(403),
        <span>You don't have permissions to access or write the application archive.
            Please correct the location or log in as a different user.</span>
    } catch exerr:EXREPOINSTALL001 {
        response:set-status-code(404),
        <p>Failed to install application.</p>
    } catch * {
        response:set-status-code(501)
    }
};

(: :::::::::::::::::::
 : End of material extensively copied from eXide's deployment.xql library
 : 
 :  :)

declare function local:get-datatype($filename as xs:string) as xs:string {
    let $extension := functx:substring-after-last($filename,'.')
    return 
        if ($extension = 'svg') then 
            'image/svg+xml'
        else if ($extension = 'xql') then
            'application/xml'
        else if (($extension = 'xml') || ($extension = 'html') || ($extension = 'xconf')) then
            'text/xml'

        else
            'text'
};


declare function local:make-sources( $path as xs:string, $format as xs:string)  as item()* {
    if ($path = '') then
       error(QName('http://heml.mta.ca/Lace2/Error/','HugeZipFile'),'Inappropriate number of subdocuments in path"' || $path || '"')
    else 
        for $page in collection($path)
            return
                if ($format = "xar") then
                    <entry name="{util:document-name($page)}" type='{local:get-datatype(util:document-name($page))}' method='deflate'>
                        {$page}
                    </entry>
                else if ($format = "text") then
                    <entry name="{fn:tokenize(util:document-name($page), '\.')[1] || '.txt'}" type='text' method='store'>
                        {transform:transform($page, doc("resources/xslt/hocr_to_plain_text.xsl"), <parameters/>)}
                    </entry>
                else
                    <wha/>
} ;

declare function local:collection-local-name($path as xs:string) as xs:string {
    let $a := tokenize(util:collection-name($path||'/f'),'/')
    return 
        $a[count($a)]
};

let $collectionUri := xs:string(request:get-parameter('collectionUri', ''))
let $format := xs:string(request:get-parameter('format','xar'))
let $collectionSuffix := 
    if ($format = "xar") then
            "xar"
        else
            "zip"

return
    if ($collectionSuffix = "zip") then
        let $collectionName := local:collection-local-name($collectionUri) || "." || $collectionSuffix
        let $col :=  local:make-sources($collectionUri, $format)
        return
            response:stream-binary(
                xs:base64Binary(compression:zip($col, true()) ),
                'application/zip',$collectionName)
    else
        deploy:downloadPackage($collectionUri)
