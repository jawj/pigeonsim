// To Install Modules needed run: 
//  npm install galileo-io ws

//Running on Galileo == 1, testing on computer == 0;
var boardRun = 0;

if(boardRun){
    var Galileo = require('galileo-io')
    var board = new Galileo();
}

var WebSocket = require('ws')

var PWMmapping = {
    "3": 3,
    "5": 5,
    "6": 6,
    "9": 1,
    "10": 7,
    "11": 4
}

var LEDpin = 7;

var LEDPin_R = PWMmapping['5'];
var LEDPin_G = PWMmapping['6'];
var LEDPin_B = PWMmapping['9'];

var rightFanPWM = PWMmapping['3'];
var leftFanPWM = PWMmapping['3'];

var fanSelectLeft = 2;
var fanSelectRight = 4;

var fanMap = 0; // 1 == Left, 2 = Right, 0 = None


if(boardRun){
    board.on("ready", function() {
        var byte = 0;

        //Set Fan Output
        this.pinMode(rightFanPWM, this.MODES.OUTPUT);
        this.pinMode(leftFanPWM, this.MODES.OUTPUT);

        // Set Fan Select switches
        this.pinMode(fanSelectLeft, this.MODES.INPUT);
        this.pinMode(fanSelectRight, this.MODES.INPUT);

        // Set single LED
        this.pinMode(LEDpin, this.MODES.OUTPUT);

        //Set RGB LED
        this.pinMode(LEDPin_R, this.MODES.OUTPUT);
        this.pinMode(LEDPin_G, this.MODES.OUTPUT);
        this.pinMode(LEDPin_B, this.MODES.OUTPUT);

        // Board Startup -- Yellow
        setRGBLED(255,255,0)

        wsRegisterEvents(board);
    });
}else{
    wsRegisterEvents(undefined);
}

function setRGBLED(r, g, b){
    board.analogWrite(LEDPin_R, r);
    board.analogWrite(LEDPin_G, g);
    board.analogWrite(LEDPin_B, b);
}

function flashRGBLed(r, g, b, duration, times){
    // TODO:  Flash x times
    setRGBLED(0, 0, 0);
    setTimeout(function(){
        setRGBLED(r, g, b);
        setTimeout(function(){
            setRGBLED(0, 0, 0);
        }, duration);
    }, duration);
}

function wsRegisterEvents(board){
    //On ready and connected to server!
    ws = new WebSocket('ws://127.0.0.1:8888/p5websocket');
    ws.on('open', function() {
        console.log("Connected to the FanController");
        if(board != undefined){
            board.digitalWrite(LEDpin, 1);
            setRGBLED(0, 255, 0); // On Green

            board.digitalRead(fanSelectLeft, function(data) {
                if(data == 1){
                    fanMap = 1;
                }      
            });

            board.digitalRead(fanSelectRight, function(data) {
                if(data == 1){
                    fanMap = 2;
                }      
            });
        }
    });

    ws.on('close', function() {
        console.log("Server has closed connection");
        if(board != undefined){
            board.digitalWrite(LEDpin, 0);
            setRGBLED(255, 0, 0); // On Red
        }
    });

    ws.on('message', function(message) {
        message = JSON.parse(message);
        if(message.reset == 1 || message.reset == 2){
            console.log("RESET: Switching Fans off! \tMode:" + message.reset);
            if(board != undefined){
                board.analogWrite(leftFanPWM, 0);
                board.analogWrite(rightFanPWM, 0);
            }
        }

        if(message.roll != 0){
            if(message.roll > 0){
                console.log("Fan Left On: " + message.roll);
                if(board != undefined){
                    if(fanMap == 1){
                        board.analogWrite(leftFanPWM, 255);
                    }else{
                        board.analogWrite(rightFanPWM, 0); //Turn off right fan when going right
                    }
                }
            }
            
            if(message.roll < 0){
                console.log("Fan Right On: " + message.roll);
                if(board != undefined){
                    if(fanMap == 2){
                        board.analogWrite(rightFanPWM, 255);
                    }else{
                        board.analogWrite(leftFanPWM, 0);  //Turn off left fan when going right
                    }
                }
            }
        
        }else{
            console.log("Straight Flight Both Fans On")
            if(board != undefined){
                board.analogWrite(leftFanPWM, 50);
                board.analogWrite(rightFanPWM, 50);
            }
        }
    });
}
