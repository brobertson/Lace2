function get_filename() {
    var path_array = window.location.pathname.split("/")
    return path_array[path_array.length - 1]
}

function get_editing_progress() {
    alert("wow");
}

$.urlParam = function(name){
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    if (results===null) {
       return null;
    }
    return decodeURI(results[1]) || 0;
}

function update_progress_bar() {
    var confirmed = $("span[data-manually-confirmed='true']").length;
    $('.ocr_page').attr('data-confirmed-word-count', confirmed)
    var all_words = $("span[class='ocr_word']").length
    //console.log("all words" + all_words)
    //$('.ocr_page').attr('data-word-count', all_words)
    var empty_words = $("span[class='ocr_word']:empty").length
    $('.ocr_page').attr('data-empty-word-count',empty_words)
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
    var filePath = doc.substring(0,n);
    data['filePath'] = filePath
    picker_span = $(picker_span_string)
    composed_urn = $("#"+urnpicker_id).attr("data-ctsurn")+$("#"+urnpicker_id+"_additional").val()
    data['name'] = $("#"+urnpicker_id).attr("data-author-name") + " " + $("#"+urnpicker_id+"_additional").val()
    data['id'] = urnpicker_id + "_span"
    //this is unnecessary
    data['label'] = picker_span_string
    data['next_sibling_id'] = picker_span.next().attr('id')
    data['starting-span'] = picker_span.attr("data-starting-span")
    data['value'] = composed_urn
    data['action'] = my_action

    $.post('modules/updateCTSUrn.xq',data, function( data, textStatus, xhr  ) {
        console.log("success updating CTS URN: " + composed_urn + " on "+ picker_span_string + " at " + filePath + "/" + fileName + " before " + data['next_sibling_id'])//success
    })
    .fail( function(xhr, textStatus, errorThrown) {
        //failure
        console.log("failure updating CTS URN")
    });
   }

function update_xmldb(element, e) {
            var data = {};
            data['shift'] = e.shiftKey
            data['value'] = $(element).text();
            data['id'] = element.id;
            doc = $('.ocr_page').attr('title')
            data['doc'] = doc
            var n = doc.lastIndexOf('/');
            var fileName = doc.substring(n + 1);
            data['fileName'] = fileName
            var filePath = doc.substring(0,n);
            data['filePath'] = filePath
            whole_address = 'modules/updateWord.xq';
            //console.log("posting ", data, " to ", whole_address)
            old_attribute = element.getAttribute("data-manually-confirmed")
            element.setAttribute("data-manually-confirmed", "true");
            $.post(whole_address,data,function( data, textStatus, xhr  ) {
                //console.log("success!" + xhr.responseText)
                //this is the 'success' function 
                //if the update works, it will fire.
                //We can't use JQuery syntax here, for some reason.
                
            })
            .fail( function(xhr, textStatus, errorThrown) {
                element.setAttribute("data-manually-confirmed", old_attribute);
                if ((xhr.status == 404) || (xhr.status === 0)) {
                    alert("The connection has been lost to the lace server.")
                } 
                else {
                    alert(xhr.responseText + " status" + xhr.status);
                }
            });
          
}

function update_all_xmldb(element, e) {
            var data = {};
            
            doc = $('.ocr_page').attr('title')
            var n = doc.lastIndexOf('/');
            var fileName = doc.substring(n + 1);
            data['fileName'] = fileName
            var filePath = doc.substring(0,n);
            data['filePath'] = filePath
            
            data['correctedForm'] = $(element).text();
            data['query'] = $(element).attr('data-selected-form');

            data['id'] = element.id;
            console.log("updated " + data['query'] + " with " + data['correctedForm'] + " in all of " + data['collectionPath']);
            $.post('modules/updateMany.xq',data, function( dataReturned, textStatus, xhr ) {
                console.log("success!" + xhr.responseText)
                set_of_blinkers = $(".ocr_word").filter(function() { return ($(this).text() === data['query']) })
                console.log("blinker count " + set_of_blinkers.length)
                set_of_blinkers.addClass("blinker");
                //
                //this is the 'success' function 
                //if the update works, it will fire.
                //We can't use JQuery syntax here, for some reason.
                
            }).fail( function(xhr, textStatus, errorThrown) {
        alert(xhr.responseText);
    });
}

function add_line_below_xmldb(element, e,uniq) {
            //console.log("calling addlinebelow")
            var data = {};
            data['shift'] = e.shiftKey
            data['value'] = $(element).text();
            data['id'] = element.id;
            data['uniq'] = uniq;
            doc = $('.ocr_page').attr('title')
            data['doc'] = doc
            var n = doc.lastIndexOf('/');
            var fileName = doc.substring(n + 1);
            data['fileName'] = fileName
            var filePath = doc.substring(0,n);
            data['filePath'] = filePath
            $.post('modules/addLineBelow.xq',data,function( data, textStatus, xhr ) {
                //console.log("success!" + xhr.responseText)
                //this is the 'success' function 
                //if the update works, it will fire.
                //We can't use JQuery syntax here, for some reason.
                
            }).fail( function(xhr, textStatus, errorThrown) {
        alert(xhr.responseText);
    });
}




