//
//  AppDelegate.swift
//  ChatAppAES
//
//  Created by quynb on 17/01/2022.
//

import Firebase
import UIKit
import BigInt
import CryptoSwift
import FirebaseDatabase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        "a".setUpKey(text: "Trung siu nhan")
//        if (UserDefaults.standard.value(forKey: "sharedSecretKeyValue") != nil) {
//            let sharedSecretKeyValue = UserDefaults.standard.value(forKey: "sharedSecretKeyValue") as! String
//                CreateShareKey.shared.initAES(sharedSecretKeyValue: sharedSecretKeyValue)
//            let a = CreateShareKey.shared.encrypt(mess: "Trung")
//            let b = CreateShareKey.shared.decrypt(cipherText: "pxJoxmYfUaogZuWO1cAs/A==")
//            
//            print(b)
//        }
        
//        Database.database().reference().child("key_infor").observeSingleEvent(of: .value, with: { (snapshot) in
//            if snapshot.exists(){
//                DatabaseManager.shared.getDataFor(path: "key_infor/iv", completion: { resultt in
//                    switch resultt {
//                    case .success(let data):
//                        let ivString = data as! String
//                        let dataIv = Data(base64Encoded: ivString, options: .ignoreUnknownCharacters)
//                        let iv = [UInt8](dataIv! as Data)
//                        UserDefaults.standard.set(iv, forKey: "iv")
//                    case .failure(let error):
//                        print("\(error)")
//                    }
//                })
//            }else{
//                print("false room doesn't exist")
//            }
//        })
        
        FirebaseApp.configure();
        return true
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}

