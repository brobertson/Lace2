const svg = $("#svg");

function save_svg() {
    /**** 
     * Interacts with the 'modules/updateSVGRects.xq' xquery file to 
     * save the state of the svg element in the XML database.
     ***/
    var data = {};
    doc = $('.ocr_page').attr('title')
    data['doc'] = doc
    var n = doc.lastIndexOf('/');
    var fileName = doc.substring(n + 1);
    data['fileName'] = fileName
    var filePath = doc.substring(0,n);
    data['filePath'] = filePath
    doc = $('.ocr_page').attr('title')
    whole_address = 'modules/updateSVGRects.xq';
    var serializer = new XMLSerializer();
    //we pass the svg as a string
    svg_string = serializer.serializeToString(document.getElementById("svg"))
    data["svg"] = svg_string
    $.post(whole_address,data,function( data, textStatus, xhr  ) {
       // console.log("svg success!" + xhr.responseText)
        //this is the 'success' function 
        //if the update works, it will fire.
        //We can't use JQuery syntax here, for some reason.
        
    })
    .fail( function(xhr, textStatus, errorThrown) {
        if ((xhr.status == 404) || (xhr.status === 0)) {
            alert("The connection has been lost to the lace server.")
        } 
        else {
            alert(xhr.responseText + " status" + xhr.status);
        }
    });
}
 
/*************************************/
/****
 * Rectangle helper functions:
 ****/
 
function intersectRect(rect1, rect2) {
    /****
     * Returns 'true' if the two rectangles overlap. 
     ***/

    left_x_of_rect1 = parseFloat(rect1.attr("x"))
    left_x_of_rect2 = parseFloat(rect2.attr("x"))
    right_x_of_rect2 = (left_x_of_rect2 + parseFloat(rect2.attr("width")))
    right_x_of_rect1 = ( left_x_of_rect1 + parseFloat(rect1.attr("width")))
    // If one rectangle is on left side of other 
    if ((left_x_of_rect1 > right_x_of_rect2) || (left_x_of_rect2 > right_x_of_rect1)) { 
        
        return false; 
    }
    top_y_of_rect1 = parseFloat(rect1.attr("y"))
    top_y_of_rect2 = parseFloat(rect2.attr("y"))
    bottom_y_of_rect1 = top_y_of_rect1 + parseFloat(rect1.attr("height"))
    bottom_y_of_rect2 = top_y_of_rect2 + parseFloat(rect2.attr("height"))
    // If one rectangle is above other 
   if ((top_y_of_rect1 > bottom_y_of_rect2) || (top_y_of_rect2 > bottom_y_of_rect1))  {
        return false; 
   }
   // otherwise, it is in fact overlapping
    return true; 
} 

function rectCollision(my_rectangle) {
    /****
     * Compares 'my_rectangle' with all the other elements of class .rectangle
     * to return 'true' if any of them collide.
     ***/
    var rectangles = $('.rectangle')
    //if there's only one rectangle, then it's 'my_rectangle' and we don't need to go
    //any further.
    if (rectangles.length == 1) {
        return false
    }
    for(var i = 0; i < rectangles.length; i++){
        //check that it isn't this same rectangle that is colliding!
        if (!($(rectangles[i]).attr("id") == my_rectangle.attr("id")) && intersectRect(my_rectangle, $(rectangles[i]))) {
            return true
        }
    }
    return false
}

function delete_rectangle($my_rectangle) {
    /****
     * Takes a jquery svg rectangle and destroys it and its corresponding 
     * corner dots and tooltip. It uses the id of the rectangle minus the 
     * string '_rectangle' as a key to these other elements ids.
     ***/
    //fun fact: if you have focus, your tooltip will not get destroyed, no matter what
    $my_rectangle.blur()
    $my_rectangle.tooltip("destroy");
    $my_rectangle.remove()
    suffix="_rectangle"
    id = $my_rectangle.attr("id")
    bare_name = id.substring(0,id.length-suffix.length)
    start_circle_id = bare_name + "_start_circle"
    finish_circle_id = bare_name + "_finish_circle"
    $("#"+finish_circle_id).remove()
    $("#" + start_circle_id).remove()
    clear_zoning_hilight()
}


function screenToSVGCoords(canvas, e) {
    /****
     * Converts mouse coordinates to SVG canvas coordinates
    ***/
  // Read the SVG's bounding rectangle...
  let canvasRect = canvas.getBoundingClientRect();
  // ...and transform clientX / clientY to be relative to that rectangle
  return {
    x: e.clientX - canvasRect.x,
    y: e.clientY - canvasRect.y
  }
}