/*called when the 'x' button beside the added line is pressed*/
function delete_added_line(buttonElement) {
    var data = {};
    doc = $('.ocr_page').attr('title')
    data['doc'] = doc
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0,n);
    data['filePath'] = filePath
    enclosing_div_element = buttonElement.id.substr(0, buttonElement.id.lastIndexOf('_')).concat('_div');
    data['id'] = enclosing_div_element
    $.post('modules/deleteLine.xq',data, function( returnedData, textStatus, xhr ) {
                //console.log("success!" + xhr.responseText)
                //console.log("id is " + data["id"])
                        /* if it succeeds in removing from the database, 
        then also remove from the DOM on the screen 
        */
        $("#" + data['id']).remove();
            }).fail( function(xhr, textStatus, errorThrown) {
        alert(xhr.responseText);
    });

}

function add_index_after(element, e,uniq) {
            var data = {};
            data['shift'] = e.shiftKey
            data['value'] = $(element).text();
            data['id'] = element.id;
            data['uniq'] = uniq;
            doc = $('.ocr_page').attr('title')
            data['doc'] = doc
            var n = doc.lastIndexOf('/');
            var fileName = doc.substring(n + 1);
            data['fileName'] = fileName
            var filePath = doc.substring(0,n);
            data['filePath'] = filePath
            a = $.post(exist_server_address +  '/exist/apps/laceApp/addIndexWordAfter.xq',data)
}

function generate_image_tag_call(collectionUri, page_file, bbox) {
    //book_name = "490021999brucerob"
    //page_file = "490021999brucerob_0100.jpg"
        var request = "<img src=\"" + "getCroppedImage.xq?collectionUri=" + encodeURIComponent(collectionUri) + "&amp;file=" + encodeURIComponent(page_file) + "&amp;bbox=" + encodeURIComponent(bbox) + "\" alt='a word image'/>"
        //console.log(request);
	return request
}

