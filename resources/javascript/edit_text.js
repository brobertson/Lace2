
/**
* initialize bloodhound
**/

var text_suggestions = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('label'),
    queryTokenizer: Bloodhound.tokenizers.whitespace, // see its meaning above
    prefetch: {
        url:'urns_to_json.xq',
        cache: false
    }
});


function error_message(message) {
     $("#error_message").text(message)
     $("#myModal").modal()
}

function get_filename() {
    var path_array = window.location.pathname.split("/")
    return path_array[path_array.length - 1]
}

function get_bbox_array(bbox_string) {
    bbox = bbox_string.split(';')[0];
    //console.log("this is bbox: " + bbox)
    return bbox.split(' ').map(Number).slice(1);
}

function get_bbox_array_of_element(jquery_element) {
    ot_attr = jquery_element.attr("original-title");
    //console.log("the ot_attr is: " + ot_attr)
    if (typeof ot_attr !== typeof undefined && ot_attr !== false && ot_attr.indexOf('bbox') !== -1) {
       // console.log("returing ot_attr")
        return get_bbox_array(ot_attr);
    }
    else {
        console.log("returing title attr for bbox: " + jquery_element.attr("title"))
        return get_bbox_array(jquery_element.attr("title"));
    }
}

function narrow_bbox_below_string(jquery_element, amount) {
    bbox_array=get_bbox_array_of_element(jquery_element)
    console.log("original array: " + bbox_array)
    y1 =  bbox_array[1]+amount
    y2 = y1 + 2
    return "bbox " + bbox_array[0] + " " + y1  + " " +  bbox_array[2] + " " + y2;
}

function narrow_bbox_above_string(jquery_element, amount) {
    bbox_array=get_bbox_array_of_element(jquery_element)
    y1 =  Math.max(bbox_array[1]-amount,0)
    y2 = y1 + 2
    return "bbox " + bbox_array[0] + " " + y1  + " " +  bbox_array[2] + " " + y2;
}

function tall_bbox_beside_string(jquery_element, amount) {
    bbox_array=get_bbox_array_of_element(jquery_element)
    x1 = bbox_array[2] + amount
    x2 = x1 + 2
    return "bbox " + x1 + " " + bbox_array[1] + " " + x2 + " " + bbox_array[3]
}


$.urlParam = function(name) {
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    if (results === null) {
        return null;
    }
    return decodeURI(results[1]) || 0;
};

function pause_editing() {
     $("#right_side").addClass("inactive")
     $("#ocr_page").attr("contentEditable", "false")
}

function resume_editing() {
     $("#right_side").removeClass("inactive")
     $("#ocr_page").attr("contentEditable", "true")
}

function update_progress_bar() {
    var confirmed = $("span[data-manually-confirmed='true']").length;
    $('.ocr_page').attr('data-confirmed-word-count', confirmed)
    var all_words = $("span[class='ocr_word']").length
    //console.log("all words" + all_words)
    //$('.ocr_page').attr('data-word-count', all_words)
    var empty_words = $("span[class='ocr_word']:empty").length
    $('.ocr_page').attr('data-empty-word-count', empty_words)
    //console.log("we have " + all_words + " words.")
    //console.log(confirmed + " are corrected")
    //console.log(empty_words + " are empty")
    editing_progress = confirmed / all_words
    var progress_percent = Math.round(editing_progress * 100.0)
    //console.log(progress_percent)
    $('#progress_bar').css('width', progress_percent + "%");
    $('#progress_bar').text(progress_percent + "%");
    if (confirmed >= (all_words - empty_words)) {
        $('.ocr_page').addClass("complete_text");
    }
}

