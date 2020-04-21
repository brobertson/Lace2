xquery version "3.1";

module namespace laceupdate="http://heml.mta.ca/Lace2/update";
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace lace="http://heml.mta.ca/2019/lace";
import module namespace functx="http://www.functx.com";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "app.xql";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare variable $laceupdate:svgDirName := "SVG";
declare variable $laceupdate:miniumHocrCompletion := xs:float(0.1);

declare function laceupdate:convertToDateTime($in as xs:string) as xs:dateTime {
let $t := tokenize($in,'-')
return xs:dateTime(concat(string-join(subsequence($t,1,3),'-'), 'T', string-join(subsequence($t,4,6),':')))
};

declare function laceupdate:collectionDateTime($collection as xs:string) as xs:dateTime{
    laceupdate:convertToDateTime(collection($collection)//dc:date)
};

declare function laceupdate:copy_svgs($fromCollection, $toCollection, $clobber as xs:boolean) as node()* {
    (: TODO finish noclobber :)
            (:  If someone logs in as admin and then edits, they end up doing all
     : the work in this script as 'admin', and the permissions for the files and
     : collection are set to that level. So we are logging in here as 'guest'
     : to avoid this problem. This is not terribly elegant, and a more sensible
     : login system should be implemented eventually.
     : This also assumes that nobody has assigned a different password to 'guest'.
     :  :)
    let $try := xmldb:login('/db', 'guest', 'guest', true()) 
    let $sourceSvgCollectionPath := $fromCollection || "/" || $laceupdate:svgDirName
    let $destinationSvgCollectionPath := $toCollection || "/" || $laceupdate:svgDirName
    return
    if (xmldb:collection-available($sourceSvgCollectionPath)) then
        for $svg_file in xmldb:get-child-resources($sourceSvgCollectionPath)
        (: only overwrite svg files in destination directory if 'clobber is set to true() :)
        where ($clobber = true()) or (not(doc-available($destinationSvgCollectionPath || $svg_file)))
        order by $svg_file
            let $unused1 := 
                if (not(xmldb:collection-available($destinationSvgCollectionPath))) then
                    xmldb:create-collection($toCollection, $laceupdate:svgDirName)
                else
                    ()
                    return <html:li>{xmldb:copy-resource($sourceSvgCollectionPath , $svg_file, $destinationSvgCollectionPath, $svg_file)}</html:li>
    else
        (: the source SVG directory doesn't exist yet :)
        ()
};

declare function laceupdate:is_completed_hocr($hocr_in as node()) as xs:boolean {
    app:hocrPageCompletionFloat($hocr_in) > $laceupdate:miniumHocrCompletion
};
    
declare function laceupdate:copy_complete_hocrs($fromCollection as xs:string, $toCollection as xs:string, $clobber as xs:boolean) as node()* {
    (: TODO: finish no clobber  :)
    for $possible_hocr_file in xmldb:get-child-resources($fromCollection)
        let $inPath := $fromCollection || '/' || $possible_hocr_file 
        let $destinationPath := $toCollection || '/' || $possible_hocr_file 
        order by $possible_hocr_file
        return
        try {
            (: if there is an illegal xml charcater in the xhtml, then 'doc' will throw an exception :)
            if ( (fn:ends-with($possible_hocr_file, '.html')) and  (laceupdate:is_completed_hocr(doc($inPath))) and ($clobber or not(laceupdate:is_completed_hocr(doc($destinationPath))) ) ) then
            <html:li>{xmldb:copy-resource($fromCollection, $possible_hocr_file, $toCollection, $possible_hocr_file)}</html:li> 
            else
                ()
        }
        catch * {
            <html:li>Couldn't copy {$possible_hocr_file} due to error</html:li>
        }



};

declare function laceupdate:get_sibling_runs($archive_number as xs:string, $myUri as xs:string, $myDate as xs:string) as xs:string+{
    (: TODO implement date limitation :)
    for $run in collection('/db/apps')//lace:run[dc:identifier/text() = $archive_number]
        let  $possible_sibling := app:hocrCollectionUriForRunMetadataFile($run)
        order by $run/dc:date ascending
        (: don't include myself as a sibling :)
        where ($possible_sibling != $myUri) and true()
        return
            $possible_sibling
};

declare function laceupdate:update($node as node(), $model as map(*),  $collectionUri as xs:string, $clobber as xs:string?, $importFromYoungerRuns as xs:string?) {
    let $clobber_boolean := xs:boolean($clobber = 'true')
    let $importFromYoungerRuns_boolean := xs:boolean($importFromYoungerRuns = 'true')
    let $collectionName := collection($collectionUri)//dc:identifier
    let $collectionDate := collection($collectionUri)//dc:date
    for $runPath in laceupdate:get_sibling_runs($collectionName, $collectionUri, $collectionDate)
    where (($importFromYoungerRuns_boolean = true()) or (laceupdate:collectionDateTime($runPath) < laceupdate:collectionDateTime($collectionUri)))
        return <html:ul>{(laceupdate:copy_complete_hocrs($runPath, $collectionUri, $clobber_boolean),laceupdate:copy_svgs($runPath,$collectionUri, $clobber_boolean))}</html:ul>
};

declare function laceupdate:formatTitle($node as node(), $model as map(*),  $collectionUri as xs:string)  {
    (app:formatCatalogEntryForCollectionUri(app:imageCollectionFromCollectionUri($collectionUri)),
    ' ',
    <html:a href="{concat("side_by_side_view.html?collectionUri=",$collectionUri,"&amp;positionInCollection=2")}">{collection($collectionUri)//dc:date}</html:a>)
};