function get_line_mode_state() {
    /*****
     * Look at the html:button with id line_mode and see if its class is 
     * btn-primary. If it is, then return true
     ****/
     return $("#line_mode").hasClass("btn-primary")
}

function get_rectangle_type() {
    /***
     * uses the dropdown menu #zoning_choice to find the one item within it
     * that has the class 'active', and returns its id, minus the string '_button'
     * on the end of that id.
     ****/
    var zoning_buttons = $("#zoning_choice").children()
    console.log("number of children? " + zoning_buttons.length)
        for(var i = 0; i < zoning_buttons.length; i++){
            console.log(zoning_buttons[i].id + "active? " + $(zoning_buttons[i]).hasClass("active"))
            //inner_input = $(zoning_buttons[i]).children()[0]
            if($(zoning_buttons[i]).hasClass("active")){
                //remove string '_button' from the end of the 'id'
                return zoning_buttons[i].id.substring(0,zoning_buttons[i].id.length -7);
            }

        }
     return zoning_buttons[0].id.substring(0,zoning_buttons[0].id.length -7);
}

function toggle_selected(a_rectangle) {
    /****
     * Toggles a rectangle between the selected and unselected
     * states. As a side-effect, it un-selects other selected
     * rectangles and appropriately establishes the hilighting of
     * ocr_words in the text.
     ***/
    is_selected = a_rectangle.hasClass("selected_rectangle")
    if (is_selected) {//we're unselecting it
        a_rectangle.removeClass("selected_rectangle")
        clear_zoning_hilight()
    }
    else {//we're selecting it
        //clear the selection of all other rectangles
        $(".rectangle").removeClass("selected_rectangle")
        clear_zoning_hilight()
        //make this rectangle selected
        a_rectangle.addClass("selected_rectangle")
        //hilight the corresponding words
        hilight_corresponding_ocr_words(a_rectangle)
    }
}

/********************************************/

/****
 * Helper functions for dealing with ocr_word bboxes, comparing them
 * to SVG rectangles, for instance. 
 * TODO: cash a map between ocr_word ids and these converted bboxes, since
 * we calculate these many times on static data.
 ***/

function bbox_string_to_data(bbox_string) {
    bbox = bbox_string.split(';')[0];
    var bbox_array = bbox.split(" ");
    return {x: bbox_array[1], y: bbox_array[2], width: bbox_array[3] - bbox_array[1], height: bbox_array[4] - bbox_array[2]};
    
}

function bbox_string_to_data_x1(bbox_string) {
    bbox = bbox_string.split(';')[0];
    var bbox_array = bbox.split(" ");
    //console.log("bbox array at to data: " + bbox_array)
    return {x: parseInt(bbox_array[1],10), y: parseInt(bbox_array[2],10), x1: parseInt(bbox_array[3],10), y1: parseInt(bbox_array[4],10)};
    
}

/* debugging function: not needed regularly*/
function print_rect(rectangle) {
    console.log("\tx: " + rectangle.attr("x"))
    console.log("\ty: " + rectangle.attr("y"))
    console.log("\twidth: " + rectangle.attr("width"))
    console.log("\theight: " + rectangle.attr("height"))
}


function bbox_string_to_rect(bbox_string) {
    box_dict = bbox_string_to_data(bbox_string)
    //console.log(box_dict)
    var scale = $("#page_image").attr("data-scale")
    var $new_rectangle = $(document.createElementNS("http://www.w3.org/2000/svg", "rect")).attr({
        x: box_dict["x"] * scale,
        y: box_dict["y"] *scale,
        width: box_dict["width"] *scale,
        height: box_dict["height"] *scale
    });
    return $new_rectangle
}

/************
 * Functions relating to hilighting .ocr_word spans that correspond to
 * a given svg rectangle. The 'zoning_hlight' css class is added or removed
 * to create the effect.
 ************/

function clear_zoning_hilight() {
    /****
     * Removes all hilighting
     ***/
    $(".zoning_hilight").removeClass("zoning_hilight")
}

function hilight_corresponding_ocr_words($zone_rectangle) {
    /****
     * Given a SVG rectangle, this applies the 'zoning_hilight' class to each
     * .ocr_word element that either is within or intersecting with that rectangle.
     ***/
    $(".ocr_word, .inserted_line, .index_word").each(function() {
        test_rect = bbox_string_to_rect($(this).attr("original-title"))
        if (intersectRect($zone_rectangle, test_rect)) {
            $(this).addClass("zoning_hilight")
        }
        if ($(this).hasClass("zoning_hilight") && !intersectRect($zone_rectangle, test_rect)) {
            $(this).removeClass("zoning_hilight")
        }
    });
}

