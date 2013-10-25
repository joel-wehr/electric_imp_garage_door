//*************************TWILIO***********************************************
//The Twilio code is used to alert you via SMS if an unauthorized access to your
//Imp is made. It is not necessary for door control, and is just an added feature.
const TWILIO_ACCOUNT_SID = "" //Your SID 
const TWILIO_AUTH_TOKEN = ""  //Your Auth Token
const TWILIO_FROM_NUMBER = "+17175551212" // your phone no goes here
const TWILIO_TO_NUMBER = "+17175551212" // destination phone no

function send_sms(number, message) {
    local twilio_url = format("https://api.twilio.com/2010-04-01/Accounts/%s/SMS/Messages.json", TWILIO_ACCOUNT_SID);
    local auth = "Basic " + http.base64encode(TWILIO_ACCOUNT_SID+":"+TWILIO_AUTH_TOKEN);
    local body = http.urlencode({From=TWILIO_FROM_NUMBER, To=number, Body=message});
    local req = http.post(twilio_url, {Authorization=auth}, body);
    local res = req.sendsync();
    if(res.statuscode != 201) {
        server.log("error sending message: "+res.body);
    }
}
//*****************************END TWILIO***************************************
apiKey <- "" //Your API Key
doorState <- "unset";
// Respond to incoming HTTP commands
http.onrequest(function(request, response) { 
  try {
    local data = http.jsondecode(request.body);
    server.log("Received: " + request.body);
    if ("api-key" in request.headers && request.headers["api-key"] == apiKey) {
        server.log(request.headers["api-key"]);
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
            local json = "{ \"status\" : { \"doorState\" : \"Missing Data in Body\" }}";
            response.send(500, json);
        }   
    }
    else {
        local json = "{ \"status\" : { \"doorState\" : \"Unauthorized\" }}";
        response.send(401, json);
        //Uncomment the line below if you have a Twilio account set up
        //and wish to use it to monitor unauthorized access.
        //send_sms(TWILIO_TO_NUMBER, "Unauthorized access to Security System attempted.");
    }
  }
  catch (ex) {
    response.send(500, "Internal Server Error: " + ex);
  }
});
device.on("doorState", function(data) {
    doorState = data;
});
