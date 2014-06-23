// To Install Modules needed run: 
//  npm install galileo-io ws

//Running on Galileo == 1, testing on computer == 0;
var boardRun = 1;

var fanSelectOverride = 1;

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

var lowSpeedPWM = PWMmapping['3'];
var highSpeedPWM = PWMmapping['5'];

var fanSelectLeft = 13;
var fanSelectRight = 4;

var fanMap = 0; // 1 == Left, 2 = Right, 0 = None


if(boardRun){
    board.on("ready", function() {
        var byte = 0;
        console.log("Board Started.");

        //Set Fan Output
        this.pinMode(lowSpeedPWM, this.MODES.OUTPUT);
        this.pinMode(highSpeedPWM, this.MODES.OUTPUT);

        // Set Fan Select switches
        this.pinMode(fanSelectLeft, this.MODES.INPUT);
        this.pinMode(fanSelectRight, this.MODES.INPUT);

        // Set single LED
        this.pinMode(LEDpin, this.MODES.OUTPUT);

        //Set RGB LED
        //this.pinMode(LEDPin_R, this.MODES.OUTPUT);
        //this.pinMode(LEDPin_G, this.MODES.OUTPUT);
        //this.pinMode(LEDPin_B, this.MODES.OUTPUT);

        // Board Startup -- Yellow
        setRGBLED(255,255,0)

        wsRegisterEvents(board);
    });
}else{
    wsRegisterEvents(undefined);
}

function setRGBLED(r, g, b){
    //board.analogWrite(LEDPin_R, r);
    //board.analogWrite(LEDPin_G, g);
    //board.analogWrite(LEDPin_B, b);
    return true;
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
    console.log("Connecting to Server ...");
    ws = new WebSocket('ws://192.168.1.2:8888/p5websocket');
    ws.on('open', function() {
        console.log("Connected to the FanController");
        if(board != undefined){
            console.log("Setting Pins Low");
            board.digitalWrite(LEDpin, 1);
            board.analogWrite(lowSpeedPWM, 0);
            board.analogWrite(highSpeedPWM, 0);

            board.digitalRead(fanSelectLeft, function(data) {
                //console.log("L" + "\tP " + fanSelectLeft + "\tD " + data);
                if(data == 1 && fanSelectOverride == 0){
                    fanMap = 1;
                }   
            });

            board.digitalRead(fanSelectRight, function(data) {
                //console.log("R" + "\tP " + fanSelectRight + "\tD " + data);
                if(data == 1 && fanSelectOverride == 0){
                    fanMap = 2;
                }      
            });

            if(fanSelectOverride != 0){
                fanMap = fanSelectOverride; 
            }

            // Read Fan Select State for console. 
            setTimeout(function(){
                if(fanMap == 1){
                    console.log("We're the Left Fan ...");
                }else if(fanMap == 2){
                    console.log("We're the Right Fan ...");
                }
            }, 1000);
        }
    });

    ws.on('close', function() {
        console.log("Server has closed connection");
        if(board != undefined){
            board.digitalWrite(LEDpin, 0);
            board.analogWrite(lowSpeedPWM, 0);
            board.analogWrite(highSpeedPWM, 0);
            setRGBLED(255, 0, 0); // On Red
        }
    });

    ws.on('message', function(message) {
        message = JSON.parse(message);
        if(message.reset == 1 || message.reset == 2){
            console.log("RESET: Switching Fans off! \tMode:" + message.reset);
            if(board != undefined){
                board.analogWrite(highSpeedPWM, 0);
                board.analogWrite(lowSpeedPWM, 0);
            }
        }

        if(message.roll != 0){
            if(message.roll > 0){
                console.log("Fan Left On: " + message.roll);
                if(board != undefined){
                    if(fanMap == 1){
                        console.log("Setting P" + highSpeedPWM + " high.");
                        board.analogWrite(highSpeedPWM, 255);
                    }else{
                        board.analogWrite(highSpeedPWM, 0); //Turn off right fan when going right
                    }
                }
            }
            
            if(message.roll < 0){
                console.log("Fan Right On: " + message.roll);
                if(board != undefined){
                    if(fanMap == 2){
                        console.log("Setting R P" + highSpeedPWM + " high.");
                        board.analogWrite(highSpeedPWM, 255);
                    }else{
                        board.analogWrite(highSpeedPWM, 0);  //Turn off left fan when going right
                    }
                }
            }
        
        }else{
            console.log("Straight Flight Both Fans On")
            if(board != undefined){
                console.log("Setting P" + highSpeedPWM + " low.");
                board.analogWrite(highSpeedPWM, 0);
                board.analogWrite(lowSpeedPWM, 255);
            }
        }
    });
}
