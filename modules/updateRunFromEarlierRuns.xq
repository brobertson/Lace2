xquery version "3.1";

declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace lace="http://heml.mta.ca/2019/lace";
import module namespace functx="http://www.functx.com";
import module namespace app="http://heml.mta.ca/Lace2/templates" at "app.xql";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare option exist:serialize "method=text media-type=text/csv omit-xml-declaration=yes";
declare variable $svgDirName := "SVG";
declare variable $miniumHocrCompletion := xs:float(0.8);

declare function local:copy_svgs($fromCollection, $toCollection, $clobber) {
    (: TODO finish noclobber :)
            (:  If someone logs in as admin and then edits, they end up doing all
     : the work in this script as 'admin', and the permissions for the files and
     : collection are set to that level. So we are logging in here as 'guest'
     : to avoid this problem. This is not terribly elegant, and a more sensible
     : login system should be implemented eventually.
     : This also assumes that nobody has assigned a different password to 'guest'.
     :  :)
    let $try := xmldb:login('/db', 'guest', 'guest', true()) 
    let $sourceSvgCollectionPath := $fromCollection || "/" || $svgDirName
    let $destinationSvgCollectionPath := $toCollection || "/" || $svgDirName
    return
    if (xmldb:collection-available($sourceSvgCollectionPath)) then
        for $svg_file in xmldb:get-child-resources($sourceSvgCollectionPath)
            let $unused1 := 
                if (not(xmldb:collection-available($destinationSvgCollectionPath))) then
                    xmldb:create-collection($toCollection, $svgDirName)
                else
                    ()
                    return <html:li>xmldb:copy-resource($sourceSvgCollectionPath , $svg_file, $destinationSvgCollectionPath, $svg_file)</html:li>
    else
        (: the source SVG directory doesn't exist yet :)
        ()
};

declare function local:is_completed_hocr($hocr_in as node()) as xs:boolean {
    app:hocrPageCompletionFloat($hocr_in) > $miniumHocrCompletion
};
    
declare function local:copy_complete_hocrs($fromCollection as xs:string, $toCollection as xs:string, $clobber as xs:boolean) as xs:string* {
    (: TODO: finish no clobber :)
    for $possible_hocr_file in xmldb:get-child-resources($fromCollection)
        let $inPath := $fromCollection || '/' || $possible_hocr_file 
        return
        try {
            (: if there is an illegal xml charcater in the xhtml, then 'doc' will throw an exception :)
            if ((fn:ends-with($possible_hocr_file, '.html') and  (local:is_completed_hocr(doc($inPath))))) then
            <html:li>xmldb:copy-resource($fromCollection, $possible_hocr_file, $toCollection, $possible_hocr_file)</html:li> 
            else
                ()
        }
        catch * {
            ()
        }



};

declare function local:get_sibling_runs($archive_number as xs:string, $myUri as xs:string) as xs:string+{
    for $run in collection('/db/apps')//lace:run[dc:identifier/text() = $archive_number]
        let  $possible_sibling := app:hocrCollectionUriForRunMetadataFile($run)
        order by $run/dc:date ascending
        (: don't include myself as a sibling :)
        where $possible_sibling != $myUri
        return
            $possible_sibling
};

let $collectionUri := xs:string(request:get-parameter('collectionUri', ''))
let $clobber := xs:boolean(request:get-parameter('clobber', 'false') = 'true')
let $collectionUri := "/db/apps/actaphilippietac00bonnuoft_2020-01-16-00-08-53"
let $collectionName := collection($collectionUri)//dc:identifier

for $runPath in local:get_sibling_runs($collectionName, $collectionUri)
    return <html:ul>(local:copy_complete_hocrs($runPath, $collectionUri, $clobber),local:copy_svgs($runPath,$collectionUri, $clobber))</html:ul>
