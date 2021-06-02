xquery version "3.1";
module namespace urnlibrary="http://heml.mta.ca/Lace2/urnlibrary";
declare namespace file="http://exist-db.org/xquery/file";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";


declare function urnlibrary:xmlTable() {
    
    let $urnLibrary := doc("/apps/lace/resources/xml/urns.xml")/ctsTags
        for $tag in $urnLibrary/*
        order by $tag/@label
        return
            <html:tr>
                <html:td>{data($tag/@label)}</html:td>
                <html:td>{data($tag/@urn)}</html:td>
                <html:td><html:a href="?action=delete&amp;urn={data($tag/@urn)}">x</html:a></html:td>
            </html:tr>
            
    
};

declare function urnlibrary:delete($urn as xs:string) {
    update delete doc("/apps/lace/resources/xml/urns.xml")/ctsTags/*[@urn = $urn]
};

declare function urnlibrary:update($urn as xs:string, $label as xs:string) {
    update insert <tag label="{$label}" urn="{$urn}"/> into doc("/apps/lace/resources/xml/urns.xml")/ctsTags
};

declare function urnlibrary:page($node as node(), $model as map(*), $action as xs:string*, $urn as xs:string*, $label as xs:string*) {

let $update := 
if ($action eq 'update') then
    <html:div class="row">
      update: {$urn} {$label} {urnlibrary:update($urn,$label)}
    </html:div>
else
    if ($action eq 'delete')
    then
        <html:div class="row">
        delete: {$urn} {urnlibrary:delete($urn)}
    </html:div>
else
    ()
    
return
    <html:div class="row">
    <html:form action="">
            {$update}
            <html:div class="row ">
            <html:div class="col-md-5 input-group">
                <span class="input-group-addon" id="basic-addon1">Label and URN Pair</span>
                <html:input type="text" class="form-control" name="label" placeholder="label" aria-describedby="sizing-addon1"/>
                    <html:input type="text" class="form-control" name="urn" placeholder="URN" aria-describedby="sizing-addon1"/>
                    </html:div>
                </html:div>
            <html:div class="row">
            <input type="hidden" name="action" value="update" />
            <html:input type="submit" value="Add pair"/>
            </html:div>
            </html:form>    
        <html:table>
    <html:thead>
        <html:tr>
      <html:th scope="Label">Label</html:th>
      <html:th scope="URN">URN</html:th>
      <html:th scope="delete">Delete</html:th>
    </html:tr>
  </html:thead>
  <html:tbody>
   { urnlibrary:xmlTable() }
    </html:tbody>
    </html:table>
    </html:div>

};