function updateCTSURN(urnpicker_id, my_action) {
    console.log("updating CTSUrn")
    var data = {};
    picker_span_string = "#" + urnpicker_id + "_span"
    doc = $('.ocr_page').attr('title')
    data['doc'] = doc
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0, n);
    data['filePath'] = filePath
    picker_span = $(picker_span_string)
    composed_urn = $("#" + urnpicker_id).attr("data-ctsurn") + $("#" + urnpicker_id + "_additional").val()
    console.log("my action is " + my_action)
    if (my_action === "add") {
        Cookies.set('ctsurn', $("#" + urnpicker_id).attr("data-ctsurn"), { expires: 7 });
        Cookies.set('author-name', $("#" + urnpicker_id).attr("data-author-name"), { expires: 7 });
    }
    data['name'] = $("#" + urnpicker_id).attr("data-author-name") + " " + $("#" + urnpicker_id + "_additional").val()
    data['id'] = urnpicker_id + "_span"
    //this is unnecessary
    data['label'] = picker_span_string
    data['next_sibling_id'] = picker_span.next().attr('id')
    data['starting-span'] = picker_span.attr("data-starting-span")
    data['value'] = composed_urn
    data['action'] = my_action
  
    $.ajax({
        url: 'modules/updateCTSUrn.xq',
        method: "POST",
        dataType: "xml",
        data: data,
      beforeSend: function( xhr ) {
        console.log("sending" + xhr)
      }
    })
    .done(function( data ) {
        if ( console && console.log ) {
          console.log("success " + my_action + " CTS URN: " + composed_urn + " on " + picker_span_string + " at " + filePath + "/" + fileName + " before " + data['next_sibling_id']) 
        }
    })
    .fail(function() {
        console.log("failure updating CTS URN")
        //delete the element?
    });
}


/***
 * Old way of updating a word, which does one at a time. 
 * This will be replaced with 'update_xmldbs' in all cases if the latter works
 * out.
 ****/
function update_xmldb(element) {
    var data = {};
    data['value'] = $(element).text();
    data['id'] = $(element).attr('id');
    doc = $('.ocr_page').attr('title')
    data['doc'] = doc
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0, n);
    data['filePath'] = filePath
    whole_address = 'modules/updateWord.xq';
    //console.log("posting ", data, " to ", whole_address)
    old_attribute = element.getAttribute("data-manually-confirmed")
    element.setAttribute("data-manually-confirmed", "true");

    $.ajax({
        url: whole_address,
        method: "POST",
        dataType: "xml",
        data: data,
      beforeSend: function( xhr ) {
        console.log("sending" + xhr)
        pause_editing()
      }
    })
    .done(function( data ) {
        if ( console && console.log ) {
          //console.dirxml(data);
        }
        resume_editing()
    })
    .fail(function() {
        //make_page-not_gray()
        element.setAttribute("data-manually-confirmed", old_attribute);
        alert("The connection has been lost to the lace server.")
        resume_editing()
    
  });
}

function test_text(textIn) {
    if (textIn.length > 200) {
        return true
    }
    return true
}


/*****
 * Experimental multi-element update
 * ****/
 
function update_xmldbs(elementsIn, validateOnly) {
    var elements = {};
    for (i = 0; i < elementsIn.length; i++) {
        element = elementsIn[i]
        element.setAttribute("data-manually-confirmed", "true");
        elements[$(element).attr('id')] = $(element).text();
    }
    var data = {};
    data['elements'] = JSON.stringify(elements)
    data['validateOnly'] = validateOnly
    doc = $('.ocr_page').attr('title')
    data['doc'] = doc
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0, n);
    data['filePath'] = filePath
    whole_address = 'modules/updateWords.xq';
    //console.log("posting ", data, " to ", whole_address)
    //old_attribute = element.getAttribute("data-manually-confirmed")
    $.ajax({
        url: whole_address,
        method: "POST",
        dataType: "xml",
        data: data,
      beforeSend: function( xhr ) {
        //console.log("sending" + xhr)
        pause_editing()
      }
    })
    .done(function( data ) {
        if ( console && console.log ) {
          //console.dirxml(data);
        }
        find_next_focus(element)
        resume_editing()
    })
    .fail(function() {
        //make_page-not_gray()
        element.setAttribute("data-manually-confirmed", old_attribute);
        alert("The connection has been lost to the lace server.")
        resume_editing()
    
  });
}

