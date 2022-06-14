//
//  ConversationsViewController.swift
//  ChatAppAES
//
//  Created by quynb on 17/01/2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import FirebaseDatabase

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let lastestMessage: LastestMessage
}

struct LastestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

class ConversationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let shared = ConversationsViewController()
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet var tableViewChat: UITableView!
    
    let cellTable = "ConversationTableViewCell"
    let spinner = JGProgressHUD(style: .dark)
    private var conversations = [Conversation]()
    let profile = ProfileViewController()
    static var key_infor_path: String = "default"
    static var email_other: String = "email"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableViewChat.delegate = self
        self.tableViewChat.dataSource = self
        //        DatabaseManager.shared.test()
        self.title = "Chat"
        tableViewChat.register(UINib(nibName: cellTable, bundle: nil), forCellReuseIdentifier: cellTable)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTap))
        if (UserDefaults.standard.value(forKey: ConversationsViewController.key_infor_path) != nil) {
            let sharedSecretKeyValue = UserDefaults.standard.value(forKey: ConversationsViewController.key_infor_path) as! String
            CreateShareKey.shared.initAES(sharedSecretKeyValue: sharedSecretKeyValue)
        }
        
        // Do any additional setup after loading the view.
    }
    
    private func startListeningForConversation() {
        guard let email = UserDefaults.standard.value(forKey: "Email") as? String else {
            return
        }
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        DatabaseManager.shared.getAllConversation(for: safeEmail, completion: { [weak self] resultt in
            switch resultt {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                
                self?.conversations = conversations
            case .failure(let error):
                print("\(error)")
                self?.conversations = [];
                break
            }
            DispatchQueue.main.async {
                self?.tableViewChat.reloadData()
            }
        })
        
    }
    
    @IBAction func segmentneeded(sender: AnyObject)
    {
        if(segment.selectedSegmentIndex == 0)
        {
            self.title = "Chat"
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTap))
            profile.view.removeFromSuperview()
            startListeningForConversation()
            //            segment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        else if(segment.selectedSegmentIndex == 1)
        {
            self.title = "Profile"
            if #available(iOS 13.0, *) {
                let logoutButton = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.forward.square.fill"), style: .plain, target: self, action:#selector(logOut))
                self.navigationItem.rightBarButtonItem  = logoutButton
                profile.view.frame = self.tableViewChat.frame
                profile.view.center = self.tableViewChat.center
                self.view.addSubview(profile.view)
            } else {
                // Fallback on earlier versions
            } // action:#selector(Class.MethodName) for swift 3
            
            //            segment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }
    
    @objc func didTap() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] resultt in
            let email_other = resultt["email"]!
            let email = UserDefaults.standard.value(forKey: "Email")!
            let safeEmail = DatabaseManager.shared.safeEmail(Email: email as! String)
            let key_db = "key_infor_\(email_other)_\(safeEmail)"
            ConversationsViewController.key_infor_path = key_db
            ConversationsViewController.email_other = email_other
            Database.database().reference().child(key_db).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(){
                    self?.createNewConversation(result: resultt)
                } else {
                   
                    self?.setUpkey(key_db:key_db)
//                    self?.createNewConversation(result: resultt)
                    let alert = UIAlertController(title: "Thông báo", message: "Đã gửi lời mời kết bạn.", preferredStyle: UIAlertController.Style.alert)

                            // add an action (button)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

                            // show the alert
                    self!.present(alert, animated: true, completion: nil)
                }
            })
            
        }
        let navVc = UINavigationController(rootViewController: vc)
        present(navVc, animated: true)
    }
    
    func setUpkey(key_db: String) {
        var g = CreateShareKey.shared.generatePrimeNumber()
        var m = CreateShareKey.shared.generatePrimeNumber()

        if (g > m) {
            let swap = g
            g = m
            m = swap
        }
        
        let senderSecretKeyValue = CreateShareKey.shared.generateRandomNumber() % MAX_RANDOM_NUMBER
        UserDefaults.standard.set("\(senderSecretKeyValue)", forKey: "senderSecretKeyValue")
        
        let senderPublicKeyValue = CreateShareKey.shared.powermod(g, power: senderSecretKeyValue, modulus: m)
        let iv = CreateShareKey.shared.createIV()
        
        let value: [String: Any] = [
            "g": g,
            "m": m,
            "iv": iv,
            "senderPublicKeyValue": senderPublicKeyValue,
            "sender": UserDefaults.standard.value(forKey: "name") as! String
        ]
        let email = UserDefaults.standard.value(forKey: "Email")!
        let safeEmail = DatabaseManager.shared.safeEmail(Email: email as! String)
        
//        let value_add: [String: Any] = [
//            "chat_with": safeEmail
//        ]
        
        DatabaseManager.shared.database.child(key_db).setValue(value, withCompletionBlock: { error, _  in
            guard error == nil else {
                return
            }
            UserDefaults.standard.set(true, forKey: "sender")
        })
        
        DatabaseManager.shared.database.child("\(ConversationsViewController.email_other)/chat_with").observeSingleEvent(of: .value, with: {snapshot in
            if var userCollection = snapshot.value as? [[String: String]] {
                let newElement = [
                    "email": safeEmail
                ]
                
                userCollection.append(newElement)
                
                DatabaseManager.shared.database.child("\(ConversationsViewController.email_other)/chat_with").setValue(userCollection, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        return
                    }
                })
            } else {
                let newCollection: [[String: String]] = [
                    [
                        "email": safeEmail
                    ]
                ]
                
                DatabaseManager.shared.database.child("\(ConversationsViewController.email_other)/chat_with").setValue(newCollection, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        return
                    }
                })
            }
        })
        
