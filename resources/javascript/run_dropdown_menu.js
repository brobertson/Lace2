function show_info_report() {
        var url = new URL(window.location.href);
        var collectionUri = url.searchParams.get("collectionUri");
        //event.preventDefault(); 
        $.ajax({url: "collectionInfo.html?collectionUri=" + collectionUri, dataType: "xml",
    beforeSend: function() {
        $("#bars3").show();
    },
        success: function(result){
        $("#info_p").replaceWith(result.documentElement);
        $("#info_alert").show()
        $("#bars3").hide();
    }});
    }


function show_accuracy_report() {
    var url = new URL(window.location.href);
    var collectionUri = url.searchParams.get("collectionUri");
    //event.preventDefault(); 
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
}

function show_editing_report(){
        var url = new URL(window.location.href);
        var collectionUri = url.searchParams.get("collectionUri");
        var positionInCollection = url.searchParams.get("positionInCollection")
        //event.preventDefault(); 
          $.ajax({url: "getEditRatios.xq?collectionUri=" + collectionUri + "&positionInCollection=" + positionInCollection, dataType: "xml",
            beforeSend: function() {
                $("#bars3").show();
            },
            success: function(result){
                $("#svg_edit_report").replaceWith(result.documentElement);
                $("#bars3").hide();
                $("#svg_edit_report_holder").show();
            }});
}

$(function() {
    var url = new URL(window.location.href);
    var accuracy_view_choice = url.searchParams.get("accuracy_view");
    var editing_view_choice = url.searchParams.get("editing_view");
    var info_view_choice = url.searchParams.get("info_view");
    //do this as a class, and hide them all at once
    $("#bars3").hide();

    if (info_view_choice == "true") {
        show_info_report()
    }
    else {
            $("#info_alert").hide();
    }
    if (accuracy_view_choice == "true") {
        show_accuracy_report()
    }
    else {
     $("#svg_accuracy_report_holder").hide();

    }
    
    if (editing_view_choice == "true") {
        show_editing_report()
    }
    else {
     $("#svg_edit_report_holder").hide();
    }

$("#info_close").click(function(){
    $("#info_alert").hide();
});

$("#edit_close").click(function(){
    $("#svg_edit_report_holder").hide();
});

$("#accuracy_close").click(function(){
    $("#svg_accuracy_report_holder").hide();
});

    $("#run_info").click(function() {
        show_info_report();
    });

    $("#accuracy_view").click(function(){
        show_accuracy_report();
    });
    
    $("#editing_view").click(function() {
        show_editing_report();
    });
    $("a").click(function() {
        old_url = $(this).attr("href")
        url_extension = ""
        //the "?" means that this is a link to another view page, not off site, or whatever
        if (old_url[0] == "?") {
            if ($("#info_alert").is(":visible")) {
                url_extension = url_extension + "&info_view=true"
            }
            if ($("#svg_edit_report_holder").is(":visible")) {
                url_extension = url_extension + "&editing_view=true"
            }
            if ($("#svg_accuracy_report_holder").is(":visible")) {
                url_extension = url_extension + "&accuracy_view=true"
            }
            new_url = old_url + url_extension
            $(this).attr("href",new_url)
        }
    });
});