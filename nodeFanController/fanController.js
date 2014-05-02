var WebSocket = require('ws')

var lowPower = 2;
var maxPower = 10;

ws = new WebSocket('ws://127.0.0.1:8888/p5websocket');
ws.on('open', function() {
    console.log("Connected to the FanController");
});
ws.on('message', function(message) {
	message = JSON.parse(message);
    if(message.roll != 0){
    	if(message.roll > 0){
    		console.log("Fan Left On: " + message.roll);
    	}
    	if(message.roll < 0){
    		console.log("Fan Right On: " + message.roll);
    	}
    }else{
    	//console.log("Straight Flight Both Fans On:" + lowPower)
    }
});
