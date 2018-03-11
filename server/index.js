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

hifi.connect(23, 'kitchen-radio', function() {
    console.log('Connected to Hifi');
});

hifi.on('close', function() {
    console.log('Closed connection to Hi-fi');
});

hifi.on('data', function(data) {
    console.log('Incoming: ' + data);
    wss.clients.forEach(function each(client) {
        if (client.readyState === WebSocket.OPEN) {
            client.send(data);
        }
    });
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