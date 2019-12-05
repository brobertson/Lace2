xquery version "3.1";
import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace html="http://www.w3.org/1999/xhtml";
let $dbroot := "/db/Lace2Data/texts/"
let $doc-with-indexes := "/db/Lace2Data/texts/122319309brucerob/2016-06-07-20-53_loeb_2016-03-20-14-17-00128200.pyrnn.gz_selected_hocr_output/122319309brucerob0_0052.html"
let $doc-with-indexes := "/db/Lace2Data/texts"
let $search-expression :="ἔλκ*"
(: 
let $score := "0.7"

    for $hit in collection($doc-with-indexes)//html:span[text()=$search-expression]
:)
    (::)
    for $hit in collection($doc-with-indexes)//html:span[ ft:query(.,$search-expression)]
    (:
    let $score as xs:float := ft:score($hit)
    order by $score descending
    :)
    (::)
    return (
        $hit
        (:<p>Score: {$score}:</p>:)
)