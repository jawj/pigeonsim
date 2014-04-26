// Start SSL Server
// Author:  Steven Gray

var fs = require('fs');
var express = require('express');
var https = require('https');
var key = fs.readFileSync('./keys/snakeoil.key');
var cert = fs.readFileSync('./keys/snakeoil.crt')
var https_options = {
    key: key,
    cert: cert
};
var PORT = 8443;
var HOST = 'localhost';
app = express();

app.configure(function(){
    app.use(app.router);
});

server = https.createServer(https_options, app).listen(PORT, HOST);
console.log('https server listening on https://%s:%s', HOST, PORT);

app.use(express.static(__dirname + '/../web_client'));
