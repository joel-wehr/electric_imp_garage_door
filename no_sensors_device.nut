agent.on("toggleDoor", function(data) {
    server.log("Received request: " + data);
    hardware.pin9.write(1);
    imp.sleep(1);
    hardware.pin9.write(0);
}); 
hardware.pin9.configure(DIGITAL_OUT);
imp.configure("Garage Door", [], []);
hardware.pin9.write(0); //Write Pin 9 LOW on Imp Boot.
