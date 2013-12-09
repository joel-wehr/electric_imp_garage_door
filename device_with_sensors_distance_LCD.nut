//***************Distance Sensor***************

//************Screen class to manage the LCD*************
port0 <- hardware.uart1289;
port0.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS);
class Screen {
    port = null;
    constructor(_port) {
        port = _port;
    }
    function set_size(_columns, _rows) {
        port.write(0xFE);
        port.write(0xD1);
        port.write(_columns);
        port.write(_rows);
        server.log("Set LCD: " + _columns + "x" + _rows);
    }
    function set_contrast(_value) {
        port.write(0xFE);
        port.write(0x50);
        port.write(_value);
        //server.log("Contrast: " + _value);
    }
    function set_brightness(_value) {
        port.write(0xFE);
        port.write(0x99);
        port.write(_value);
        //server.log("Brightness: " + _value);
    }
    function set_color(_red, _green, _blue) {
        port.write(0xFE);
        port.write(0xD0);
        port.write(_red);
        port.write(_green);
        port.write(_blue);
    }
    function cursor_off() {
        port.write(0xFE);
        port.write(0x4B);
        port.write(0xFE);
        port.write(0x54);
    }
    function clear_screen() {
        port.write(0xFE);
        port.write(0x58);
        //server.log("Clear Screen");
    }
    function autoscroll_on() {
        port.write(0xFE);
        port.write(0x51);
    }
    function autoscroll_off() {
        port.write(0xFE);
        port.write(0x52);
    }
    function startup_message() {
        port.write(0xFE);
        port.write(0x40);
        port.write("**Your Startup*******Message****");
    }
    function cursor_at_line0() {
        port.write(0xFE);
        port.write(0x48);
    }
    function cursor_at_line1() {
        port.write(0xFE);
        port.write(0x47); 
        port.write(1);
        port.write(2);
    }
    function write_string(string) {
        foreach(i, char in string) {
            port.write(char);
        }
    }
}
//****************End Screen Class***********************
Distance <- 0;
DistanceState <- -1;

// Distance variables

DistanceMaxReadings <- 16;
DistanceAverage <- 0;
DistanceReadingsTotal <- 0;
DistanceReadings <- [];
function DistanceSensorEvent ()
{
    // Read the first byte from the buffer
    //  Dec 82 = Chr "R" | Dec 13 = Carriage Return
    local DistanceByte = DistanceSensor.read ();
    
    // Cycle round until we've emptied the buffer
    
    while (DistanceByte != -1) {
        //server.log(DistanceByte.tochar());
        
        ProcessDistanceByte (DistanceByte);
        DistanceByte = DistanceSensor.read();
    }
}

function ProcessDistanceByte (DistanceByte)
{
    switch (DistanceState) {
    case -1:
        if (DistanceByte == 'R') {
            //server.log("Got an R");
            DistanceState = 0;
        }
        break;
    
    case 0: // 100's
        Distance = (DistanceByte - '0') * 100;
        DistanceState++;
        break;
    
    case 1: // 10's
        Distance += (DistanceByte - '0') * 10;
        DistanceState++;
        break;
    
    case 2: // 1's
        Distance += (DistanceByte - '0');
        
        // We have the distance from the sensor
        // Have we got the minimum number of readings yet ?
        
        if (DistanceReadings.len () == DistanceMaxReadings) { // Yes
        
            // Remove the oldest reading, make room for a more recent one
            
            DistanceReadingsTotal -= DistanceReadings[0]
            DistanceReadings.remove (0)
        }

        // Calculate the new reading
        
        DistanceReadingsTotal += Distance
        DistanceReadings.append (Distance)
        
        // Recompute
        
        DistanceAverage = (DistanceReadingsTotal / DistanceReadings.len ()).tointeger ()
        //server.log("Distance = " + DistanceAverage + "in");
        if (DistanceAverage <= 52) {
            screen.set_color(255,0,0);
            //rgbChange(255,0,0);
            //server.log("Red");
        }
        else if (DistanceAverage >= 53 && DistanceAverage <= 56) {
            screen.set_color(0,255,0);
            //rgbChange(0, 255, 0);
            //server.log("Green");
        }
        else {
            screen.set_color(0,0,255);
            //rgbChange(255, 255, 0);
            //server.log("Yellow");
        }
        screen.clear_screen();
        screen.cursor_at_line0();
        screen.write_string("Distance: " + DistanceAverage + "in");
        DistanceState = -1;  // reSync
        break;
    }
}
DistanceSensor <- hardware.uart57;
DistanceSensor.configure (9600,8,PARITY_NONE,1,NO_TX,DistanceSensorEvent);
//**************End Distance Sensor************


doorState <- "unset";
respondHTTP <- false;
ID <- hardware.getimpeeid();
function checkDoor() {  
    if (hardware.pin1.read() == 1 && hardware.pin2.read() == 1){
        doorState = "open"; // Both open, door is open
    }
    else if (hardware.pin1.read() == 0 && hardware.pin2.read() == 0) {
        doorState = "closed"; // Both closed, door is closed
    }
    else {
        doorState = "partially open";
    }
    agent.send("doorState", doorState);
    //return doorState;
}
agent.on("toggleDoor", function(data) {
    server.log("Received request: " + data);
    respondHTTP = true;
    hardware.pin9.write(1);
    imp.sleep(1);
    hardware.pin9.write(0);
}); 
function pin2Changed() {
    checkDoor();
    if (doorState == "open" && respondHTTP == true) {
        server.log("Door open.");
        agent.send("doorToggled", doorState);
    }    
}
function pin1Changed() {
    checkDoor();
    if (doorState == "closed" && respondHTTP == true) {
        server.log("Door Closed.");
        agent.send("doorToggled", doorState);
    }      
}
hardware.pin1.configure(DIGITAL_IN_PULLUP, pin1Changed); //Door is down switch 
hardware.pin2.configure(DIGITAL_IN_PULLUP, pin2Changed); //Door is up switch

hardware.pin9.configure(DIGITAL_OUT);

imp.configure("Garage Door", [], []);
screen <- Screen(port0);
screen.set_contrast(200);
screen.clear_screen();
screen.cursor_at_line0();
checkDoor();
