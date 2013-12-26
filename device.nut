respondHTTP <- false;
function checkDoor() {  
    if (hardware.pin8.read() == 1 && hardware.pin7.read() == 1){
        doorState = "open"; // Both open, door is open
    }
    else if (hardware.pin8.read() == 0 && hardware.pin7.read() == 0) {
        doorState = "closed"; // Both closed, door is closed
    }
    else {
        doorState = "partially open";
    }
    agent.send("doorState", doorState);
    return doorState;
}
agent.on("toggleDoor", function(data) {
    server.log("Received request: " + data);
    respondHTTP = true;
    hardware.pin9.write(1);
    imp.sleep(1);
    hardware.pin9.write(0);
}); 
function pin8Changed() {
    checkDoor();
    if (doorState == "open" && respondHTTP == true) {
        agent.send("doorToggled", doorState);
    }    
}
function pin7Changed() {
    checkDoor();
    if (doorState == "closed" && respondHTTP == true) {
        agent.send("doorToggled", doorState);
    }      
}
hardware.pin7.configure(DIGITAL_IN_PULLUP, pin7Changed); //Door is down switch 
hardware.pin8.configure(DIGITAL_IN_PULLUP, pin8Changed); //Door is up switch
hardware.pin9.configure(DIGITAL_OUT);
hardware.pin9.write(0);
server.log(checkDoor());
