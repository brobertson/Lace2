 $(function() {
    $.contextMenu({
        selector: '.ocr_word',
        zIndex: 0,
        callback: function(key, options) {
            //var m = "clicked: " + key;
            //window.console && console.log(m) || alert(m);
            switch (key) {
                case 'word':
                    insert_word_inline($(this))
                    break;
                case 'add_line_below':
                    below = true
                    insert_line($(this), below)
                    break;
                case 'add_line_above':
                    below = false
                    insert_line($(this), below)
                    break;
                case 'verify_line':
                    verify_this_line($(this))
                    break;
                case 'verify_page':
                    verify_whole_page($(this))
                    break;
                case 'cts-urn':
                    make_cts_urn_picker($(this))
                    break;
                case 'following':
                    validate_following($(this))
                    break;
                case 'all':
                    validate_all_similar($(this))
                    break;
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
            "add_line_below": {name: "Add Line After", icon: "fa-beer"},
             "add_line_above": {name: "Add Line Before", icon: "fa-beer"},
            "word": {name: "Add Word After", icon: "fa-edit"},
            "verify_line": {name: "Verify Whole Line", icon: "fa-beer"},
            "verify_page": {name: "Verify Whole Page", icon: "fa-beer"}
            //"following": {name: "Verify Following", icon: "fa-cloud-download"}
            //"all": {name: "Verify All in Volume", icon: "fa-edit"}
        }
    });
    $.contextMenu({
        selector: '.inserted_line, .index_word',
        zIndex: 0,
        callback: function(key, options) {
            //var m = "clicked: " + key;
            //window.console && console.log(m) || alert(m);
            switch (key) {
                case 'cts-urn':
                    make_cts_urn_picker($(this))
                    break;
            }
        },
        items: {
            "cts-urn": {name: "Insert Ref. Before", icon: "fa-edit"}
           // "add_line": {name: "Add Line After", icon: "fa-beer"},
            //"word": {name: "Insert Word After", icon: "fa-edit"},
            //"following": {name: "Verify Following", icon: "fa-cloud-download"}
            //"all": {name: "Verify All in Volume", icon: "fa-edit"}
        }
    });
});