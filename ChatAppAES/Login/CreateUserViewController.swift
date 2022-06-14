//
//  CreateUserViewController.swift
//  Side Menu
//
//  Created by Nguyễn Trung on 23/01/2021.
//  Copyright © 2021 Kyle Lee. All rights reserved.
//

import UIKit
import Firebase
import DTTextField

class CreateUserViewController: UIViewController {
    
    @IBOutlet weak var nameUser: DTTextField!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var Email: DTTextField!
    @IBOutlet weak var password: DTTextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var repass: DTTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        signInButton.layer.cornerRadius = 20
//        avatar.layer.cornerRadius = (avatar.frame.size.width - 5) / 2
        avatar.contentMode = UIView.ContentMode.scaleAspectFill
        avatar.layer.cornerRadius = (avatar.frame.height - 5) / 2
        avatar.layer.masksToBounds = false
        avatar.clipsToBounds = true

       
        self.bottomTextField()
        // Do any additional setup after loading the view.
    }
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
//    @objc func changeAvatar(_ sender: UITapGestureRecognizer) {
//        print("dada")
//        presentImage()
//    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        presentImage()
      }
    
    override func viewWillAppear(_ animated: Bool) {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.avatar.addGestureRecognizer(gesture)
        avatar.isUserInteractionEnabled = true
    }
    
    @IBAction func singInClick(_ sender: Any) {
        let email: String = self.Email.text!
        let pass: String = self.password.text!
        let nameUser: String = self.nameUser.text!
        var messageNotify: String = ""
        print(email)
        if (validateData()) {
            Auth.auth().createUser(withEmail: email, password: pass) { authResult, error in
                if let error = error as NSError? {
                    switch AuthErrorCode(rawValue: error.code) {
                    case .operationNotAllowed:  messageNotify = "Đã xảy ra lỗi"; break
                    // Error: The given sign-in provider is disabled for this Firebase project. Enable it in the Firebase console, under the sign-in method tab of the Auth section.
                    case .emailAlreadyInUse: messageNotify = "Email đã tồn tại"; break
                    // Error: The email address is already in use by another account.
                    case .invalidEmail: messageNotify = "Email không chính xác"; break
                    // Error: The email address is badly formatted.
                    case .weakPassword: messageNotify = "Mật khẩu phải chứ ít nhất 6 ký tự"; break
                    // Error: The password must be 6 characters long or more.
                    default:
                        print("Error: \(error.localizedDescription)")
                    }
                    let alert = UIAlertController(title: "Thông báo", message: messageNotify, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    print("User signs up successfully")
                    let newUserInfo = Auth.auth().currentUser
                    let emailUser = newUserInfo?.email
                    UserDefaults.standard.set(nameUser, forKey: "name")
                    let chatUser = ChatAppUser(name: nameUser, email: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            guard let image = self.avatar.image,
                                  let data = image.pngData() else {
                                      return
                                  }
                            let fileName = chatUser.avatarFileName
                            StorageManager.shared.uploadAvatar(with: data, fileName: fileName) { result in
                                switch result {
                                case .success(let downloadUrl):
                                    print(downloadUrl)
                                    UserDefaults.standard.set(downloadUrl, forKey: "avatar_url")
                                case .failure(let error):
                                    print("Error download: \(error)")
                                }
                            }
                        }
                    })
                    print(emailUser!)
                    let alert = UIAlertController(title: "Thông báo", message: "Đăng ký thành công!", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {_ in
                        _ = self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func bottomTextField() {
        nameUser.placeholderColor = .lightGray
        Email.placeholderColor = .lightGray
        password.placeholderColor = .lightGray
        repass.placeholderColor = .lightGray
        
        nameUser.floatPlaceholderColor = .darkGray
        Email.floatPlaceholderColor = .darkGray
        password.floatPlaceholderColor = .darkGray
        repass.floatPlaceholderColor = .darkGray
        
        nameUser.floatPlaceholderFont = UIFont(name: "Chalkboard SE", size: 11.0)!
        Email.floatPlaceholderFont = UIFont(name: "Chalkboard SE", size: 11.0)!
        password.floatPlaceholderFont = UIFont(name: "Chalkboard SE", size: 11.0)!
        repass.floatPlaceholderFont = UIFont(name: "Chalkboard SE", size: 11.0)!
        
        //        userName.dtLayer.cornerRadius = 15
        nameUser.dtLayer.backgroundColor = .none
        Email.dtLayer.backgroundColor = .none
        password.dtLayer.backgroundColor = .none
        repass.dtLayer.backgroundColor = .none
        
        nameUser.borderColor = .darkGray
        Email.borderColor = .darkGray
        
        nameUser.dtborderStyle = .bottom
        Email.dtborderStyle = .bottom
        password.dtborderStyle = .bottom
        
        password.borderColor = .darkGray
        repass.dtborderStyle = .bottom
        repass.borderColor = .darkGray
        
        nameUser.keyboardType = UIKeyboardType.alphabet;
        Email.keyboardType = UIKeyboardType.alphabet;
        
    }
    
    func validateData() -> Bool {
        guard !nameUser.text!.isEmptyStr else {
            nameUser.showError(message: "Bạn cần nhập tên người dùng")
            return false
        }
        
        guard !Email.text!.isEmptyStr else {
            Email.showError(message: "Bạn cần nhập Email")
            return false
        }
        guard !password.text!.isEmptyStr else {
            password.showError(message: "Bạn cần nhập mật khẩu")
            return false
        }
        guard !repass.text!.isEmptyStr else {
            repass.showError(message: "Bạn cần nhập lại mật khẩu")
            return false
        }
        guard isValidEmail(password.text!, repass: repass.text!) else {
            repass.showError(message: "Mật khẩu không trùng khớp")
            return false
        }
        return true
    }
    
    func isValidEmail(_ pass: String, repass: String) -> Bool {
        if (pass == repass) {
            return true
        }
        return false
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension CreateUserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentImage() {
        let actions = UIAlertController(title: "Profile Picture", message: "Hay chon 1 buc anh lam anh dai dien", preferredStyle: .actionSheet)
        actions.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actions.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        actions.addAction(UIAlertAction(title: "Chooese Photo", style: .default, handler: { [weak self] _ in
            self?.presentPickImage()
        }))
        present(actions, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPickImage() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController .InfoKey.editedImage] as? UIImage else {
            return
        }
        self.avatar.image = selectedImage
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
