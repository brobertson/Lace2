const svg = $("#svg");
console.log("alive!2");
function screenToSVGCoords(canvas, e) {
  // Read the SVG's bounding rectangle...
  let canvasRect = canvas.getBoundingClientRect();
  // ...and transform clientX / clientY to be relative to that rectangle
  return {
    x: e.clientX - canvasRect.x,
    y: e.clientY - canvasRect.y
  }
}

mousemovefunct = function(canvas, e) {
    current_coords = screenToSVGCoords(canvas, e);
    console.log("moving " + current_coords.x + " " + current_coords.y)
    $("#finish_circle").attr('cx',current_coords.x)
    $("#finish_circle").attr('cy',current_coords.y)
}

mouseupfunct = function(canvas, e) {
    current_coords = screenToSVGCoords(canvas, e);
    console.log("mouse up " + current_coords.x + " " + current_coords.y)
    $("#finish_circle").attr('cx',current_coords.x)
    $("#finish_circle").attr('cy',current_coords.y)
}

$(document).ready(function() {

    //$("#svg").mouseup(function(e) {console.log("we did it");
    //    console.log(screenToSVGCoords(this, e))
    //});
    $("#svg").mousedown(function(e) {
  initial_coords = screenToSVGCoords(this, e);
  $("#start_circle").attr('cx',initial_coords.x)
  $("#start_circle").attr('cy',initial_coords.y)
  console.log("starting " + initial_coords.x + " " + initial_coords.y)
   $("rect").attr("fill-opacity","0.6");
  $(this).on("mousemove", function(e) {
    current_coords = screenToSVGCoords(this, e);
    $("#finish_circle").attr('cx',current_coords.x)
    $("#finish_circle").attr('cy',current_coords.y)
    let x = Math.min(initial_coords.x, current_coords.x);
    let y = Math.min(initial_coords.y, current_coords.y);
    let width = Math.abs(current_coords.x - initial_coords.x);
    let height = Math.abs(current_coords.y - initial_coords.y);
    $("rect").attr('x', x);
    $("rect").attr('y', y);
    $("rect").attr('width', width);
    $("rect").attr('height', height);
  });
  $(this).on("mouseup", function(e) {
       $(this).unbind("mousemove");
       $(this).unbind("mouseup");
       $("rect").attr("fill-opacity","0.0");
  
       
  });
  //document.addEventListener('mousemove', mousemovefunct(this));
  //document.addEventListener('mouseup', mouseupfunct(this));
    });


});



//  $(document).mouseup(function(e){
 //   alert("document up");
//});