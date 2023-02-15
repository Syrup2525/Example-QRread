//
//  ViewController.swift
//  qrread
//
//  Created by 김경환 on 2023/02/15.
//

import UIKit
import WebKit


class ViewController: UIViewController {
    @IBOutlet var webContentView: UIView!
    
    private var wKWebView: WKWebView!
    
    public var url: String = "https://www.naver.com"
    public var parameter: String?
    
    private let QR_READ_SEGUE = "QRreadSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initWebView()
    }
    
    private func initWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "result")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.suppressesIncrementalRendering = false
        configuration.selectionGranularity = .dynamic
        configuration.allowsInlineMediaPlayback = false
        
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        wKWebView = WKWebView(frame: webContentView.bounds, configuration: configuration)
        
        wKWebView.uiDelegate = self
        wKWebView.navigationDelegate = self
        
        wKWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wKWebView.frame = CGRect(origin: CGPoint.zero, size: wKWebView.frame.size)
        
        webContentView.addSubview(wKWebView!)
        
        loadWebView()
    }
    
    private func loadWebView() {
        guard
            let url = URL(string: self.url)
        else {
            return
        }
        
        var urlRequest = URLRequest(url: url)
        
        if let parameter = self.parameter, parameter.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            if let header = convertToDictionary(text: parameter) {
                for (key, value) in header {
                    urlRequest.setValue("\(value)", forHTTPHeaderField: key)
                }
            } else {
                DispatchQueue.main.async {
                    self.alert(message: "JSON 문자열이 유효하지 않습니다.") {
                        self.dismiss(animated: true)
                    }
                }
                
                return
            }
        }
        
        wKWebView?.load(urlRequest)
    }
    
    private func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    @IBAction func onClickCamera(_ sender: UIButton) {
        self.performSegue(withIdentifier: self.QR_READ_SEGUE, sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QRreadViewController {
            destination.dismissClosure = { qrReadValue in
                if let qrReadValue = qrReadValue {
                    self.alert(message: qrReadValue)
                }
            }
        }
        
        super.prepare(for: segue, sender: sender)
    }
}

extension ViewController {
    public func openSafari(link: String) {
        // 공백제거
        let nonSpaceLink = link.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let encodedString = nonSpaceLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let encodedString = encodedString, let url = URL(string: encodedString) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    public func alert(message: String, title: String? = nil, okHandler: (() -> ())? = nil) {
        let sheet = UIAlertController(title: title ?? "알림", message: message, preferredStyle: .alert)
        sheet.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            okHandler?()
        })
        
        self.present(sheet, animated: true)
    }
    
    public func confirm(message: String, title: String? = nil, okHandler: (() -> ())? = nil, cancelHandler: (() -> ())? = nil) {
        let sheet = UIAlertController(title: title ?? "알림", message: message, preferredStyle: .alert)
        sheet.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            okHandler?()
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            cancelHandler?()
        })
        
        self.present(sheet, animated: true)
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "result" {
            guard
                let body = message.body as? String
            else {
                self.alert(message: "message.body is not String")
                return
            }
            
            self.alert(message: body, title: "result")
        }
    }
}

extension ViewController: WKUIDelegate, WKNavigationDelegate {
    // target _blank
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            self.openSafari(link: "\(navigationAction.request)")
        }
        
        return nil
    }
    
    // 웹 컨텐츠가 Web View로 로드되기 시작할 때 호출
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("[URL] \(webView)")
    }
    
    // alert패널 제어(안내)
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        self.alert(message: message) {
            completionHandler()
        }
    }
    
    // alert 패널 제어(확인/취소)
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        confirm(message: message, okHandler: { completionHandler(true) }, cancelHandler: { completionHandler(false) })
    }
    
    // alert 패널 제어(text입력 전달)
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        confirm(message: defaultText ?? "")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        let url = navigationAction.request.url
        let strUrl = url?.absoluteString
        
        if strUrl != "about:blank" {
            if ((strUrl ?? "") as NSString).range(of: "//itunes.apple.com/").location != NSNotFound {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                
                decisionHandler(.cancel, preferences)
                return
            } else if !(strUrl!.hasPrefix("http://")), !(strUrl!.hasPrefix("https://")) {   // URL scheme 방식인 경우
                if UIApplication.shared.canOpenURL(url!) {  // 해당 앱 오픈
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    decisionHandler(.cancel, preferences)
                } else {
                    alert(message: "앱 설치 후 다시 시도해주세요.")
                    decisionHandler(.cancel, preferences)
                }
                return
            }
        }
        
        decisionHandler(.allow, preferences)
    }
}

