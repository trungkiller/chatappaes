//
//  NewConversationViewController.swift
//  ChatAppAES
//
//  Created by quynb on 17/01/2022.
//

import UIKit
import JGProgressHUD
import FirebaseDatabase

class NewConversationViewController: UIViewController {

    public var completion: (([String: String]) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    private var results = [[String: String]]()
    private var hasFetched = false
    
    private let searchBar: UISearchBar = {
       let searchBar = UISearchBar()
        searchBar.placeholder = "Tim nguoi dung..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "Khong ton tai nguoi dung"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Huy", style: .done, target: self, action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: self.view.bounds.width/4, y: (self.view.bounds.height - 200) / 2, width: self.view.bounds.width, height: 200)
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUserData = results[indexPath.row]
        print("trunggggg1")
        let email = UserDefaults.standard.value(forKey: "Email")!
        let safeEmail = DatabaseManager.shared.safeEmail(Email: email as! String)
        let email_other = targetUserData["email"]
        let key_db = "key_infor_\(email_other!)_\(safeEmail)"
        
        Database.database().reference().child("\(key_db)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(){
                ConversationsViewController.init().GetKey(key_path: key_db)
                DatabaseManager.shared.getDataFor(path: "\(key_db)/iv", completion: { resultt in
                    switch resultt {
                    case .success(let data):
                        let ivString = data as! String
                        UserDefaults.standard.set(ivString, forKey: "\(key_db)_iv")
                        DispatchQueue.main.async {
                            if (UserDefaults.standard.value(forKey: key_db) != nil) {
                                let sharedSecretKeyValue = UserDefaults.standard.value(forKey: key_db) as! String
                                CreateShareKey.aes = CreateShareKey.shared.initAES(sharedSecretKeyValue: sharedSecretKeyValue, key_path: key_db, ivString: ivString)
                            }
//                            } else {
//                                ConversationsViewController.init().GetKey(key_path: key_db)
//                                let sharedSecretKeyValue = UserDefaults.standard.value(forKey: key_db) as! String
//                                CreateShareKey.aes = CreateShareKey.shared.initAES(sharedSecretKeyValue: sharedSecretKeyValue, key_path: key_db, ivString: ivString)
//                            }
                            self.dismiss(animated: true, completion: { [weak self] in
                                self?.completion?(targetUserData)
                            })
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            } else {
                self.dismiss(animated: true, completion: { [weak self] in
                    self?.completion?(targetUserData)
                })
            }
        })
    }
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.isEmpty, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        
        spinner.show(in: self.view)
        
        self.searchUser(query: text)
    }
    
    func searchUser(query: String) {
        if hasFetched {
            filterUsers(with: query)
        } else {
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print(error)
                }
            })
        }
    }
    
    func filterUsers(with term: String) {
        guard hasFetched else {
            return
        }
        
        self.spinner.dismiss(animated: true)
        
        let results: [[String: String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResultLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}
