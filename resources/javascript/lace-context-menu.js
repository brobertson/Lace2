 $(function() {
    $.contextMenu({
        selector: '.ocr_word',
        zIndex: 0,
        callback: function(key, options) {
            //var m = "clicked: " + key;
            //window.console && console.log(m) || alert(m);
            if (key === 'word') {
                 insert_word_inline($(this))
            }
            else if (key === 'line') {
                insert_line_below($(this))
            }
            else if (key === "cts-urn") {
                make_cts_urn_picker($(this))
            }
        },
        /** somehow, we're not doing this right 
        determinePosition: function($this){
        // Position using jQuery.ui.position 
        // http://api.jqueryui.com/position/
        $this.css('display', 'block')
            .position({ my: "left bottom", at: "right top", of: this, offset: "0 5"})
            .css('display', 'none');
    },
        
        **/
        items: {
            "cts-urn": {name: "Insert Ref. Before", icon: "fa-edit"},
            "line": {name: "Add Line After", icon: "fa-beer"},
            "word": {name: "Insert Word After", icon: "fa-edit"},
            copy: {name: "Cloud download", icon: "fa-cloud-download"}
        }
    });

});