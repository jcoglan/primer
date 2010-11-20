(function() {
  window.PRIMER_CHANNELS = window.PRIMER_CHANNELS || [];
  
  var BAYEUX_CLIENT = null;
  
  var script = document.createElement('script'),
      head   = document.getElementsByTagName('head')[0];
  
  script.type = 'text/javascript';
  script.src  = '/primer/bayeux.js';
  
  script.onload = script.onreadystatechange = function() {
    var state = script.readyState;
    if (!state || state === 'loaded' || state === 'complete') {
      script.onload = script.onreadystatechange = null;
      head.removeChild(script);
      connect();
    }
  };
  head.appendChild(script);
  
  var connect = function() {
    BAYEUX_CLIENT = new Faye.Client('/primer/bayeux');
    var i = PRIMER_CHANNELS.length;
    while (i--) listen(PRIMER_CHANNELS.pop());
  };
  
  var listen = function(channel) {
    BAYEUX_CLIENT.subscribe(channel, function(message) {
      var node = document.getElementById(message.dom_id);
      if (node) node.innerHTML = message.content;
    });
  };
})();

