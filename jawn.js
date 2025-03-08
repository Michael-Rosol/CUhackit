const express = require("express");
const http = require("http");
const WebSocket = require('ws'); // You'll need to install this: npm install ws
const app = express();

app.use(express.urlencoded({ extended: false }));
app.use(express.json());

// Cors Handling
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header(
    "Access-Control-Allow-Headers",
    "Origin,X-Requested-With,Content-Type,Accept,Authorization"
    );
    if (req.method === "OPTIONS") {
        res.header("Access-Control-Allow-Methods", "PUT, POST, PATCH, DELETE, GET");
        return res.status(200).json({});
    }
    next();
});

app.get("/", (req, res) => {
    const responseData = {
        message: "Hello World!",
    };
    return res.json(responseData);
});

app.use((req, res, next) => {
    const error = new Error("Not found");
    error.status = 404;
    next(error);
});

app.use((error, req, res, next) => {
    res.status(error.status || 500);
    res.json({
        error: {
            message: error.message,
        },
    });
});

const server = http.createServer(app);

// Create WebSocket server
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
    console.log('Client connected');
    
    // Send welcome message
    ws.send(JSON.stringify({ message: 'Connected to server' }));
    
    // Handle messages from clients
    ws.on('message', (message) => {
        console.log('Received:', message.toString());
        
        // Broadcast message to all connected clients
        wss.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(message.toString());
            }
        });
    });
    
    ws.on('close', () => {
        console.log('Client disconnected');
    });
});

const PORT = process.env.PORT || 8080;

// Start the server
server.listen(PORT, async () => {
    console.log(`Server listening on ${PORT}`);
});

/*
const fs = require('fs');
const https = require('https');

// Load SSL certificate and key
const options = {
  key: fs.readFileSync('path/to/private-key.pem'),
  cert: fs.readFileSync('path/to/certificate.pem')
};

// Create HTTPS server instead of HTTP
const server = https.createServer(options, app);
*/ 