function isScriptAlreadyIncluded(src){
    var scripts = document.getElementsByTagName("script");
    for(var i = 0; i < scripts.length; i++) 
       if(scripts[i].getAttribute('src') == src) return true;
    return false;
}

var proxyPrefix = "/ubooquity"; /* blank if no proxy */

function runMe(){
    if((!isScriptAlreadyIncluded('../../theme/jquery-3.1.1.min.js')) && (!isScriptAlreadyIncluded('jquery-3.1.1.min.js'))){
        loadScript(proxyPrefix+"/theme/jquery-3.1.1.min.js", function(){
            loadScript(proxyPrefix+"/theme/theme.js", function(){
                /*console.log("injected");*/
            });
        });
    }
}