/**
 * Functions implemented with context menu.
 **/

/**
 * This is not yet implemented in the context menu. I'm not sure it
 * is that useful, honestly.
 **/
function validate_all_similar(element) {
    update_all_xmldb(element);
    old_form = $(element).attr('data-selected-form')
    new_form = $(element).text()
    $(".ocr_word[data-selected-form='" + old_form.replace(/'/g, "\\'") + "']").each(function() {
        $(this).text(new_form);
        $(this).attr("data-manually-confirmed", "true");
    });
}

/**
 * Called by the function above
 **/
function update_all_xmldb(element) {
    var data = {};
    doc = $('.ocr_page').attr('title')
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0, n);
    data['filePath'] = filePath
    data['correctedForm'] = $(element).text();
    data['query'] = $(element).attr('data-selected-form');
    data['id'] = $element.attr('id');
    console.log("updated " + data['query'] + " with " + data['correctedForm'] + " in all of " + data['filePath']);
 
    $.ajax({
    url: 'modules/updateMany.xq',
    method: "POST",
    dataType: "xml",
    data: data,
    beforeSend: function( xhr ) {
        console.log("sending" + xhr)
      }
    })
    .done(function( data_back ) {
        set_of_blinkers = $(".ocr_word").filter(function() {
            return ($(this).text() === data['query'])
            })
        //console.log("blinker count " + set_of_blinkers.length)
        set_of_blinkers.addClass("blinker");
    })
    .fail(function() {
        console.log("failure updating many")
        alert("Failure to update. Disconnected from Lace Server?")
    });
}

function verify_this_line(element) {
    siblings_and_self = $(element).parent().children()
    validateOnly = "true"
    update_xmldbs(siblings_and_self, validateOnly)
    update_progress_bar();
}

function verify_whole_page_actual() {
    validateOnly = "true"
    update_xmldbs($("span[class='ocr_word']"), validateOnly)
    update_progress_bar();
}

/***
 * this shows the modal dialog that is stored in page.html 
 * If its 'OK' button is pressed, then the function above
 * 'verify_whole_page_actual' is run
 ***/
function verify_whole_page(element) {
    $('#verifyPageModal').modal('show');
}

function add_line_xmldb(element, uniq, below) {
    console.log("calling addlinebelow")
    var data = {};
    data['value'] = $(element).text();
    data['original-title'] = $(element).attr('original-title')
    data['title'] = $(element).attr('original-title')
    data['id'] = $(element).attr('id');
    console.log("the id is: " + data['id'])
    data['uniq'] = uniq;
    doc = $('.ocr_page').attr('title');
    data['doc'] = doc;
    data['below'] = below;
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0, n);
    data['filePath'] = filePath;
    $.ajax({
    url: 'modules/addLineBelow.xq',
    method: "POST",
    dataType: "xml",
    data: data,
    beforeSend: function( xhr ) {
        console.log("sending" + xhr)
      }
    })
    .done(function( data_out ) {
        if ( console && console.log ) {
          console.log("success adding line below")
          console.dirxml(data_out);
        }
    })
    .fail(function() {
        console.log("failure adding line below")
        alert("Disconnected from Lace Server")
    });
}


/*called when the 'x' button beside the added element is pressed*/
function delete_added_element(buttonElement) {
    console.log("calling line delete");
    var data = {};
    doc = $('.ocr_page').attr('title');
    data['doc'] = doc;
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0, n);
    data['filePath'] = filePath
    the_actual_span = buttonElement.id.substr(0, buttonElement.id.lastIndexOf('_'))
    enclosing_element = the_actual_span.concat('_holder');
    data['id'] = enclosing_element
    //this has been stored in the database, so we need to do a call to xquery to 
    //delete it from there, and only delete it from the DOM if that call is successful

    $.ajax({
        url: 'modules/deleteElement.xq',
        method: "POST",
        dataType: "xml",
        data: data,
      beforeSend: function( xhr ) {
        console.log("sending" + xhr)
      }
    })
    .done(function( data_out ) {
        if ( console && console.log ) {
          console.log("success deleting element " + data["id"]) 
        }
        $("#" + data['id']).remove();
    })
    .fail(function() {
        console.log("failure deleting element "+ data["id"])
        alert("Failure to connect to the Lace Server")
    });
}

