"use strict";
const express = require('express');
const http = require('http');
const net = require('net');
const WebSocket = require('ws');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });
const hifi = new net.Socket();

app.use(express.static(__dirname + '/../client'));

if (process.argv.length < 3) {
    console.log("Usage: " + process.argv[0] + " " + process.argv[1] + " (ip address)");
    process.exit(1);
}

hifi.setEncoding("utf8");
hifi.connect(23, process.argv[2], function() {
    console.log('Connected to Hifi');
});

hifi.on('close', function() {
    console.log('Closed connection to Hi-fi');
});

hifi.on('data', function(data) {
    var i, lines;

    lines = data.split('\r');
    for (i = 0; i < lines.length; i++) {
        if (!lines[i]) {
            continue
        }
        console.log('Incoming: ' + lines[i]);
        wss.clients.forEach(function each(client) {
            if (client.readyState === WebSocket.OPEN) {
                client.send(lines[i]);
            }
        });
    }
});

wss.on('connection', function connection(ws) {
    console.log('Reconnected');

    ws.on('message', function incoming(message) {
        console.log('Sending ' + message);
        hifi.write(message + '\r');
    });
});

server.listen(8888, function listening() {
    console.log('Listening on %d', server.address().port);
});