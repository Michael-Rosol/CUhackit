import socket
import threading

# Server
def handle_client(client_socket, address):
    print(f"Accepted connection from {address}")
    while True:
        try:
            message = client_socket.recv(1024).decode('utf-8')
            if not message:
                break
            print(f"Client: {message}")
            response = input("Message: ")
            client_socket.send(response.encode('utf-8'))
        except ConnectionResetError:
            print(f"Connection with {address} closed.")
            break
    client_socket.close()

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    host = '127.0.0.1'
    port = 12345
    server_socket.bind((host, port))
    server_socket.listen(5)
    print(f"Server listening on {host}:{port}")

    while True:
        client_socket, address = server_socket.accept()
        client_thread = threading.Thread(target=handle_client, args=(client_socket, address))
        client_thread.start()

# Client
def start_client():
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    host = '127.0.0.1'
    port = 12345
    try:
        client_socket.connect((host, port))
        print(f"Connected to {host}:{port}")
        while True:
            message = input("Message: ")
            client_socket.send(message.encode('utf-8'))
            response = client_socket.recv(1024).decode('utf-8')
            print(f"Server: {response}")
    except ConnectionRefusedError:
        print("Server is not running. Please start the server first.")
    finally:
        client_socket.close()

if __name__ == "__main__":
    server_or_client = input("Run as server (s) or client (c)? ").lower()
    if server_or_client == 's':
        start_server()
    elif server_or_client == 'c':
        start_client()
    else:
        print("Invalid input. Please enter 's' or 'c'.")