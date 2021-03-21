xquery version "3.1";
declare namespace xh="http://www.w3.org/1999/xhtml";
declare namespace expath = "http://expath.org/ns/pkg";

declare function local:repo-counts() {
    let $repos := repo:list()
    let $nl := "&#10;"
    let $text-repos :=
        for $repo in $repos
        order by $repo
        where fn:starts-with($repo, 'http://heml.mta.ca/Lace/Texts/') 
        return util:collection-name(collection(repo:get-root())//expath:package[@name = $repo])
    for $text-repo in $text-repos
    return
        $text-repo ||',' || current-date() || ',' || current-time() ||',' || count(collection($text-repo)//xh:span[@data-manually-confirmed="true"]) || ',' || count(collection($text-repo)//xh:span[@data-manually-confirmed="false"]) || $nl
};

local:repo-counts()
 
  