function add_span_after(element, uniq, dimensions) {
    var data = {};
    //data['shift'] = e.shiftKey
    data['value'] = $(element).text();
    data['id'] = $(element).attr("id");
    data['uniq'] = uniq;
    doc = $('.ocr_page').attr('title')
    data['original-title'] = dimensions
    console.log("posting dimensions: " + dimensions)
    data['title'] = dimensions
    data['doc'] = doc
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0, n);
    data['filePath'] = filePath
    $.ajax({
    url: 'modules/addIndexWordAfter.xq',
    method: "POST",
    dataType: "xml",
    data: data,
    beforeSend: function( xhr ) {
        console.log("sending" + xhr)
      }
    })
    .done(function( data ) {
        if ( console && console.log ) {
          
        }
    })
    .fail(function() {
        console.log("failure adding word after")
        alert("Disconnected from Lace Server")
    });
}

function generate_image_tag_call(collectionUri, page_file, bbox, width, height) {
    scale = 0.5
    width = width * scale
    height = height * scale
    var request = "<img width='" + width + "' height='" + height + "' src=\"" + "getCroppedImage.xq?collectionUri=" + encodeURIComponent(collectionUri) + "&amp;file=" + encodeURIComponent(page_file) + "&amp;bbox=" + encodeURIComponent(bbox) + "\" alt='a word image'/>"
    return request
}

function insert_word_inline(target_word) {
    console.log("inside insert")
    parent_line = target_word.parent('.ocr_line')
    var uniq = 'ins_word_' + (new Date()).getTime();
    var index_word = $("<span class='index_word_holder' id='" + uniq + "_holder'><span class='index_word' id='" + uniq + "' data-manually-confirmed='false' contenteditable='true'></span><button id='" + uniq + "_button' type='button' class='delete_element' aria-label='Close'><span aria-hidden='true'>&times;</span></button></span>")
    target_word.after(index_word)
    var pixel_shift_down = 0
    dimensions = narrow_bbox_below_string(parent_line, pixel_shift_down)
    $("#"+uniq).attr("original-title", dimensions)
    $("#"+uniq).attr("title", dimensions)
    add_span_after(target_word, uniq, dimensions);
    $('.ocr_page').on('keypress', '.index_word', function(e) {
        if (e.which == 13) {
            e.preventDefault();
            update_xmldb(this);
            }
    });
    $("#"+uniq).focus()
    return; //this is the trick to short-circuiting the function.
}

function insert_line(element, below) {
    parent_line = $(element).parent('.ocr_line')
    var uniq = 'ins_line_' + (new Date()).getTime();
    var newline = $("<div class='inserted_line_holder' id='" + uniq + "_holder'><span class='inserted_line' id='" + uniq + "' data-manually-confirmed='false' contenteditable='true'></span><button id='" + uniq + "_button' type='button' class='delete_element' aria-label='Close'><span aria-hidden='true'>&times;</span></button></div>")
    console.log("the newline is:" + newline)

    if (below) {
        parent_line.after(newline);
        new_bbox_string = narrow_bbox_below_string(parent_line, 4)
    }
    else {
        parent_line.before(newline);
        new_bbox_string = narrow_bbox_above_string(parent_line, 4);
    }
    $("#"+uniq).attr("original-title", new_bbox_string)
    $("#"+uniq).attr("title", new_bbox_string)
    add_line_xmldb(element, uniq, below);
    $('.ocr_page').on('keypress', '.inserted_line', function(e) {
        //console.log("we get an inserted line keypress")
        if (e.which == 13) {
            //console.log("it's a return")
            e.preventDefault();
            update_xmldb(this);
        }
    });
    $("#"+uniq).focus()
}