//        DatabaseManager.shared.database.child("\(ConversationsViewController.email_other)/").setValue(value_add, withCompletionBlock: { error, _  in
//            guard error == nil else {
//                return
//            }
//        })
    }
    
    private func createNewConversation(result: [String: String]) {
        guard let name = result["name"], let email = result["email"] else {
            return
        }
        
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func logOut(_ sender: UIButton) {
        try! Auth.auth().signOut()
        let domain = Bundle.main.bundleIdentifier
        UserDefaults.standard.removePersistentDomain(forName: domain!)
        UserDefaults.standard.synchronize()
        let login = LoginViewController()
        self.navigationController?.pushViewController(login, animated: true)
    }
    
    func GetKey(key_path: String) {
        var g = 0
        var m = 0
        var senderPublicKeyValue = 0
        var receivePublicKeyValue = 0
        
        if (UserDefaults.standard.value(forKey: "sender") == nil) {
            if (UserDefaults.standard.value(forKey: key_path) == nil) {
                DatabaseManager.shared.getDataFor(path: "\(key_path)/g", completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        g = data as! Int
                    case .failure(let error):
                        print("\(error)")
                    }
                })
                
                DatabaseManager.shared.getDataFor(path: "\(key_path)/m", completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        m = data as! Int
                    case .failure(let error):
                        print("\(error)")
                    }
                })
                
                DatabaseManager.shared.getDataFor(path: "\(key_path)/senderPublicKeyValue", completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        senderPublicKeyValue = data as! Int
                        let receiveSecretKey = CreateShareKey.shared.generateRandomNumber() % MAX_RANDOM_NUMBER
                        UserDefaults.standard.set("\(receiveSecretKey)", forKey: "receiveSecretKey")
                        
                        let receivePublicKeyValue = CreateShareKey.shared.powermod(g, power: receiveSecretKey, modulus: m)
                        
                        let sharedSecretKeyValue = CreateShareKey.shared.powermod(senderPublicKeyValue, power: receiveSecretKey, modulus: m)
                        print("trung1: \(sharedSecretKeyValue)")
                        UserDefaults.standard.set("\(sharedSecretKeyValue)", forKey: key_path)
                        CreateShareKey.shared.initAES(sharedSecretKeyValue: "\(sharedSecretKeyValue)")
                        
                        //                    let value: [String: Any] = [
                        //                        "receivePublicKeyValue": senderPublicKeyValue
                        //                    ]
                        
                        DatabaseManager.shared.database.child("\(key_path)").child("receivePublicKeyValue").setValue(receivePublicKeyValue, withCompletionBlock: { error, _  in
                            guard error == nil else {
                                return
                            }
                        })
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            } else {
//                let sharedSecretKeyValue = UserDefaults.standard.value(forKey: "sharedSecretKeyValue") as! String
//                    CreateShareKey.shared.initAES(sharedSecretKeyValue: sharedSecretKeyValue)
            }
        } else {
            if (UserDefaults.standard.value(forKey: key_path) == nil) {
                DatabaseManager.shared.getDataFor(path: "\(key_path)/g", completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        g = data as! Int
                    case .failure(let error):
                        print("\(error)")
                    }
                })
                
                DatabaseManager.shared.getDataFor(path: "\(key_path)/m", completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        m = data as! Int
                    case .failure(let error):
                        print("\(error)")
                    }
                })
                
                DatabaseManager.shared.getDataFor(path: "\(ConversationsViewController.key_infor_path)/receivePublicKeyValue", completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        receivePublicKeyValue = data as! Int
                        let senderSecretKeyValue = UserDefaults.standard.value(forKey: "senderSecretKeyValue") as! String
                        
                        let sharedSecretKeyValue = CreateShareKey.shared.powermod(receivePublicKeyValue, power: Int(senderSecretKeyValue)!, modulus: m)
                        print("trung2: \(sharedSecretKeyValue)")
                        UserDefaults.standard.set("\(sharedSecretKeyValue)", forKey: key_path)
                        CreateShareKey.shared.initAES(sharedSecretKeyValue: "\(sharedSecretKeyValue)")
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            } else {
//                let sharedSecretKeyValue = UserDefaults.standard.value(forKey: "sharedSecretKeyValue") as! String
//                    CreateShareKey.shared.initAES(sharedSecretKeyValue: sharedSecretKeyValue)
            }
        }
    }
    
    func CompletionKey(users: [[String: String]]) {
        let email = UserDefaults.standard.object(forKey: "Email") as! String
        let safeEmail = DatabaseManager.shared.safeEmail(Email: email)
        for val in users {
            let email_chat = (val["email"]! as String)
            let key_path = "key_infor_\(safeEmail)_\(email_chat)"
        if (UserDefaults.standard.value(forKey: "sender") == nil) {
            Database.database().reference().child("\(key_path)").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(){
                    if (UserDefaults.standard.value(forKey: "sharedSecretKeyValue") == nil) {
                        var sender: String = ""
                        DatabaseManager.shared.getDataFor(path: "\(key_path)/sender", completion: { resultt in
                            switch resultt {
                            case .success(let data):
                                sender = data as! String
                            case .failure(let error):
                                print("\(error)")
                            }
                        })
                        self.GetKey(key_path: key_path)
//                        let alert = UIAlertController(title: "Thông báo", message: "\(sender) đã gửi lời mời kết bạn.", preferredStyle: UIAlertController.Style.alert)
//
//                                // add an action (button)
//                        alert.addAction(UIAlertAction(title: "Đồng ý", style: .default, handler: { action in
//                            switch action.style{
//                                case .default:
//                                self.GetKey(key_path: key_path)
//
//                                case .cancel:
//                                print("cancel")
//
//                                case .destructive:
//                                print("destructive")
//
//                            }
//                        }))
//
//                                // show the alert
//                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.startListeningForConversation()
                    }
                    
                }else{
                    print("false room doesn't exist")
                }
            })
        } else {
            Database.database().reference().child("\(ConversationsViewController.key_infor_path)/receivePublicKeyValue").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists(){
                    if (UserDefaults.standard.value(forKey: "sharedSecretKeyValue") == nil) {
                        self.GetKey(key_path: key_path)
                    } else {
//                        let sharedSecretKeyValue = UserDefaults.standard.value(forKey: "sharedSecretKeyValue") as! String
//                        CreateShareKey.shared.initAES(sharedSecretKeyValue: sharedSecretKeyValue)
                        self.startListeningForConversation()
                    }
                }else{
                    print("false room doesn't exist")
                }
            })
        }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        var users = [[String: String]]()
        if !checkLogin() {
            let login = LoginViewController()
            self.navigationController?.pushViewController(login, animated: true)
        } else {
            DatabaseManager.shared.getAllChatWith(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    users = usersCollection
                    self!.CompletionKey(users: users)
                case .failure(let error):
                    print(error)
                }
            })
        }
//            receivePublicKeyValue
           
        //        if FirebaseAuth.Auth.auth().currentUser == nil {
        //            let login = LoginViewController()
        //            self.navigationController?.pushViewController(login, animated: true)
        //        }
    }
    func checkLogin() -> Bool {
        let isLogin = UserDefaults.standard.bool(forKey: "logInState")
        return isLogin;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellTable) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        let pathImg = "images/\(model.otherUserEmail)_avatar.png"
        StorageManager.shared.downloadURL(for: pathImg, completion: { [weak self] resultt in
            switch resultt {
            case .success(let url):
                self?.loadImageFromURL(imageView: cell.avatar, url: url)
            case .failure(let error):
                print("\(error)")
                break
            }
        })
        var lastMessage = ""
        let senderSecretKeyValue = UserDefaults.standard.value(forKey: "sharedSecretKeyValue") as! String
        lastMessage = CreateShareKey.shared.decrypt(cipherText: model.lastestMessage.text)
        cell.lastest_message.text = lastMessage
        cell.nameUser.text = model.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("trunggg")
        let model = conversations[indexPath.row]
        tableViewChat.deselectRow(at: indexPath, animated: true)
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //        return 120
    //    }
    
    func loadImageFromURL(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async() {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
    }
    
}
