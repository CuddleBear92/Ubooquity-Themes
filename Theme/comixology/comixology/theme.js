/* Settings */
var proxyPrefix = "/ubooquity"; /* blank if no proxy */
var StoryArcFolder = "__Story Arcs"; 
var itemsPerPage=48; /* This are only used by old story arc pages */
var maxPages=20;     /* New arc lists don't use addLink, so no need to change this for a new install */

function hideStoryArcs(){
    $('#arcLink').attr('href',$( '.cellcontainer > .cell > .label:exact("'+StoryArcFolder+'")' ).parent().find('a').attr('href'));
    $( '.cellcontainer > .cell > .label:exact("'+StoryArcFolder+'")' ).parent().parent().remove();
}

/* Older method links */
function addFeatured(publisher){
    $( '.cellcontainer > .cell > .label:exact("'+publisher+'")' ).parent().parent().clone().appendTo( "#featured" );   
}

function addLink(pageID, searchString, orderNum, pageNum){
    if (pageNum === undefined) {
        pageNum = 0;
    }
    $('<div>').load("../"+pageID+"/?index="+(pageNum * itemsPerPage)+" .cellcontainer:has(.label:contains('"+searchString+"'))", function() {
        if ( $(this).children().length > 0 ) {
            if (orderNum !== undefined) {
                $(this).find(".cellcontainer").attr('id', orderNum);
            }
            $(this).find(".cellcontainer").attr('data-seriesid', pageID);
            $("#group").append($(this).find(".cellcontainer"));
        } else {
            pageNum++;
            if(pageNum <= maxPages){
                addLink(pageID, searchString, orderNum, pageNum);
            }
        }
    });
}

/* Bookmark Functions */
var Bookmarks = [];
function storeElement(href,onclick,img,label){
    Bookmarks.push([href,onclick,img,label]);
    localStorage.setItem("Ubooquity_Bookmarks2",JSON.stringify(Bookmarks));
}

function buildElement(href,onclick,img,label,index){
    var $temp = $('<div>', {
        "class": 'cell'
    }).wrap($('<div>', {
        "class": 'cellcontainer',
        id: index
    }));   
    
    $temp.append(($('<div>', {
        "class": 'thumb'
    })).append($('<a>').attr({
        href: href,
        "onclick": onclick
    }).append($('<img>').attr({
        src: img
    }))));
    
    $temp.append($('<div>', {
        "class": 'label',
        text: label
    }));
    
    if(window.location.href.indexOf("bookmarks.htm") != -1){
        $temp.parent().hover(function() {
            $(this).append($("<div id='remButton' onclick='delBookmark($(this).parent().find(\".thumb a img\").attr(\"src\"));'></div>"));
        }, function() {
            $(this).find("#remButton").remove();
        });
    } else {
        $temp.parent().hover(function() {
            $( this ).prepend( $( "<div id='addButton' onclick='storeElement($(this).parent().find(\".thumb a\").attr(\"href\"),$(this).parent().find(\".thumb a\").attr(\"onclick\"),$(this).parent().find(\".thumb a img\").attr(\"src\"),$(this).parent().find(\".label\").text());'></div>" ) );
        }, function() {
            $( this ).find( "#addButton" ).remove();
        });
    }
    
    $temp.parent().appendTo('#group');
}

function rebuildBookmarks(){
    $( ".cellcontainer" ).remove();
    for (i = 0; i < Bookmarks.length; i++) {            
        buildElement(Bookmarks[i][0],Bookmarks[i][1],Bookmarks[i][2],Bookmarks[i][3], i+1);
    }
    $('#group').sortable({
        items: ".cellcontainer",
        containment: "document",
        placeholder: "sortable-placeholder",
        activate: function ( event, ui ) {
            $('.sortable-placeholder').height(ui.item[0].clientHeight-10);
        },
        stop: function( event, ui ) {
            resaveBookmarks();
        }
    });
}
    