function resize_rect_to_corresponding_ocr_words($zone_rectangle) {
    /****
     * Given a SVG rectangle, this resizes it to the perimeter of the 
     * .ocr_word elements that either are within or intersecting with that rectangle.
     ***/
    hit_array = []
    $(".ocr_word, .inserted_line, .index_word").each(function() {
        data_rect = bbox_string_to_data_x1($(this).attr("original-title"))
        test_rect = bbox_string_to_rect($(this).attr("original-title"))
        if (intersectRect($zone_rectangle, test_rect)) {
            //add test_rect to the array of rects
            console.log("a data_rect:" + data_rect['x'] + " " + data_rect["y"] + " " + data_rect["x1"] + " " + data_rect["y1"])
            hit_array.push(data_rect)
        }
    });
    //collect the widest dimensions based on the enclosed or touched words
    var i;
    var x1 = 0;
    y1 = 0;
    var x = 1000000;
    y = 1000000;
    for (i = 0; i < hit_array.length; i++) {
        //console.log("x of rect in loop is: " + hit_array[i]['x'])
        //console.log("x is " + x)
        if (hit_array[i]['x'] < x) {
            console.log(hit_array[i]['x'] + " is less than " + x)
            x = hit_array[i]['x']
        }
        if (hit_array[i]['y'] < y) {
            y = hit_array[i]['y']
        }
        if (hit_array[i]['x1'] > x1) {
            //console.log(hit_array[i]['x1'] + " is greater than " + x1)
            x1 = hit_array[i]['x1']
        }
        if (hit_array[i]['y1'] > y1) {
            y1 = hit_array[i]['y1']
        }
    }
    console.log("modified zone_rectangle so that its outer limits are " + x + " " + y + " " + x1 + " " + y1)
    //modify $zone_rectangle so that is the outer limits of all of those rects
    var scale = $("#page_image").attr("data-scale")
    $zone_rectangle.attr('x', x*scale);
    $zone_rectangle.attr('y', y*scale);
    $zone_rectangle.attr('width', Math.max((x1-x)*scale,0));
    $zone_rectangle.attr('height', Math.max((y1-y)*scale,0));
    suffix="_rectangle"
    id = $zone_rectangle.attr("id")
    bare_name = id.substring(0,id.length-suffix.length)
    start_circle_id = bare_name + "_start_circle"
    finish_circle_id = bare_name + "_finish_circle"
    $("#"+start_circle_id).attr('cx',x*scale)
    $("#" + start_circle_id).attr('cy',y*scale)
    $("#"+finish_circle_id).attr('cx',x1*scale)
    $("#"+finish_circle_id).attr('cy',y1*scale)
    //return $zone_rectangle 
    //with its dimensions expanded.
}

