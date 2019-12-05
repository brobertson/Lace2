$(function() {
    //do this as a class, and hide them all at once
    $("#bars3").hide();
    $("#info_alert").hide();
    $("#svg_accuracy_report_holder").hide();
    $("#svg_edit_report_holder").hide();

$("#info_close").click(function(){
    $("#info_alert").hide();
});

$("#edit_close").click(function(){
    $("#svg_edit_report_holder").hide();
});

$("#accuracy_close").click(function(){
    $("#svg_accuracy_report_holder").hide();
});

    $("#run_info").click(function(){
        var url = new URL(window.location.href);
        var collectionUri = url.searchParams.get("collectionUri");
        event.preventDefault(); 
        $.ajax({url: "collectionInfo.html?collectionUri=" + collectionUri, dataType: "xml",
    beforeSend: function() {
        $("#bars3").show();
    },
        success: function(result){
        $("#info_p").replaceWith(result.documentElement);
        $("#info_alert").show()
        $("#bars3").hide();
    }});
    });

    $("#accuracy_view").click(function(){
        var url = new URL(window.location.href);
        var collectionUri = url.searchParams.get("collectionUri");
        event.preventDefault(); 
        svgUrl = '/exist/rest' + collectionUri + '/accuracyReport.svg'
        $.ajax({url: svgUrl, dataType: "xml",
    beforeSend: function() {
        $("#bars3").show();
    },
        success: function(result){
        $("#svg_accuracy_report").replaceWith(result.documentElement);
        $("#bars3").hide();
         $("#svg_accuracy_report_holder").show();
    }});
    });
    $("#editing_view").click(function(){
        var url = new URL(window.location.href);
        var collectionUri = url.searchParams.get("collectionUri");
        event.preventDefault(); 
  $.ajax({url: "getEditRatios.xq?collectionUri=" + collectionUri, dataType: "xml",
    beforeSend: function() {
        $("#bars3").show();
    },
    success: function(result){
        $("#svg_edit_report").replaceWith(result.documentElement);
        $("#bars3").hide();
        $("#svg_edit_report_holder").show();
    }});
});
});