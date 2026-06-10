//
//  WebViewCommonVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 26/12/25.
//

import UIKit
import WebKit

class WebViewCommonVC: UIViewController {
    
    //Outlets..
    @IBOutlet weak var Activity: UIActivityIndicatorView!
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var lblTitle: UILabel!

    //Variables..
    var strTitle = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initilaisation()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.setHidesBackButton(true, animated: true)

        //Hide tabbar code...
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil{
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }
    }
}

//MARK: - Initialisations..
extension WebViewCommonVC
{
    func initilaisation()
    {
        self.lblTitle.text = strTitle
        var strUrl = "https://guardian-drive.dharechainfotech.com/assets/html/Privacypolicy-Apple.html"
        //https://guardian-drive.dharechainfotech.com/assets/html/Privacypolicy-Apple.html
        //https://guardian-drive.dharechainfotech.com/assets/html/ProminentDisclosure-Apple.html
        
        if strTitle == "Privacy Policy"
        {
            strUrl = "https://guardian-drive.dharechainfotech.com/assets/html/Privacypolicy-Apple.html"
            
        }else if strTitle == "Terms Of Services"
        {
            strUrl = "https://guardian-drive.dharechainfotech.com/assets/html/TermsAndConditions.html"
            //"https://guardian-drive.dharechainfotech.com/assets/html/ProminentDisclosure-Apple.html"
        }
       
        guard let url = URL(string: strUrl) else { return }

        webview.navigationDelegate = self
        self.Activity.startAnimating()
        self.Activity.hidesWhenStopped = true

        let request = URLRequest(url: url)
        webview.load(request)
    }
}

//MARK:- Action events -
extension WebViewCommonVC {
    @IBAction private func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension WebViewCommonVC : WKNavigationDelegate
{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Activity.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Activity.stopAnimating()
    }
}
