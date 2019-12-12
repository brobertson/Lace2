const svg = $("#svg");

function save_svg() {
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
            svg_string = serializer.serializeToString(document.getElementById("svg"))
            data["svg"] = svg_string
            //console.log(svg_string);
            //console.log("posting ", data, " to ", whole_address)
            $.post(whole_address,data,function( data, textStatus, xhr  ) {
                console.log("svg success!" + xhr.responseText)
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
    
function intersectRect(rect1, rect2) {
    //console.log('doing ir3: rect1:')
    //console.log(rect1)
    //console.log(rect2)
// Returns true if two rectangles (l1, r1) and (l2, r2) overlap 
    left_x_of_rect1 = parseFloat(rect1.attr("x"))
    left_x_of_rect2 = parseFloat(rect2.attr("x"))
    right_x_of_rect2 = (left_x_of_rect2 + parseFloat(rect2.attr("width")))
    right_x_of_rect1 = ( left_x_of_rect1 + parseFloat(rect1.attr("width")))
    
    console.log("left edge of r1 " + left_x_of_rect1)
    console.log("left edge of r2: " + left_x_of_rect2)
    console.log("right edge of r1: " + right_x_of_rect1)
    console.log("right edge of r2: " + right_x_of_rect2)
    // If one rectangle is on left side of other 
    if ((left_x_of_rect1 > right_x_of_rect2) || (left_x_of_rect2 > right_x_of_rect1)) { 
        
        return false; 
    }
    top_y_of_rect1 = parseFloat(rect1.attr("y"))
    top_y_of_rect2 = parseFloat(rect2.attr("y"))
    bottom_y_of_rect1 = top_y_of_rect1 + parseFloat(rect1.attr("height"))
    bottom_y_of_rect2 = top_y_of_rect2 + parseFloat(rect2.attr("height"))
    console.log("top of r1 " + top_y_of_rect1)
    console.log("top of r2 " + top_y_of_rect2)
    console.log("bottom of r1 " + bottom_y_of_rect1)
    console.log("bottom of r2 " + bottom_y_of_rect2)
    // If one rectangle is above other 
   if ((top_y_of_rect1 > bottom_y_of_rect2) || (top_y_of_rect2 > bottom_y_of_rect1))  {
        return false; 
   }
   // otherwise, it is in fact overlapping
    return true; 
} 

function rectCollision(my_rectangle) {
    //console.log("id " + my_rectangle_id)
   // my_rectangle = $("#" + my_rectangle_id)
    var rectangles = $('.rectangle')
    console.log("number of rects: " + rectangles.length)
    if (rectangles.length == 1) {
        return false
    }
    for(var i = 0; i < rectangles.length; i++){
        console.log(rectangles[i])
        if (!($(rectangles[i]).attr("id") == my_rectangle.attr("id")) && intersectRect(my_rectangle, $(rectangles[i]))) {
            return true
        }
    }
    return false
}

function delete_rectangle($my_rectangle) {
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
}
function screenToSVGCoords(canvas, e) {
  // Read the SVG's bounding rectangle...
  let canvasRect = canvas.getBoundingClientRect();
  // ...and transform clientX / clientY to be relative to that rectangle
  return {
    x: e.clientX - canvasRect.x,
    y: e.clientY - canvasRect.y
  }
}

function get_rectangle_type() {
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
    is_selected = a_rectangle.hasClass("selected_rectangle")
    console.log("is it selectd? " + is_selected)
    $(".rectangle").removeClass("selected_rectangle")
    if (!is_selected) {
        a_rectangle.addClass("selected_rectangle")
        console.log("ive added the class")
    }
}


mousemovefunct = function(canvas, e) {
    current_coords = screenToSVGCoords(canvas, e);
    //console.log("moving " + current_coords.x + " " + current_coords.y)
    $("#finish_circle").attr('cx',current_coords.x)
    $("#finish_circle").attr('cy',current_coords.y)
}

mouseupfunct = function(canvas, e) {
    current_coords = screenToSVGCoords(canvas, e);
    //console.log("mouse up " + current_coords.x + " " + current_coords.y)
    $("#finish_circle").attr('cx',current_coords.x)
    $("#finish_circle").attr('cy',current_coords.y)
}

$(document).ready(function() {
  $("rect").mousedown(function(e) {
             console.log("you clicked on the prefab rect, man")
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
      console.log("key: ", key, " active id " + active_id)
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

            this_rect.attr("data-original-title", this_rect.attr("data-rectangle-type") + " Zone " + new_ordinal)
            save_svg();
            // re-enable tooltips
           // $(document).tooltip("enable");
            }
        }
  });
  
  $("html").on("focus", function(event) {
      $(".rectangle").removeClass("selected_rectangle")
  });
  
    $("#svg").mousedown(function(e) {
    new_rectangle_type = get_rectangle_type()
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
   // $("#finish_circle").attr('cx',current_coords.x)
   // $("#finish_circle").attr('cy',current_coords.y)
    let x = Math.min(initial_coords.x, current_coords.x);
    let y = Math.min(initial_coords.y, current_coords.y);
    let width = Math.abs(current_coords.x - initial_coords.x);
    let height = Math.abs(current_coords.y - initial_coords.y);
    $new_rectangle.attr('x', x);
    $new_rectangle.attr('y', y);
    $new_rectangle.attr('width', width);
    $new_rectangle.attr('height', height);
  });
  $(this).on("mouseup", function(e) {
       $(this).unbind("mousemove");
       $(this).unbind("mouseup");
       $new_rectangle.removeClass("selected_rectangle");
       //check it isn't overlapping with other rectangles
       total_dimensions = parseFloat($new_rectangle.attr("width")) + parseFloat($new_rectangle.attr("height"))
       console.log("dim: " + total_dimensions)
       if (rectCollision($new_rectangle) || (total_dimensions < 10)) {
           console.log("collision between rectangles or too small")
           delete_rectangle($new_rectangle)
       }
       else {//these are things we should only do with a new rectangle
       rect_number = $(".rectangle").length
       $new_rectangle.attr("data-rectangle-ordinal", rect_number)
       $new_rectangle.attr("data-rectangle-type", new_rectangle_type)
       $new_rectangle.attr("title", new_rectangle_type + " Zone " + rect_number)
       $new_rectangle.tooltip({
        placement: 'top',
        container: 'body' 

        });
         $new_rectangle.mousedown(function(e) {
             console.log("you clicked on the rect, man")
             toggle_selected($new_rectangle)
             e.stopPropagation()
         });
        save_svg();
       }

  });
  

  
    });


});

