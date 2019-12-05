xquery version "3.1";

declare namespace local="http://hcmc.uvic.ca/ns";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace request="http://exist-db.org/xquery/request";


declare variable $inCol := request:get-parameter("col", "/db");
declare variable $startCol := if (starts-with($inCol, "/")) then $inCol else concat("/", $inCol);


declare function local:getLatest($col as xs:string) as xs:dateTime*
{
	let $dates :=local:getDocDates($col)
	return max($dates)
};

declare function local:getDocDates($col as xs:string) as xs:dateTime*
{
	let $result :=
		(for $c in xmldb:get-child-collections($col) return local:getDocDates(concat($col, '/', $c)),
        for $r in xmldb:get-child-resources($col) return xmldb:last-modified($col, $r)
        )
	return $result
};

let $startCol := "/db/Lace2Data/texts/"
return 
local:getLatest($startCol)