function make_cts_urn_picker(element) {
    
    /** 
     * See if we have cookies set to preset this data
     * 
     **/
    ctsurn_cookie = Cookies.get('ctsurn');
    authorname_cookie = Cookies.get('author-name')
    authorname_placeholder = ''
    if ((ctsurn_cookie == null) || (authorname_cookie == null)) {
        authorname_placeholder = 'author/title'
    }
    else
    {
        authorname_placeholder = authorname_cookie
    }
    var uniq_picker = 'ins_cts_picker_' + (new Date()).getTime();
    var cts_picker = $("<span class='cts_picker' id='" + uniq_picker + "_span'>📖<input class='ctsurn-picker' id='" + uniq_picker + "' type='text' placeholder='" + authorname_placeholder + "'/><input class='ctsurn-span' id='" + uniq_picker + "_additional'/><button class='kill_button' type='button' id='" + uniq_picker + "_kill_button'> <span>×</span> </button></span>");
    $(element).before(cts_picker);
    cts_picker.attr("data-starting-span", $(element).attr("id"))
    /**
     * Put a typeahead on the text field
    
    $("#" + uniq_picker).typeahead({
        default_val: "my default val",
        hint: true,
        highlight: true,
        source: function(query) {
            var self = this;
            self.map = {};
            var items = [];
            //ctsGreekTags is assigned in a separate file
            $.each(cts_tags, function(i, item) {
                self.map[item.label] = item;
                items.push(item.label)
            });
            return items;
        },
        //limit does not work, and we are hard-fixed to 8.
        //See this discussion: https://stackoverflow.com/questions/26111281/twitters-typeahead-limit-not-working
        //limit: 10,
        updater: function(item) {
            var selectedItem = this.map[item];
            this.$element.data('selected', selectedItem);
            console.log("updater function called on: " + selectedItem)
            console.log(this.$element)
            this.$element.attr("data-ctsurn", selectedItem["id"])
            this.$element.attr("data-author-name", selectedItem["label"])
            $("#" + uniq_picker + "_additional").focus()
            return item
        }
    });
    **/
    $("#" + uniq_picker).typeahead({
        hint: true,
        highlight: true,
        minLength: 1
    },
    {
        name: 'texts',
        source: text_suggestions,   // Bloodhound instance is passed as the source
        display: function(item) {        // display: 'name' will also work
        return item.label;
    },
    

    });

  



$("#" + uniq_picker).bind('typeahead:select', function(ev, item) {
            console.log("typeahead:select: ", item["id"])
            $(this).attr("data-ctsurn", item["id"])
            $(this).attr("data-author-name", item["label"])
            $("#" + uniq_picker + "_additional").focus()
});

    $("#" + uniq_picker + "_additional").on('keypress', function(event) {
        //console.log("we get an inserted line keypress")
        if (event.which == 13) {
            event.preventDefault(); // To prevent actually entering return
            console.log("return in picker_additional: " + uniq_picker)
            //add data and tooltip to span
            the_span = $("#" + uniq_picker + "_span")
            /***
             * in the case of a close-reference milestone, trying to use the closed-book emoji, but honestly, this
             * causes a bunch of side effects, so wait for another day.
            if ($("#"+uniq_picker).attr("data-ctsurn") === "__end__") {
               the_span.text("📕")
            } 
            ***/
            if ($("#"+uniq_picker).attr("data-ctsurn") == null)  {
               console.log("the picker was undefined! Setting it to " + ctsurn_cookie + " from cookie")
               $("#"+uniq_picker).attr("data-ctsurn", ctsurn_cookie)
               $("#"+uniq_picker).attr("data-author-name",authorname_cookie)
            }
            composed_urn = $("#"+uniq_picker).attr("data-ctsurn") + $("#" + uniq_picker + "_additional").val()
            readable_name = $("#" + uniq_picker).attr("data-author-name") + " " + $("#" + uniq_picker + "_additional").val() + " = " + composed_urn
            the_span.attr("data-ctsurn", composed_urn)
            the_span.attr("data-toggle", "tooltip")
            the_span.attr("data-placement", "top")
            the_span.attr("title", readable_name)
            //the_span.tooltip()
            console.log("here, uniq_picker is " + uniq_picker)
            updateCTSURN(uniq_picker, "add")
            //now delete all the inner inputs and this button
            $("#" + uniq_picker).typeahead('destroy');
            $("#" + uniq_picker).remove()
            $("#" + uniq_picker + "_additional").remove()
            $("#" + uniq_picker + "_ok_button").remove()
        }
    });
    $("#" + uniq_picker + "_kill_button").on('click', function(event) {
        //remove the entire picker span
        updateCTSURN(uniq_picker, "remove")
        $(this).parent().remove()
    });
    //set focus to picker citation box here
    $("#" + uniq_picker + "_additional").focus()
    return; //this is the trick to short-circuiting the function.
}

