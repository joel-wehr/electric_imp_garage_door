const html = @"<!DOCTYPE html>
<html lang=""en"">
    <head>
        <meta charset=""utf-8"">
        <meta name=""viewport"" content=""width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"">
        <meta name=""apple-mobile-web-app-capable"" content=""yes"">
            
        <script src=""http://code.jquery.com/jquery-1.9.1.min.js""></script>
        <script src=""http://code.jquery.com/jquery-migrate-1.2.1.min.js""></script>
        <script src=""http://d2c5utp5fpfikz.cloudfront.net/2_3_1/js/bootstrap.min.js""></script>
        
        <link href=""//d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap.min.css"" rel=""stylesheet"">
        <link href=""//d2c5utp5fpfikz.cloudfront.net/2_3_1/css/bootstrap-responsive.min.css"" rel=""stylesheet"">

        <title>Garage Door</title>
    </head>
    <body>
        <script type=""text/javascript"">
            function sendToImp(value){
                if (window.XMLHttpRequest) {devInfoReq=new XMLHttpRequest();}
                else {devInfoReq=new ActiveXObject(""Microsoft.XMLHTTP"");}
                try {
                    devInfoReq.open('POST', document.URL, false);
                    devInfoReq.send(value);
                } catch (err) {
                    console.log('Error parsing device info from imp');
                }
            }
            function toggle(){
                sendToImp(document.getElementById('password').value);
            }
        </script>
        <div class='container'>
            <div class=''>
                
            </div>
            <div class='well' style='max-width: 320px; margin: 0 auto 10px; height:280px; font-size:22px;'>
            <h1 class='text-center'>Garage Door</h1>
            <h3 class='text-center'>Enter Authorization Code:</hr3>
            <input id='password' type='text' name='password' style='width:94%;'>
            <button style='width:100%; height:30%; margin-bottom:10px; margin-top:10px;' class='btn btn-primary btn-large btn-block' onclick='toggle()'><h1>Open/Close</h1></button>
            
            
            </div>
        </div>
    </body>
</html>";
//****************************END HTML******************************************
//*************************TWILIO***********************************************
const TWILIO_ACCOUNT_SID = ""
const TWILIO_AUTH_TOKEN = ""
const TWILIO_FROM_NUMBER = "" // your phone no goes here
const TWILIO_TO_NUMBER = "" // destination phone no

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
apiKey <- ""
doorState <- "unset";
password <- "";
// Respond to incoming HTTP commands
http.onrequest(function(request, response) { 
    server.log("Incoming request: " + request.body);
    if (request.body == "") {
        response.send(200, html);
    }
    else if (request.body == password) {
        device.send("toggleDoor", "Toggle Door.");
        device.on("doorToggled", function(data) {
            doorState = data;
            local json = "{ \"status\" : { \"doorState\" : \"" + doorState + "\" }}";
            server.log("Response: " + json);
            response.send(200, json);
        });
    }
    else {
        try {
            local data = http.jsondecode(request.body);
            //server.log("Received: " + request.body);
            if ("api-key" in request.headers && request.headers["api-key"] == apiKey) {
                //server.log(request.headers["api-key"]);
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
                    server.log("Response: " + json);
                    response.send(500, json);
                }   
            }
            else {
                local json = "{ \"status\" : { \"doorState\" : \"Unauthorized\" }}";
                response.send(401, json);
                send_sms(TWILIO_TO_NUMBER, "Unauthorized access to Garage Door attempted.");
            }
         }
        catch (ex) {
            response.send(500, "Internal Server Error: " + ex);
        }
    }
});
device.on("doorState", function(data) {
    doorState = data;
});
