//
//  ChatViewController.swift
//  ChatAppAES
//
//  Created by quynb on 18/01/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static var dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        return formatter
    }()
    
    public var isNewConversation = false
    public var otherUserEmail: String
    private var conversationId: String?
    
    var messages = [Message]()
    private var selfSender:Sender? {
        guard let email = UserDefaults.standard.value(forKey: "Email") as? String else {
            return nil
        }
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }
    
    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        messages.append(Message(sender: selfSender!, messageId: "1", sentDate: Date(), kind: .text("Hello World!")))
//        messages.append(Message(sender: selfSender!, messageId: "1", sentDate: Date(), kind: .text("Are you ok?")))
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessageForConversatuion(with: id, completion: { resultt in
            switch resultt {
            case .success(let messages):
                print("succes for message: \(messages[0])")
                guard !messages.isEmpty else {
                    print("null")
                    return
                }
                
                self.messages = messages
                DispatchQueue.main.async {
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("\(error)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageId = createMessageId() else {
            return
        }
        //Send Message
        let mmessage = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        if isNewConversation {
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: mmessage, completion: { successs in
                if successs {
                    print("message sent new conversations")
                    self.isNewConversation = false
                } else {
                    print("message failed")
                }
            })
        } else {
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: mmessage, completion: { successs in
                if successs {
                    print("message sent")
                } else {
                    print("error send message")
                }
            })
        }
        inputBar.inputTextView.text = ""
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    private func createMessageId() -> String? {
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "Email") as? String else {
            return nil
        }
        
        var safeEmail = currentUserEmail.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        print("email: \(safeEmail)")
        let dataString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeEmail)_\(dataString)"
        print("message id: \(newIdentifier)")
        return newIdentifier
    }
    
    
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("sender us null")
    }
    
    func getTheMessageText(messageKind: MessageKind) -> String {
        if case .text(let value) = messageKind {
            return value
        }
        return ""
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
//        DatabaseManager.shared.getDataFor(path: "\(self.conversationId!)/key", completion: { resultt in
//            switch resultt {
//            case .success(let data):
//                messages[indexPath.row] = try! messages[indexPath.row].kind.textMessageKind.text.aesDecrypt(key: data as! String)
//            case .failure(let error):
//                print("\(error)")
//            }
//        })
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
