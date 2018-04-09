//
//  ViewController.swift
//  ASCII Cam
//
//  Created by Nathaniel Yearwood on 2018-04-02.
//  Copyright © 2018 Nathaniel Yearwood. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    
    @IBOutlet weak var processedView: UIImageView!
    @IBOutlet weak var asciiView: UILabel!
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
//    var values = ["$", "@", "%", "#", "*", "+", "=", "-", ":", ",", " "]
    var values = ["$","@","B","%","8","&","W","M","#","*","o","a","h","k","b","d","p","q","w","m","Z","O","0","Q","L","C","J","U","Y","X","z","c","v","u","n","x","r","j","f","t","/","\\","|","(",")","1","{","}","[","]","?","-","_","+","~","<",">","i","!","l","I",";",":",",","\"","^","`","'","."," "]

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCaptureSession()
        setupCaptureDevice()
        setupInput()
        setupOutputLayer()
        startRunningCaptureSession()
    }
    
    func setupCaptureSession(){
        captureSession.sessionPreset = AVCaptureSession.Preset.low
    }
    
    func setupCaptureDevice(){
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
        }
        currentCamera = backCamera
    }
    
    func setupInput(){
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print("Could not set up input \(error)")
        }
    }
    
    func setupOutputLayer(){
        
        // shows camera preview
//        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
//        cameraPreviewLayer?.frame = self.view.frame
//
//        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
        
        // delegates image processing
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        let videoOutputQueue = DispatchQueue(label: "VideoQueue")
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Could not add video data as output.")
        }

    }
    
    func startRunningCaptureSession(){
        captureSession.startRunning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var output = [String]()
        connection.videoOrientation = AVCaptureVideoOrientation.portrait // rotates camera
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // locks memory address
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)!
        let byteBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for j in 0..<height {
            output.append("") // adds new empty string to array
            for i in 0..<width {
                // calcs buffer index (BGRA)
                let index = (j * width + i) * 4
                
                let gray = grayscale(byteBuffer : byteBuffer, index : index)
                
                output[j].append(values[Int(Double(gray)/3.643)]) // use 25.5 for 10 level colour space
            }
        }
        
        // shows sample values in console
        print("\n\nwidth", width, "\theight", height)
        for x in [0,4,8,12,16] {
            let index = Int(Double(grayscale(byteBuffer: byteBuffer, index: x))/3.643)
            print(values[index])
        }
        
        DispatchQueue.main.async {
            self.asciiView.text = ""
            for x in 0...(height-1) {
                self.asciiView.text?.append((output[x] + "\n"))
            }
            self.asciiView.addCharacterSpacing()
        }
        
        // frees memory address
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }
}




// converts BGR to grayscale using weighted values
func grayscale(byteBuffer : UnsafeMutablePointer<UInt8>, index : Int) -> UInt8 {
    let b = UInt8(round(Double(byteBuffer[index]) * 0.11))
    let g = UInt8(round(Double(byteBuffer[index+1]) * 0.59))
    let r = UInt8(round(Double(byteBuffer[index+2]) * 0.3))
    
    return b + g + r
}




// allows changing spacing between characters in UILabel for viewing ASCII
extension UILabel {
    func addCharacterSpacing() {
        if let labelText = text, labelText.count > 0 {
            let attributedString = NSMutableAttributedString(string: labelText)
            attributedString.addAttribute(NSAttributedStringKey.kern, value: 0.8, range: NSRange(location: 0, length: attributedString.length - 1))
            attributedText = attributedString
        }
    }
}
