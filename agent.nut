doorState <- "unset";
// Respond to incoming HTTP commands
http.onrequest(function(request, response) { 
  try {
    local data = http.jsondecode(request.body);
    server.log("Received: " + request.body);
    if (data.action == "status") {
        local json = "{ \"status\" : { \"doorState\" : \"" + doorState + "\" }}";
        server.log("Response: " + json);
        response.send(200, json);      
    } 
    else if (data.action == "toggle") {
        device.send("toggleDoor", data.action);
        device.on("doorToggled", function(data) {
        doorState = data;
        local json = "{ \"status\" : { \"doorState\" : \"" + doorState + "\" }}";
        server.log("Response: " + json);
        response.send(200, json);
        });       
    }
   else {
       server.log(request.body);
        response.send(500, "Missing Data in Body");
   }     
  }
  catch (ex) {
    response.send(500, "Internal Server Error: " + ex);
  }
});
device.on("doorState", function(data) {
    doorState = data;
});
