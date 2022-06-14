//
//  ProfileViewController.swift
//  ChatAppAES
//
//  Created by quynb on 19/01/2022.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var nameUser: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var profileTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        avatar.layer.borderWidth = 1
        avatar.layer.borderColor = UIColor.black.cgColor
        avatar.contentMode = UIView.ContentMode.scaleAspectFill
        avatar.layer.cornerRadius = (avatar.bounds.height) / 2
        avatar.layer.masksToBounds = false
        avatar.clipsToBounds = true
        
        let email = UserDefaults.standard.object(forKey: "Email")
        let name = UserDefaults.standard.object(forKey: "name")
        emailLabel.text = email as? String
        nameUser.text = name as? String
        let safeEmail = DatabaseManager.shared.safeEmail(Email: email as! String)
        let fileName = safeEmail + "_avatar.png"
        let path = "images/" + fileName
        
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success(let url):
                self.loadImageFromURL(imageView: self.avatar, url: url)
            case .failure(let error):
                print("Failed: \(error)")
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
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
