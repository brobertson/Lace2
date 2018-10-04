xquery version "3.1";

import module namespace test="http://exist-db.org/xquery/xqsuite" 
at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
test:suite(
    inspect:module-functions(xs:anyURI("app.xql"))
)