function find_next_focus(element) {
    var focusables = $(".ocr_word");
    var current = focusables.index(element);
    //var path_array = window.location.pathname.split("/")
    following_focusables = focusables.slice(current, focusables.length)
    preceding_focusables = focusables.slice(0, current)
    preceding_focusables_unedited = preceding_focusables.filter(function() {
        return $(this).attr('data-manually-confirmed') == 'false'
    })
    // console.log("following length: " + following_focusables.length)
    following_focusables_unedited = following_focusables.filter(function() {
        return $(this).attr('data-manually-confirmed') == 'false'
    })
    // console.log("ffuned: " + following_focusables_unedited.length)
    if (following_focusables_unedited.length > 0) {
        next = following_focusables_unedited[0]
    } else if (preceding_focusables_unedited.length > 0) {
        next = preceding_focusables_unedited[0]
    } else {
        next = focusables.eq(current + 1).length ? focusables.eq(current + 1) : focusables.eq(0);
    }
    next.focus()
}

/**
 * This confirms the given value for the OCR in all the words following the 'element' word
 * until it reaches either the end of the page or a word which does not ahve a 'True' spelcheck-mode.
 * It then finds the next word to focus on. It is called from the context menu.
 **/
function validate_following(element) {
    var words = $(".ocr_word");
    var current_word = words.index(element);
    console.log("there are ", words.length, " words")
    console.log("im at ", current_word)
    console.log("doing validate_following starting with ", element.attr('id'))
    following_words = words.slice(current_word, words.length)
    console.log("there are ", following_words.length, " following words")
    var i = 0;
    do {
        current = $(following_words[i])
        console.log("current spellcheck mode: ", current.attr('data-spellcheck-mode'))
        console.log("will I validate ", current.attr('id'), "?")
        //There's no point in doing it again if it's already entered.
        if ( current.attr('data-manually-confirmed') == 'false' ) {
            //requires a javascript, not jquery object: .get(0) will dereference it.
            update_xmldb(current.get(0));
            console.log("\tyes")
        }
        i++;
        //console.log("next spellcheck mode: ", $(following_words[i]).attr('data-spellcheck-mode'))
    }
    while ( (i < following_words.length) && ( $(following_words[i]).attr('data-spellcheck-mode').startsWith('True')) || $(following_words[i]).attr('data-manually-confirmed') == 'true');
    find_next_focus(following_words[i])
}