function resaveBookmarks(){
    Bookmarks = [];
    localStorage.setItem("Ubooquity_Bookmarks2",JSON.stringify([]));  
    $('#group .cellcontainer').each(function () {
        storeElement($(this).find(".thumb a").attr("href"),$(this).find(".thumb a").attr("onclick"),$(this).find(".thumb a img").attr("src"),$(this).find(".label").text());
    });
}
    
function delBookmark(url){
    for(var i = 0; i < Bookmarks.length; i++) {
       if(Bookmarks[i][2] === url) {
         Bookmarks.splice(i,1);
         localStorage.setItem("Ubooquity_Bookmarks2",JSON.stringify(Bookmarks));
         rebuildBookmarks();
       }
    }
};

function exportBookmarks(){
    var csvContent = "data:text/csv;charset=utf-8,";
    Bookmarks.forEach(function(infoArray, index){
        dataString = '"'+infoArray.join('","')+'"';
        csvContent += index < Bookmarks.length-1 ? dataString+ "\n" : dataString;
    }); 
    var encodedUri = encodeURI(csvContent);
    var link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "export.csv");
    link.click();
}

function clearBookmarks(){
    Bookmarks = [];
    localStorage.setItem("Ubooquity_Bookmarks2",JSON.stringify(Bookmarks));  
    location.reload();
}

function buildArc(arclist){
    for (i = 0; i < arclist.length; i++) { 
        if(arclist[i].length > 0){
            var splitLine = arclist[i].unquoted().split("\",\"");
            var arcNum = padDigits(i+1,2);
            buildElement(splitLine[0],splitLine[1],splitLine[2],arcNum+" - "+splitLine[3],i+1);    
        } else {
            console.log("Issue "+(i+1)+" missing");
        }
    }
}

/* Registration functions */   
var serverSalt="d0809793df2c3be1a77a229781cfe1cdb1a2a"; /* shouldn't be unique as far as I can find */
function generateHash(username,password){
    $('#resultbox').val(username + ":" + hex_hmac_sha256(password,serverSalt));
}

function importUser(string){
    var username=string.split(":")[0];
    var passhash=string.split(":")[1];
    document.getElementById('cmd').value = 'cmd_createuser';
    document.getElementById('user').value = username;
    document.getElementById('hash').value = passhash;
    document.getElementById('editform').submit();
}

