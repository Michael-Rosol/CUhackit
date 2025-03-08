const express = require('express');
const http = require('http');
const WebSocket = require('ws');

const app = express();
const server = http.createServer(app);

// Create WebSocket server
const wss = new WebSocket.Server({ server });

// Serve static files (like HTML, CSS, JS)
app.use(express.static("public"));

// Handle WebSocket connections
wss.on('connection', ws => {
    console.log('A new client connected');
    
    // Send a message to the client every 5 seconds (just for demonstration)
    setInterval(() => {
        const message = 'Hello from WebSocket server!';
        ws.send(message);
    }, 5000);

    // Handle messages from the client
    ws.on('message', message => {
        console.log('Received message:', message);
    });

    // Handle WebSocket closure
    ws.on('close', () => {
        console.log('Client disconnected');
    });
});

// Start the server
server.listen(8080, () => {
    console.log('Server is running on http://localhost:8080');
});
