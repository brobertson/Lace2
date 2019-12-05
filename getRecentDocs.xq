xquery version "3.1";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace local="http://heml.mta.ca/lace/ns";
declare variable $since := xs:dateTime("2019-06-01T00:00:00");
declare function local:getDocsAfter($col as xs:string, $since as xs:dateTime) as xs:string*
{
	for $c in xmldb:find-last-modified-since(collection($col), $since)
	let $last-modified := xmldb:last-modified(util:collection-name($c), util:document-name($c))
	order by $last-modified
		return concat($last-modified, ":", util:collection-name($c),'/', util:document-name($c))
};
let $coll := "/db/Lace2Data/texts/"
return local:getDocsAfter($coll, $since)