/* Everything setup for onLoad, since without the timeout sometimes it beats jquery to the punch */
setTimeout(function(){
    if(typeof Storage !== "undefined"){
        if (localStorage.getItem("Ubooquity_Bookmarks2") !== null) {
            Bookmarks=JSON.parse(localStorage.getItem("Ubooquity_Bookmarks2"));
        }
    }
    
    /* Remove bottom padding if there's no page selector */
    if ($('.currentpagenumber').is(':visible') === true) {
        $("#group").css("padding-bottom", "65px");
    } else {
        $("#group").css("padding-bottom", "10px");
    }
    
    /* Move page selector to the left side if there's no back button  */
    if ($("#arrowleft10").hasClass("hidden") &&  $("#arrowleft").hasClass("hidden")) {
        $("#pageselector").css("margin-left", "40px");
        if ($('.pagenumber').length < 3){
            $("#topbarright").css("margin-left", "115px");
        } else {
            $("#topbarright").css("margin-left", "156px");
        }
    }
        
    /* Add onHover button to add item to Bookmarks */    
    if(window.location.href.indexOf("bookmarks.htm") === -1){
        $(document).ajaxStop(function() {
            $(".cellcontainer").hover(
                function() {
                    $( this ).prepend( $( "<div id='addButton' onclick='storeElement($(this).parent().find(\".thumb a\").attr(\"href\"),$(this).parent().find(\".thumb a\").attr(\"onclick\"),$(this).parent().find(\".thumb a img\").attr(\"src\"),$(this).parent().find(\".label\").text());'></div>" ) );
                }, function() {
                    $( this ).find( "#addButton" ).remove();
                }
            );
        });     
    }
    
    /* Add Register link to login form, and Mobile button to everything except admin and files */
    if($('#loginform').length != 0){
        if($('#poweredby').length === 0){
            if(window.location.href.indexOf("/admin") === -1){
                $('body').prepend('<a href="'+proxyPrefix+'/theme/register.htm" id="registerLink">Register</a>');   
            }
            $('body').append('<a id="poweredby" href="http://vaemendis.net/ubooquity"></a>');
            document.getElementById('poweredby').setAttribute("style", "top: 0px; z-index: 10;");
        }
    } else {
        if((window.location.href.indexOf("/files/") === -1)&&(window.location.href.indexOf("/admin") === -1)){
            if($('#mobile').length === 0){
                $("body").append('<a href="'+proxyPrefix+'/theme/mobile.htm" id="mobile">MOBILE</a>');
                document.getElementById('mobile').setAttribute("style", "padding-left: 0px; width: 68px; padding-right: 1px;");
            }
        }
    }
    
    /* Add user info to top of page */
    if((window.location.href.indexOf("/files/") === -1)&&(window.location.href.indexOf("/admin") === -1)){
        if($('#userinfo2').length === 0){
            $("body").prepend('<div id="userinfo2"></div>');
        }
        $("#userinfo2").load( proxyPrefix+"/index.html #userinfo", function() {
            $( "#logoutlink" ).attr('href','../../?logout=true');
        });
    }
    
    /* Add Browse and New buttons, and copy #folderinfo to pages 2+ */
    if(window.location.href.indexOf("register") === -1){
        if($('#topbarcenter').length != 0){
            if($('#browsebutton').length === 0){
                $("#topbarcenter").append('<a href="'+proxyPrefix+'/comics/" id="browsebutton" class="topbutton">BROWSE</a>');
                document.getElementById('browsebutton').setAttribute("style", "padding-left: 1px; width: 65.5px; left: 122.5px; padding-right: 4px;");
            }
            if(($('#latest-comics').length === 0) && (window.location.href.indexOf("?latest=true") == -1)){
                $("#topbarcenter").append('<a id="latest-comics" href="'+proxyPrefix+'/comics/?latest=true">NEW</a>');
                document.getElementById('latest-comics').setAttribute("style", "padding-left: 0px; width: 61.5px; left: 60px;");
            }
            if((window.location.href.indexOf("?index=") != -1) && (window.location.href.indexOf("?index=0") == -1)){
                $('<div>').load(window.location.href.split("?index=")[0]+" #folderinfo", function() {
                    $("#group").prepend($(this).find("#folderinfo"));   
                    if($('#publisher').length != 0){
                        var a = document.getElementById('publisher');
                        a.href = document.getElementById('arrowup').href;
                    }
                    if($('#publisher2').length != 0){
                        var a = document.getElementById('publisher2');
                        a.href = document.getElementById('arrowup').href;
                    }
                });
            }
        }
    }
    
    /* Since page number buttons in search don't actually work */
    if(window.location.href.indexOf("?search=true") != -1){
        $("a.pagenumber").each(function() {
           var $this = $(this);       
           $this.attr('onClick','return false;');
        });
    }
    
    /* Add form to import strings from register page */
    if(window.location.href.indexOf("/admin/edit/security") != -1){
        var newForm = document.createElement("form");
        newForm.id = "importForm";
        newForm.action = "javascript:void(0);";
        var formHTML = "<input id='importMe'></input><button id='importButton'>Import</button>";
        document.getElementsByClassName('section')[0].appendChild(setInnerHTML(newForm, formHTML));
        document.getElementById("importButton").addEventListener('click',function (){
            importUser(document.getElementById('importMe').value);
        }); 
    }

    /* Replace " - " with colon */
    $(".label").text(function(index, text) {
        return text.replace(' - ', ': ');
    });
}, 0);

/* Prototypes and generic functions */
$.expr[':'].exact = $.expr.createPseudo(function(arg) {
    return function( elem ) {
        return $(elem).text().match("^" + arg + "$");
    };
});

String.prototype.unquoted = function (){return this.replace (/(^")|("$)/g, '')}

function padDigits(number, digits) {
    return Array(Math.max(digits - String(number).length + 1, 0)).join(0) + number;
}

function setInnerHTML(element, content) {
    element.innerHTML = content;
    return element;
} 