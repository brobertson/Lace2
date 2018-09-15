$(document).ready(function() {
    /* 
     * Open link or code snippet in eXide. Check if eXide is already open.
     * Include this script if you use templates:load-source.
     */
    $(".eXide-open").click(function(ev) {
        // try to retrieve existing eXide window
        var exide = window.open("", "eXide");
        if (exide && !exide.closed) {
            var snip = $(this).data("exide-create");
            var path = $(this).data("exide-open");
            
            // check if eXide is really available or it's an empty page
            var app = exide.eXide;
            if (app) {
                // eXide is there
                if (snip) {
                    exide.eXide.app.newDocument(snip, "xquery");
                } else {
                    exide.eXide.app.findDocument(path);
                }
                exide.focus();
                setTimeout(function() {
                    if ($.browser.msie ||
                        (typeof exide.eXide.app.hasFocus == "function" && !exide.eXide.app.hasFocus())) {
                        alert("Opened code in existing eXide window.");
                    }
                }, 200);
            } else {
                window.eXide_onload = function() {
                    console.log("onloaed called");
                    if (snip) {
                        exide.eXide.app.newDocument(snip, "xquery");
                    } else {
                        exide.eXide.app.findDocument(path);
                    }
                };
                // empty page
                exide.location = this.href.substring(0, this.href.indexOf('?'));
            }
            return false;
        }
        return true;
    });
});