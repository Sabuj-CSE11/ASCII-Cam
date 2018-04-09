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
    
    //    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var values = ["$", "@", "%", "#", "*", "+", "=", "-", ":", ",", " "]

    override func viewDidLoad() {
        super.viewDidLoad()

        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
    }
    
    func setupCaptureSession(){
        captureSession.sessionPreset = AVCaptureSession.Preset.low
    }
    
    func setupDevice(){
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    
    func setupInputOutput(){
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput)
//            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
            
        } catch {
            print("Could not set up input \(error)")
        }
    }
    
    func setupPreviewLayer(){
//        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
//        cameraPreviewLayer?.frame = self.view.frame
//
//        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
        
        //        new stuff
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
    
    func grayscale(byteBuffer : UnsafeMutablePointer<UInt8>, index : Int) -> UInt8 {
        let b = UInt8(round(Double(byteBuffer[index]) * 0.11))
        let g = UInt8(round(Double(byteBuffer[index+1]) * 0.59))
        let r = UInt8(round(Double(byteBuffer[index+2]) * 0.3))
        
        return b + g + r
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var output = [String]()
        connection.videoOrientation = AVCaptureVideoOrientation.portrait // rotates camera
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
//        let bitsPerComponent = 8
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)!
        let byteBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for j in 0..<height {
            output.append("")
            for i in 0..<width {
                let index = (j * width + i) * 4
                
                let gray = grayscale(byteBuffer : byteBuffer, index : index)
                
                output[j].append(values[Int(Double(gray)/25.5)])
                
                byteBuffer[index] = gray
                byteBuffer[index+1] = gray
                byteBuffer[index+2] = gray
            }
        }
        print("\n\n", width, height)
        
        for x in [0,3,6,9,12] {
            print(values[Int(Double(grayscale(byteBuffer: byteBuffer, index: x))/25.5)])
        }
        
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
//        let newContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
//        if let context = newContext {
//            let cameraFrame = context.makeImage()
            DispatchQueue.main.async {
                self.asciiView.text = ""
//                self.processedView.image = UIImage(cgImage: cameraFrame!)
                for x in 0...(height-1) {
                    self.asciiView.text?.append((output[x] + "\n"))
                    self.asciiView.addCharacterSpacing()
                }
//            }
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }

}

extension UILabel {
    func addCharacterSpacing() {
        if let labelText = text, labelText.count > 0 {
            let attributedString = NSMutableAttributedString(string: labelText)
            attributedString.addAttribute(NSAttributedStringKey.kern, value: 0.8, range: NSRange(location: 0, length: attributedString.length - 1))
            attributedText = attributedString
        }
    }
}
