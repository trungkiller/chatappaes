//
//  LoadingViewController.swift
//  Side Menu
//
//  Created by Nguyễn Trung on 23/01/2021.
//  Copyright © 2021 Kyle Lee. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
extension UIViewController {
    func startLoading( _ viewLoading: UIViewController) {
        view.addSubview(viewLoading.view)
        viewLoading.view.center = view.center
    }
    func stopLoading( _ viewLoading: UIViewController) {
        viewLoading.view.removeFromSuperview()
    }
}

class LoadingViewController: UIViewController {
    var loadingView: NVActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingView = NVActivityIndicatorView.init(frame: CGRect(x: 0,y: 0,width: 45,height: 45), type: .ballRotateChase, color: .darkGray, padding: 0)
        loadingView.startAnimating()
//        self.view.frame.size = CGSize(width: 45,height: 45)
        self.view.backgroundColor = .clear
        loadingView.backgroundColor = .clear
        self.view.addSubview(loadingView)
        loadingView.center = self.view.center
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
