xquery version "3.1";
module namespace ctsurns="http://heml.mta.ca/Lace2/ctsurns";
import module namespace functx="http://www.functx.com";

declare function ctsurns:ctsUrnReference($urn as xs:string*) {
    functx:substring-before-last($urn,':') || ":"
};

declare function ctsurns:ctsUrnReferencesSame($urn1 as xs:string, $urn2 as xs:string) as xs:boolean {
  (ctsurns:ctsUrnReference($urn1) = ctsurns:ctsUrnReference($urn2))  
};

declare function ctsurns:ctsUrnPassageCitation($urn as xs:string) {
    functx:substring-after-last($urn,':')
};

declare function ctsurns:ctsUrnPassageCitationParts($passageCitation) {
    fn:tokenize(ctsurns:ctsUrnPassageCitation($passageCitation),'\.')
};

declare function ctsurns:ctsUrnPassageCitationDepth($urn as xs:string*) as xs:int {
        try {
            count(ctsurns:ctsUrnPassageCitationParts(ctsurns:ctsUrnPassageCitation($urn)))
        }
        catch * {
            -1
        }
    };

declare function ctsurns:getPickerNodesForCtsUrnReference($ordered_pickers as node()*, $ref as xs:string) as node()* {
    for $picker in $ordered_pickers
    where ctsurns:ctsUrnReference($picker/@data-ctsurn/string()) = $ref
    return $picker
};

declare function ctsurns:uniqueCtsUrnReferences($ordered_pickers as node()*) {
        let $runRefsOnly :=
            for $picker in $ordered_pickers
            return
                ctsurns:ctsUrnReference($picker//@data-ctsurn/string())
        return fn:distinct-values($runRefsOnly)
};