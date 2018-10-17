xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;


if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
    
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
    
(: a nice try at making a more RESTful interface for editing. 
 : There's a problem, though, if this is done with a 'forward', then no further
 : processing occcurs, meaning that we have to manually, below, list the pipeline
 : for html processing. Restxq is another option, though I haven't got that working,
 : either.
else if (contains($exist:path, "editme")) then
    let $params := tokenize($exist:path,'/')
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/side_by_side_view.html">
            <add-parameter name="collectionUri" value="{concat('/db/Lace2Data/texts',$params[3])}"/>
            <add-parameter name="positionInCollection" value="{$params[4]}"/>
        </forward>
    </dispatch>
    :)
    
(:  The 'static' path goes back to Lace1 days, and is often used by harvesters. Here, we pass
 : them the edited version of the text 
 : 
 : TODO: import the $textDataPath variable, don't hard-code it here.:)
else if (contains($exist:path, 'static/Texts')) then
    let $remaining := substring($exist:path,20)
    let $route := concat ("/exist/rest/db/Lace2Data/texts/",$remaining)
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$route}"/>
        </dispatch>
     
(:  This is hard-coded to go to our server, which is nuts.
 : However, $exist:controller goes to localhost:8080, which is not OK :)
else if (contains($exist:path, 'runs/')) then
    let $thisId := tokenize($exist:path,'/')[3]
    let $route := "http://heml.mta.ca/lace" || "/runs.html?archive_number=" || $thisId
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{$route}"/>
        </dispatch>

else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
