const express = require("express");
const WebSocketio = require("socket.io");
const http = require("http");

const app = express();

app.use(express.urlencoded({ extended: false }));
app.use(express.json());

const server = http.createServer(app);
const io = socketio(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"],
    },
});

//Cors Handling
app.use((req, res, next) => {
    res.header("Access-Control-Allow-Origin", "*");
    res.header(
    "Access-Control-Allow-Headers",
    "Origin,X-Requested-With,Content-Type,Accept,Authorization"
    );
    if (req.method === "OPTIONS") {
        res.header ("Access-Control-Allow-Methods", "PUT, POST, PATCH, DELETE, GET");
        return res.status(200).json({});
    }
    next();
});

app.get("/", (req, res) => {
    const responseData = {
     message: "Hello World!",
    };
    return res.json (responseData); // Sending JSON response
}) ;
    
app.use((req, res, next) => {
    const error = new Error("Not found");
    error.status = 404;
    next (error);
});

app.use((error, req, res, next) => {
    res.status(error.status || 500);
    res.json({
        error: {
            message: error.message,
        },
    });
});

io.on("connection", (socket) => {
    console.log(socket.id, "has connected");
    socket.emit("messageFromServer", { data: "Connected to server" });

    socket.on("messageFromClient", (data) => {
        console.log("data is ", data);

        io.emit("messageFromServer", { data: data.data });
    });
});

const PORT = process.env.PORT || 8080;

// Start the server
server.listen(port, async () => {
    console.log(`Server listening on ${port}`);
});
