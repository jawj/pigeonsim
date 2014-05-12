// To Install Modules needed run: 
//  npm install galileo-io ws

//Running on Galileo == 1, testing on computer == 0;
var boardRun = 0;

if(boardRun){
    var Galileo = require('galileo-io')
    var board = new Galileo();
}

var WebSocket = require('ws')

var lowPower = 2;
var maxPower = 10;

var PWMmapping = {
    "3": 3,
    "5": 5,
    "6": 6,
    "9": 1,
    "10": 7,
    "11": 4
}

var LEDpin = 9;

var rightFanPWM = PWMmapping['3'];
var leftFanPWM = PWMmapping['5'];

if(boardRun){
    board.on("ready", function() {
        var byte = 0;
        this.pinMode(LEDpin, this.MODES.OUTPUT);
        this.pinMode(rightFanPWM, this.MODES.OUTPUT);
        this.pinMode(leftFanPWM, this.MODES.OUTPUT);

        wsRegisterEvents(board);
    });
}else{
    wsRegisterEvents(undefined);
}


function wsRegisterEvents(board){
    //On ready and connected to server!
    ws = new WebSocket('ws://127.0.0.1:8888/p5websocket');
    ws.on('open', function() {
        console.log("Connected to the FanController");
        if(board != undefined){
            board.digitalWrite(LEDpin, 1);
        }
    });

    ws.on('close', function() {
        console.log("Server has closed connection");
        if(board != undefined){
            board.digitalWrite(LEDpin, 0);
        }
    });

    ws.on('message', function(message) {
        message = JSON.parse(message);
        if(message.roll != 0){
        
            if(message.roll > 0){
                console.log("Fan Left On: " + message.roll);
                if(board != undefined){
                    board.analogWrite(leftFanPWM, 255);
                }
            }
            
            if(message.roll < 0){
                console.log("Fan Right On: " + message.roll);
                if(board != undefined){
                    board.analogWrite(rightFanPWM, 255);
                }
            }
        
        }else{
            //console.log("Straight Flight Both Fans On:" + lowPower)
            if(board != undefined){
                board.analogWrite(leftFanPWM, 50);
                board.analogWrite(rightFanPWM, 50);
            }
        }
    });
}