$(document).ready(function() {
    /****
     * Binds listeners to objects.
     ***/
    
    /****
    * 1. The button with id 'clear_zones_button' causes all the 
    * objects of class '.rectangle' to be deleted.
    ***/
    $("#clear_zones_button").mouseup(function(e) {
        $('.rectangle').each(function() { 
            delete_rectangle($(this))
        });
        save_svg();
    });
    
  $(".rectangle").mousedown(function(e) {
             toggle_selected($(this))
             console.log("this: " + $(this)[0].tagName)
             $(this).focus()
             e.stopPropagation()
         });
         $('rect').tooltip({
        placement: 'top',
        container: 'body' 
        });
  $(".zoning-dropdown-item").mouseup(function(e) {
      $(".zoning-dropdown-item").removeClass("active")
      $(this).addClass("active")
  });
  $(this).on("keyup", function(event) {
      active_id = document.activeElement.id
      const key = event.key; // const {key} = event; ES6+
        if ((key === "Backspace" || key === "Delete") && (active_id.includes("rectangle"))) {
         console.log("it was the delete key on a rectangle: " + active_id)
         delete_rectangle($("#" + active_id));
        //now renumber the rectangles
        rectangles = $(".rectangle")
        rectangles.sort(function(obj1, obj2) {
            return $(obj1).attr('data-rectangle-ordinal') - $(obj2).attr('data-rectangle-ordinal');
            });
        for(var i = 0; i < rectangles.length; i++){
            this_rect = $(rectangles[i])
            new_ordinal = i + 1
            console.log(this_rect.attr("data-rectangle-ordinal"))
            this_rect.attr("data-rectangle-ordinal",new_ordinal)
            // first, disable tooltips to make the change stick
            // don't believe this is actually necessary
           // $(document).tooltip("disable");
            this_rect.attr("title", this_rect.attr("data-rectangle-type") + " Zone " + new_ordinal)

            this_rect.attr("data-original-title", this_rect.attr("data-rectangle-type") + " zone " + new_ordinal)
            // re-enable tooltips
           // $(document).tooltip("enable");
            }
        save_svg();
        }
  });
  
  $("html").on("focus", function(event) {
      $(".rectangle").removeClass("selected_rectangle")
  });
  
    $("#svg").mousedown(function(e) {
    new_rectangle_type = get_rectangle_type()
    line_mode = get_line_mode_state()
    new_rectangle_id = new_rectangle_type + "_" + (new Date()).getTime();
  initial_coords = screenToSVGCoords(this, e);
  var $new_start_circle = $(document.createElementNS("http://www.w3.org/2000/svg", "circle")).attr({
        cx: initial_coords.x,
        cy: initial_coords.y,
        //fill: 'red',
        r: '3',
        id: new_rectangle_id + "_start_circle",
        class: new_rectangle_type + "_circle"
    });
    var $new_finish_circle = $new_start_circle.clone()
    $new_finish_circle.attr("id",new_rectangle_id + "_finish_circle")

   var $new_rectangle = $(document.createElementNS("http://www.w3.org/2000/svg", "rect")).attr({
        x: initial_coords.x,
        y: initial_coords.y,
        id: new_rectangle_id + "_rectangle",
        class: new_rectangle_type + "_rectangle"
    });
    //can't do this above because of hyphen!
    $new_rectangle.attr("data-rectangle-type", new_rectangle_type)
    $new_rectangle.attr("data-rectangle-line-mode", line_mode)
    $new_rectangle.attr("fill-opacity","0.0")
    $new_rectangle.addClass("rectangle")
    $("#svg").append($new_rectangle)
    $("#svg").append($new_start_circle);
   $("#svg").append($new_finish_circle);
  $new_rectangle.addClass("selected_rectangle")
  $(this).on("mousemove", function(e) {
    current_coords = screenToSVGCoords(this, e);
    $new_finish_circle.attr('cx',current_coords.x)
    $new_finish_circle.attr('cy',current_coords.y)
    let x = Math.min(initial_coords.x, current_coords.x);
    let y = Math.min(initial_coords.y, current_coords.y);
    let width = Math.abs(current_coords.x - initial_coords.x);
    let height = Math.abs(current_coords.y - initial_coords.y);
    $new_rectangle.attr('x', x);
    $new_rectangle.attr('y', y);
    $new_rectangle.attr('width', width);
    $new_rectangle.attr('height', height);
    hilight_corresponding_ocr_words($new_rectangle)
  });
  $(this).on("mouseup", function(e) {
       $(this).unbind("mousemove");
       $(this).unbind("mouseup");
       console.log("it was mouseup")
       console.log("rect before")
       print_rect($new_rectangle)
       $new_rectangle.removeClass("selected_rectangle");
       clear_zoning_hilight();
       resize_rect_to_corresponding_ocr_words($new_rectangle)
        console.log("rect after")
        print_rect($new_rectangle)
        //check it isn't overlapping with other rectangles
       total_dimensions = parseFloat($new_rectangle.attr("width")) + parseFloat($new_rectangle.attr("height"))
       //apparently rectangles can be made without these properties. If it doesn't have them, we don't want 
       //it to persist.
       console.log("dim: " + total_dimensions)
       has_width = $(this)[0].hasAttribute("width");
       console.log("width? " + has_width)
       has_height = $(this)[0].hasAttribute("height");
       if (rectCollision($new_rectangle) || (total_dimensions < 10) || !has_width || !has_height || isNaN(total_dimensions)) {
           console.log("new rect. not kept because of collision between rectangles or too small or no width/height")
           delete_rectangle($new_rectangle)
       }
       else {//these are things we should only do with a new rectangle
       /****
        * give the new rectangle a ordinal number
        ***/
       rect_number = $(".rectangle").length
       $new_rectangle.attr("data-rectangle-ordinal", rect_number)

       $new_rectangle.attr("title", new_rectangle_type + " Zone " + rect_number)
       //Give the new rectangle a tooltip
       $new_rectangle.tooltip({
        placement: 'top',
        container: 'body' 

        });
        //bind a mousedown event to this rectangle so that it is selected.
         $new_rectangle.mousedown(function(e) {
             console.log("you clicked on the rect, man")
             toggle_selected($new_rectangle)
             e.stopPropagation()
         });
        //finally, once the rectangle stops moving and has all its new properties, 
        //we save the state of the SVG 'canvas'.
        save_svg();
       }

  });
  

  
    });


});

