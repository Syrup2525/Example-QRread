//
//  ViewController.swift
//  qrread
//
//  Created by 김경환 on 2023/02/15.
//

import UIKit
import AVFoundation

class QRreadViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    
    public var dismissClosure: ((String?) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        basicSetting()
    }
    
    @IBAction func onClickBack(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.dismissClosure?(nil)
        }
    }
    
    private func basicSetting() {
        guard
            let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        else {
            print("captureDevice is nil")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
            
            let output = AVCaptureMetadataOutput()
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            // 리더기가 인식할 수 있는 코드 타입을 정한다. 이 프로젝트의 경우 qr.
            output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

            // 카메라 영상이 나오는 layer 와 + 모양 가이드 라인을 뷰에 추가하는 함수 호출.
            setVideoLayer()
            setGuideCrossLineView()

            // startRunning() 과 stopRunning() 로 흐름 통제
            // input 에서 output 으로의 데이터 흐름을 시작
            captureSession.startRunning()
        } catch {
            print("error")
        }
    }

    // 카메라 영상이 나오는 layer 를 뷰에 추가
    private func setVideoLayer() {
        let videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = view.layer.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(videoLayer)
    }
    
    // + 모양 가이드라인을 뷰에 추가
    private func setGuideCrossLineView() {
        let guideCrossLine = UIImageView()
        guideCrossLine.image = UIImage(systemName: "plus")
        guideCrossLine.tintColor = .green
        guideCrossLine.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guideCrossLine)
        NSLayoutConstraint.activate([
            guideCrossLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideCrossLine.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            guideCrossLine.widthAnchor.constraint(equalToConstant: 30),
            guideCrossLine.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}

extension QRreadViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard
                let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue
            else {
                return
            }
            
            print("[QR Read] \(stringValue)")
            
            self.captureSession.stopRunning()
            
            self.dismiss(animated: true) {
                self.dismissClosure?(stringValue)
            }
        }
    }
}
