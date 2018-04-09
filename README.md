# Marantz MCR-611 web control

Control a Marantz MCR-611 (and probably many others) via. a webpage.

The server component also acts as a multiplexer; the device telnet port only accepts one connection at a time, this will recieve commands and broadcast responses to all clients.

## Prerequisites

The server half is written in nodejs, and we use npm to fetch clientside code:

    apt install npm nodejs

## Installation

Fetch required modules:

    npm install

## Running

Start the server with:

    nodejs server/index.js

Now visit http://localhost:8888 or so.

## Documentation

The protocol used is the "D&M SYSTEM control protocol", for which various PDFs and spreadsheets can be found.
There doesn't seem to be a link for this model (or one that mentions Europe DAB control), instead the information has been pieced together from others.
