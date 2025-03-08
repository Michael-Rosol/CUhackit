import CoreMotion
import UIKit
import MessageUI

class ViewController: UIViewController, MFMessageComposeViewControllerDelegate, URLSessionWebSocketDelegate {

    let manager = CMMotionManager()
    var socket: URLSessionWebSocketTask?
    
    // IBOutlet connected to your label in Interface Builder
    @IBOutlet var accelerometerLabel: UILabel!
    
    // Button to send the message
    var sendMessageButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customize the accelerometer label's appearance
        styleLabel()
        connectSocket()
        
        // Customize and add the send message button
        setupSendMessageButton()
        
        // Start accelerometer updates
        manager.accelerometerUpdateInterval = 0.1
        manager.startAccelerometerUpdates()

        // Timer to update the label every second with accelerometer data
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let data = self.manager.accelerometerData {
                // Update the label text with accelerometer data
                self.accelerometerLabel.text = String(format: "x: %.2f, y: %.2f, z: %.2f",
                                                      data.acceleration.x,
                                                      data.acceleration.y,
                                                      data.acceleration.z)
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.sendToServer()
        }
    }

    // Function to style the accelerometer label
    private func styleLabel() {
        // Set the label's size and position
        accelerometerLabel.frame = CGRect(x: 0, y: 0, width: 320, height: 80)
        
        // Center the label in the middle of the screen
        accelerometerLabel.center = self.view.center
        
        // Set the text color
        accelerometerLabel.textColor = .white
        
        // Set the text alignment to center
        accelerometerLabel.textAlignment = .center
        
        // Customize the font and size
        accelerometerLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        
        // Add rounded corners and padding inside the label
        accelerometerLabel.layer.masksToBounds = true
        accelerometerLabel.layer.cornerRadius = 15
        
        // Set a background color with some transparency
        accelerometerLabel.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
        
        // Add a subtle shadow to the label (moved outside masksToBounds)
        accelerometerLabel.layer.shadowColor = UIColor.black.cgColor
        accelerometerLabel.layer.shadowOffset = CGSize(width: 2, height: 2)
        accelerometerLabel.layer.shadowOpacity = 0.7
        accelerometerLabel.layer.shadowRadius = 5
        
        // Add the label to the main view
        self.view.addSubview(accelerometerLabel)
    }
    
    // Function to setup the send message button
    private func setupSendMessageButton() {
        // Create the button programmatically
        sendMessageButton = UIButton(type: .system)
        
        // Set the button's title
        sendMessageButton.setTitle("Send Message", for: .normal)
        
        // Set the button's frame (position and size)
        sendMessageButton.frame = CGRect(x: 50, y: self.view.frame.height - 150, width: 220, height: 50)
        
        // Set the button's background color and corner radius
        sendMessageButton.backgroundColor = .systemGreen
        sendMessageButton.layer.cornerRadius = 10
        
        // Set the button's title color
        sendMessageButton.setTitleColor(.white, for: .normal)
        
        // Add the action to the button
        sendMessageButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        // Add the button to the main view
        self.view.addSubview(sendMessageButton)
    }
    
    func connectSocket() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        // Fixed WebSocket URL to use secure connection with proper port
        guard let url = URL(string: "ws://198.21.167.172:8080/") else {
            print("Invalid WebSocket URL")
            return
        }
        
        socket = session.webSocketTask(with: url)
        socket?.resume()
        
        // Set up receive message handler
        receiveMessage()
    }
    
    // Function to handle incoming messages
    func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    print("Unknown message type received")
                }
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                print("Failed to receive message: \(error)")
                
                // Attempt to reconnect after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.connectSocket()
                }
            }
        }
    }
    
    func sendToServer() {
        // Include accelerometer data in the message
        var message = "Hello Jack"
        
        if let data = self.manager.accelerometerData {
            message = String(format: "Accelerometer Data: x: %.2f, y: %.2f, z: %.2f",
                            data.acceleration.x,
                            data.acceleration.y,
                            data.acceleration.z)
        }
        
        socket?.send(.string(message)) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error sending data to WebSocket: \(error)")
                // Wait briefly before trying to reconnect
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.connectSocket()
                }
            } else {
                print("Successfully sent: \(message)")
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connection established")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket connection closed")
        
        // Reconnect if the connection closes, with a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.connectSocket()
        }
    }
    
    @objc func sendMessage() {
        // Check if the device can send SMS
        if MFMessageComposeViewController.canSendText() {
            let messageComposeVC = MFMessageComposeViewController()
            messageComposeVC.messageComposeDelegate = self

            // Retrieve the latest accelerometer data
            if let accelerometerData = manager.accelerometerData {
                let messageBody = String(format: "Accelerometer Data:\nX: %.2f\nY: %.2f\nZ: %.2f",
                                         accelerometerData.acceleration.x,
                                         accelerometerData.acceleration.y,
                                         accelerometerData.acceleration.z)
                messageComposeVC.body = messageBody
            } else {
                messageComposeVC.body = "Accelerometer data is unavailable."
            }

            // Present the message compose view controller
            self.present(messageComposeVC, animated: true, completion: nil)
        } else {
            // Show an alert if SMS cannot be sent
            let alert = UIAlertController(title: "Error",
                                         message: "SMS services are not available on this device.",
                                         preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // Message Compose View Controller Delegate Method
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        // Dismiss the message compose view controller
        controller.dismiss(animated: true)
    }
    
    // Clean up resources when view is about to disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop accelerometer updates to save battery
        manager.stopAccelerometerUpdates()
        
        // Close socket connection
        socket?.cancel(with: .goingAway, reason: nil)
    }
}