$(function() {
    /**
     * Do the following at startup.
     **/
     //testing an idea
     //$("#async").modal()
    //clear title attributes on @ocr_line spans
    $("#svg_focus_rect").attr('visibility', 'hidden');
    update_progress_bar();
    //Store the 'title' attribute value somewhere else, because
    //the tooltip requires this to store its value
    $('.ocr_word, .ocr_line').each(function() {
        var $e = $(this);
        if ($e.attr('title') || typeof($e.attr('original-title')) != 'string') {
            $e.attr('original-title', $e.attr('title') || '').removeAttr('title');
        }

    });
    
    $("#verifyPageOkButton").click(function (e) {
        verify_whole_page_actual();
    });

    /** 
     * Bind the following 'return' key presses.
     **/
    $('.index_word').bind('keypress', function(e) {
        if (e.which == 13) {
            e.preventDefault();
            update_xmldbs(this);
            }
    });
    $('.inserted_line').bind('keypress', function(e) {
        if (e.which == 13) {
            e.preventDefault();
            //console.log("trying to update xmldb")
            update_xmldb(this);
        }
    });
    $('.ocr_word').bind('keypress', function(e) {
        if (e.which == 13) {
            //console.log("return hit")
            e.preventDefault();
            test_text($(this).text())
            //set the text to a cleaned version
            $(this).text(clean_text($(this).text()))
            update_xmldbs([this]);
            //console.log(get_editing_progress())
            update_progress_bar()
            find_next_focus($(this))
        }
    });
    

    /**
     * Bind the following delete functions
     **/
    //the '.delete_element' class inside the .ocr_page should only be related
    //to generated elements, like lines and words, that have a related
    // 'x' box to delete them.
    $('.ocr_page').on('click', '.delete_element', function(e) {
    //console.log(this.id)
    delete_added_element(this)
    })
    //make all kill buttons for urn spans kill their related data
    //when built from the database
    $(".kill_button").on('click', function(event) {
        //remove the entire picker span
        span_id = $(this).parent().attr("id")
        console.log("span id" + span_id)
        picker_id = span_id.slice(0, -5);
        console.log("picker_id " + picker_id)
        //remove '_span' from the end of the name
        updateCTSURN(picker_id, "remove")
        $(this).parent().remove()

    });
    
    /**
     * Bind the following toggle functions
     **/
    $('#line_mode').click(function() {
        $(this).toggleClass('btn-primary');
    });
    
    /**
     * Make the tooltip image of the word
     **/
    //The actual dynamic generation of the tooltip 
    $('.ocr_word').on({
        'focus': function() {
            $(this).tooltip({
                //container: 'body',
                html: true,
                trigger: 'manual',
                placement: 'bottom',
                title: function() { 
                    var prev_bbox = "";
                    var page_path = $(this).closest('.ocr_page').attr("title");
                    //var bbox = $(this).attr('original-title');
                    var bbox_array = get_bbox_array_of_element($(this));
                    //Strip following, additional data in this
                    if (bbox.includes(';')) {
                        //console.log("theres additional data, that we'll strip")
                        bbox = bbox.substr(0, bbox.indexOf(';'));
                    }
                    //console.log(bbox_array)
                    var url = new URL(window.location.href);
                    var collectionUri = url.searchParams.get("collectionUri");
                    //collectionUri = $.urlParam('collectionUri');
                    var path_array = page_path.split('/');
                    var page_file = path_array[path_array.length - 1];
                    var scale = $("#page_image").attr("data-scale")
                    height_in = (bbox_array[3] - bbox_array[1])
                    min_height = 40 
                    height = Math.max(min_height, height_in)
                    image_scale = height / height_in
                    width_in = (bbox_array[2] - bbox_array[0])
                    width = width_in * image_scale
                    $("#svg_focus_rect").attr("x", bbox_array[0] * scale)
                    $("#svg_focus_rect").attr("y", bbox_array[1] * scale)
                    $("#svg_focus_rect").attr("width", width_in * scale)
                    $("#svg_focus_rect").attr("height", height_in * scale)
                    $('#svg_focus_rect').attr('visibility', 'visible');
                    return generate_image_tag_call(collectionUri, page_file, bbox, width, height)
                },
            }).tooltip('show');
        },
        'focusout': function() {
            $(this).tooltip('hide');
            $('#svg_focus_rect').attr('visibility', 'hidden');
        }
    });
    //end generate tooltips
    
});
