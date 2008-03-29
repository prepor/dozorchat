function CanHasChat(url, polling, frequency){
    this.name = "CanHasChatObject";
    this.polling = polling;
    this.frequency = frequency;
    this.url = url;
    this.messageQueue = [];
    this.presenceQueue = [];
    this.rosterQueue = [];
    this.errorQueue = [];
};

CanHasChat.getInstance = function(url, polling, frequency){
    if(CanHasChat.instance==null){
        CanHasChat.instance = new CanHasChat(url, polling, frequency);
    }
    return CanHasChat.instance;
}

CanHasChat.prototype.init = function(){
    if(this.polling){
        this._poller = new PeriodicalExecuter(this.spawnRequest.bindAsEventListener(this),
                                this.frequency);
    } else {
        this.spawnRequest();
    }
};

CanHasChat.prototype.addMessageCallback = function(cb){
    this.messageQueue.push(cb);
};

CanHasChat.prototype.addPresenceCallback = function(cb){
    this.presenceQueue.push(cb);
};

CanHasChat.prototype.addRosterCallback = function(cb){
    this.rosterQueue.push(cb);
};

CanHasChat.prototype.addErrorCallback = function(cb){
    this.errorQueue.push(cb);
};

CanHasChat.prototype.spawnRequest = function(){
    new Ajax.Request(this.url, { 
            onComplete: this.handleMessages.bindAsEventListener(this) 
        });
};

CanHasChat.prototype.handleMessages = function(request) {
    var evaluatedJson = eval(request.responseText);
    if(evaluatedJson != -1){
        for(var i=0;i<evaluatedJson.length;i++){
            var msg = evaluatedJson[i];
            msg["time"] = new Date(msg["time"] * 1000);
            this.doMessageQueue(msg, msg["type"]);
        }
        if(!this.polling){
            this.spawnRequest();
        }
    } else {
        // handle timed out chat
    }
};

CanHasChat.prototype.doMessageQueue = function(message, type) {
    var from = message["from"];
    var time = message["time"];
    var domain = message["domain"];
    var type = message["type"];
    var msg = message["message"];
    switch(type){
        case "MESSAGE":
            this.callQueue(this.messageQueue, time, from, msg, domain);
            break;
        case "ROSTER":
            for(var k in msg){
                for(var i=0;i<msg[k].length;i++){
                    this.callQueue(this.rosterQueue, time, from, msg[k][i], k);
                }
            }
            break;
        case "PRESENCE":
            this.callQueue(this.presenceQueue, time, from, msg, domain);
            break;
        case "ERROR":
            this.callQueue(this.errorQueue, time, from, msg, domain);
            break;
        default:
            // report whatever
            break;
    }
};

CanHasChat.prototype.callQueue = function(farray){
    var nargs = [];
    for(var i=1;i<arguments.length;i++){
        nargs.push(arguments[i]);
    }
    for(var i=0;i<farray.length;i++){
        farray[i].apply(window, nargs);
    }
};