//
//  MQTTController.swift
//  ChatAppAES
//
//  Created by quynb on 12/06/2022.
//

import UIKit
import MQTTClient

class MQTTController: UIViewController {
    
    @IBOutlet weak var messageInputField: UITextField!
    @IBOutlet weak var messagesLabel: UILabel!
    
    let server = "localhost"
    let port: UInt32 = 1883
    let subscriptionTopic = "messagesFromCroatia/#"
    let publishTopic = "messagesFromCroatia"
    
    private let session = MQTTSession()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createMqttSocketTransport()
        connectToMqtt()
    }
    
    @IBAction func onSubmitClicked(_ sender: Any) {
        if let message = messageInputField.text {
            clearInputField()
            sendMessage(message)
        } else {
            displayAlert("Info", message: "Please write some messages")
        }
    }
    
}

/**
 Constains MQTT-related methods
 */
extension MQTTController: MQTTSessionDelegate{
    
    func createMqttSocketTransport() {
        let transport = MQTTCFSocketTransport()
        transport.tls = false
        transport.port = port
        transport.host = server
        
        session.clientId = "IosClient_\(NSDate().timeIntervalSince1970)"
        session.transport = transport
        session.delegate = self
    }
    
    func handleEvent(_ session: MQTTSession!, event eventCode: MQTTSessionEvent, error: Error!) {
        switch eventCode {
        case .connected:
            TRACE("Connected")
            subscribeToTopic()
        case .connectionClosed:
            TRACE("Closed")
        case .connectionClosedByBroker:
            TRACE("Closed by Broker")
        case .connectionError:
            TRACE("Error")
        case .connectionRefused:
            TRACE("Refused")
        case .protocolError:
            TRACE("Protocol Error")
        }
    }
    
    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        let message = String(decoding: data, as: UTF8.self)
        TRACE("\n topic - \(topic!) data - \(message)")
        displayMessageLog(message)
    }
    
    func subAckReceived(_ session: MQTTSession!, msgID: UInt16, grantedQoss qoss: [NSNumber]!) {
        TRACE("\n subAckReceived")
    }
    
    func unsubAckReceived(_ session: MQTTSession!, msgID: UInt16) {
        TRACE("\n unsubAckReceived")
    }
    
    func connectToMqtt() {
        self.session.connect()
    }
    
    func subscribeToTopic() {
        session.subscribe(toTopic: subscriptionTopic, at: .atMostOnce)
    }
    
    func sendMessage(_ message: String) {
        let data = message.data(using: String.Encoding.utf8, allowLossyConversion: false)
        session.publishData(data, onTopic: publishTopic, retain: false, qos: .atMostOnce)
    }
    
}

/**
 Constains general logging methods.
 */
extension MQTTController {
    func TRACE(_ message: String = "", fun: String = #function) {
        print("[TRACE] [\(message)")
    }
    
    func displayAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func displayMessageLog(_ message: String) {
        messagesLabel.text = message + "\n" + (messagesLabel.text ?? "")
    }
    
    func clearInputField() {
        messageInputField.text = ""
    }
}