$(function() {
    $("#svg_focus_rect").attr('visibility','hidden');
    update_progress_bar();
    //Store the 'title' attribute value somewhere else, because
    //the tooltip requires this to store its value
    $('.ocr_word').each(function() {
            var $e = $(this);
            if ($e.attr('title') || typeof($e.attr('original-title')) != 'string') {
                $e.attr('original-title', $e.attr('title') || '').removeAttr('title');
            }
        });
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
    //The actual dynamic generation of the tooltip 
    $('.ocr_word').on({
    'focus mouseover': function() {
        

        $(this).tooltip({
                //container: 'body',
                html: true,
                trigger: 'manual',
                placement: 'bottom',
                title: function() 
              { //console.log("Hi there " + this.nodeName)
                
                var prev_bbox = ""; 
                var page_path = $(this).closest('.ocr_page').attr("title");
                var bbox = $(this).attr('original-title');
                bbox = bbox.split(';')[0];
                //console.log("listen up: this is bbox: " + bbox)
                var bbox_array = bbox.split(" ");
                //Strip following, additional data in this
                if (bbox.includes(';')) {
                    //console.log("theres additional data, that we'll strip")
                    bbox = bbox.substr(0, bbox.indexOf(';'));

                }
                //console.log("using bbox array: " + bbox)
               //In the case of the last one in a line, the image spans both the second-to-last
               //and last word, so we cut the image for the last at the end of the second-to-last.
               //However, this tooltip widget puts itself in previous position, so we need to ask for 
               //the first previous element that is a span.ocr_word.
	if($(this).is(':last-child') && $(this).prevAll("span.ocr_word:first").length)
		{
		        prev_ocrword = $(this).prevAll("span.ocr_word:first");
		        //console.log("the previous is: " + prev_ocrword.get(0).nodeName + " and has class: " +  prev_ocrword.get(0).className + " and its text is " + prev_ocrword.get(0).nodeName.text)
		        prev_bbox = prev_ocrword.attr('original-title')
		        //console.log("previous box: " + prev_bbox)
                prev_end = prev_bbox.split(" ")[3]
                bbox_array = bbox.split(" ")
                bbox_array[1] = prev_end
                bbox = bbox_array.join(" ")
                //console.log("for end word, using bbox array: " + bbox)
		}
                            var url = new URL(window.location.href);
                            var collectionUri = url.searchParams.get("collectionUri");
                            //collectionUri = $.urlParam('collectionUri');
                            var path_array = page_path.split('/');
                            var page_file = path_array[path_array.length - 1];
                            var scale = $("#page_image").attr("data-scale")
                            console.log("bbox_array: " + bbox_array[1] + "; scale: " + scale)
                            console.log("bbox_array[4]: " + bbox_array[4])
                            $("#svg_focus_rect").attr("x",bbox_array[1]*scale)
                            $("#svg_focus_rect").attr("y",bbox_array[2]*scale)
                            $("#svg_focus_rect").attr("width",(bbox_array[3]-bbox_array[1])*scale)
                            $("#svg_focus_rect").attr("height",(bbox_array[4]-bbox_array[2])*scale)
                            $('#svg_focus_rect').attr('visibility','visible');
                            return generate_image_tag_call(collectionUri, page_file, bbox)},
            }).tooltip('show');
    },
    'focusout mouseout': function() {
        $(this).tooltip('hide');
        $('#svg_focus_rect').attr('visibility','hidden');
    }
});
//end generate tooltips

    $('.ocr_word').bind('keydown', function(e) {
        if (e.which == 110) {
           e.preventDefault();
           alert("combo");
        }
    });


    $('.inserted_line').bind('keypress', function(e) {
        if (e.which == 13) {
           e.preventDefault();
           //console.log("trying to update xmldb")
           update_xmldb(this, e);
        }
    });
    
    $('.ocr_word').bind('keypress', function(e) { 
        if (e.which == 13) {
        console.log("return hit")
         e.preventDefault();
         if (e.altKey == true) {
             console.log("alt is on")
           if (e.ctrlKey == false) {
               console.log("ctrl is off")
            //alert("that's it");
            var uniq = 'ins_word_' + (new Date()).getTime();
            var index_word = $( "<span class='index_word' id='" + uniq + "' data-manually-confirmed='false' contenteditable='true'/>" )
            $(this).after(index_word);
            add_index_after(this,e,uniq);
            $('.ocr_page').on('keypress', '.index_word', function(e) {
               if (e.which == 13) {
                  e.preventDefault();
                  update_xmldb(this, e);
                 // $(this).attr("data-manually-confirmed", "true");
               }
            });
            index_word.focus()
            return;//this is the trick to short-circuiting the function.
         }
       
       else {//ctrlKey is true, also
       console.log("control-alt-return hit")
        var uniq_picker = 'ins_cts_picker_' + (new Date()).getTime();
        var cts_picker=$("<span class='cts_picker' id='" + uniq_picker + "_span'>📖<input class='ctsurn-picker' id='" + uniq_picker + "' type='text' placeholder='author/title'/><input class='ctsurn-span' id='" + uniq_picker + "_additional'/><button id='" + uniq_picker + "_ok_button' class='btn' type='button'>OK</button><button class='kill_button' type='button' id='" + uniq_picker + "_kill_button'> <span>×</span> </button></span>");
$(this).before(cts_picker);
cts_picker.attr("data-starting-span",$(this).attr("id"))
$("#" + uniq_picker).typeahead({
    source: function (query) {
        var self = this;
        self.map = {};
        var items = [];
        //ctsGreekTags is assigned in a separate file
        $.each(cts_tags, function (i, item) {
            self.map[item.label] = item;
            items.push(item.label)
        });
        return items;
    },
    updater: function (item) {
        var selectedItem = this.map[item];
        this.$element.data('selected', selectedItem);
        console.log(selectedItem)
        console.log(this.$element)
       this.$element.attr("data-ctsurn", selectedItem["id"])
       this.$element.attr("data-author-name", selectedItem["label"])
        return item
    }
});
$("#" + uniq_picker+"_ok_button").on('click', function(event) {
  event.preventDefault(); // To prevent following the link (optional)
  console.log("sof far so good")
  //add data and tooltip to span
  the_span = $("#" + uniq_picker+"_span")
  /***
   * in the case of a close-reference milestone, trying to use the closed-book emoji, but honestly, this
   * causes a bunch of side effects, so wait for another day.
  if ($("#"+uniq_picker).attr("data-ctsurn") === "__end__") {
     the_span.text("📕")
  } 
  ***/
  composed_urn = $("#"+uniq_picker).attr("data-ctsurn")+$("#"+uniq_picker+"_additional").val()
  readable_name = $("#"+uniq_picker).attr("data-author-name")+" " + $("#"+uniq_picker+"_additional").val()
  the_span.attr("data-ctsurn", composed_urn)
  the_span.attr("data-toggle", "tooltip")
  the_span.attr("data-placement", "top")
  the_span.attr("title", readable_name)
  //the_span.tooltip()
  console.log("here, uniq_picker is " + uniq_picker)
  updateCTSURN(uniq_picker, "add")
  //now delete all the inner inputs and this button
  $("#" + uniq_picker).remove()
  $("#" + uniq_picker + "_additional").remove()
  $("#" + uniq_picker + "_ok_button").remove()
});
$("#" + uniq_picker+"_kill_button").on('click', function(event) {
    //remove the entire picker span
    updateCTSURN(uniq_picker, "remove")
    $(this).parent().remove()
});
            return;//this is the trick to short-circuiting the function.
 }//end ctrl key is true
}// end alt key is true
          if (e.shiftKey == false) {
            var data = {};
            console.log(this.constructor.name);
            if(e.ctrlKey == true) {//with ctrl held down, every word in all volume page is
            //corrected at once
               update_all_xmldb(this,e);
               old_form = $(this).attr('data-selected-form')
               new_form = $(this).text()
               $(".ocr_word[data-selected-form='" + old_form.replace(/'/g, "\\'") + "']").each(function(){
                  $(this).text(new_form);
                  $(this).attr("data-manually-confirmed", "true");
               });
             }//end e.ctrlKey == true
            else {//ctrlKey == false
            //this is what happens if you just hit return.
               //console.log("doing single word update")
               update_xmldb(this, e);
               //console.log(get_editing_progress())
               update_progress_bar()
            }
            //$(this).attr("data-manually-confirmed", "true");
            var focusables = $(".ocr_word");
            var current = focusables.index(this);
            //var path_array = window.location.pathname.split("/")
            following_focusables = focusables.slice(current,focusables.length)
            preceding_focusables = focusables.slice(0,current)
            preceding_focusables_unedited = preceding_focusables.filter(function(){
                   return $(this).attr('data-manually-confirmed') == 'false'
                })
           // console.log("following length: " + following_focusables.length)
            following_focusables_unedited = following_focusables.filter(function(){
                   return $(this).attr('data-manually-confirmed') == 'false'
                })
           // console.log("ffuned: " + following_focusables_unedited.length)
            if (following_focusables_unedited.length > 0) {
            next = following_focusables_unedited[0]
            }
            else if (preceding_focusables_unedited.length > 0) {
                next = preceding_focusables_unedited[0]
            }
            else {
              next = focusables.eq(current + 1).length ? focusables.eq(current + 1) : focusables.eq(0);
            }
/* Not certain this functionality is desired. It rapidly verifies a whole bunch of following words, but I thinnk
   it ends up validating to liberally in practice.
            if (e.shiftKey == true) {
              //First, make sure we don't get into endless loop when all are edited. Next only rip through the ones that are True,
              //Edited (Manual) or TrueLower
              while (focusables.index(next) != 0 && ($(next).attr("data-spellcheck-mode") === "True" || $(next).attr("data-manually-confirmed") === "true" || $(next).attr("data-spellcheck-mode") === "TrueLower")){
                update_xmldb(next);
                console.log(next.constructor.name);
                console.log(next);
                $(next).attr("data-manually-confirmed", "true");
                next_index = focusables.index(next);
		alert(next_index);
                next = focusables.eq(next_index + 1).length ? focusables.eq(next_index + 1) : focusables.eq(0);
                }
            }
*/
            next.focus()
            var all_manually_edited = true;
            $(".ocr_word").each(function(index, element) {
                if (($(element).attr("data-spellcheck-mode") !== "Manual") && ($(element).attr("data-manually-confirmed") !== "true")) {
                    all_manually_edited = false;
                }
            });
            if (all_manually_edited) {
                $('#download').attr('style', "display: block;");
            }
            var name = get_filename();
            $('#download').attr('download', name);
            }//end shiftkey = false
            else { // shiftkey is true
             if (e.shiftKey == true) {
                 //console.log("inserting line")
               var uniq = 'ins_line_' + (new Date()).getTime();
               var newline = $( "<div class='inserted_line_div' id='" + uniq + "_div'><span class='inserted_line' id='" + uniq + "' data-manually-confirmed='false' contenteditable='true'></span><button id='" + uniq + "_button' type='button' class='close' aria-label='Close'><span aria-hidden='true'>&times;</span></button></div>" )
                  $('.ocr_page').on('click', '.close', function(e) {
                    //console.log(this.id)
                    delete_added_line(this)
                    });
               $(this).parent('.ocr_line').after(newline);
               add_line_below_xmldb(this,e,uniq);
              
               $('.ocr_page').on('keypress', '.inserted_line', function(e) {
                   //console.log("we get an inserted line keypress")
                    if (e.which == 13) {
                        //console.log("it's a return")
                       e.preventDefault();
                       update_xmldb(this, e);
                    }
                });
         
               newline.focus()
             }
            }//end else
           }//end if e.which == 13
            });
});
