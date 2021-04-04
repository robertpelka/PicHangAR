//
//  mainViewController.swift
//  PicHangAR
//
//  Created by Robert Pelka on 28/03/2021.
//

import UIKit
import SceneKit
import ARKit

class mainViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var scanningLabel: UILabel!
    @IBOutlet weak var foundLabel: UILabel!
    @IBOutlet weak var choosePictureButton: UIButton!
    
    let imagePicker = UIImagePickerController()
    var frame = Frame()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        choosePictureButton.imageView?.contentMode = .scaleAspectFill
        choosePictureButton.layer.borderWidth = 4
        choosePictureButton.layer.borderColor = UIColor.white.cgColor
        choosePictureButton.layer.cornerRadius = 15
        
        scanningLabel.layer.masksToBounds = true
        scanningLabel.layer.cornerRadius = scanningLabel.frame.height / 2
        scanningLabel.alpha = CGFloat(0)
        animateFlash(label: scanningLabel)
        foundLabel.layer.masksToBounds = true
        foundLabel.layer.cornerRadius = scanningLabel.frame.height / 2
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        registerGestureRecognizers()
    }
    
    func animateFlash(label: UILabel) {
        UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse], animations: {
            label.alpha = CGFloat(1)
        }, completion: nil)
    }
    
    func animatefadeOut(label: UILabel) {
        UIView.animate(withDuration: 0.4, delay: 0.6, options: [], animations: {
            label.alpha = CGFloat(0)
        }, completion: nil)
    }
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let touchLocation = recognizer.location(in: recognizer.view)
        
        let hitTestResults = self.sceneView.hitTest(touchLocation, options: nil)
        if let tappedNode = hitTestResults.first?.node {
            indicateSelection(ofNode: tappedNode)
            return
        }
        
        guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .vertical) else {return}
        let results = sceneView.session.raycast(query)
        if let result = results.first {
            hangPicture(atLocation: result)
        }
    }
    
    func hangPicture(atLocation hitResult: ARRaycastResult) {
        let pictureHeight = frame.height - (frame.borderThickness * 2)
        let pictureWidth = frame.preserveAspectRatio ? frame.width - (frame.borderThickness * 2) : pictureHeight * frame.pictureAspectRatio
        let picture = SCNPlane(width: CGFloat(pictureWidth / 100), height: CGFloat(pictureHeight / 100))
        picture.firstMaterial?.diffuse.contents = choosePictureButton.image(for: .normal)
        picture.firstMaterial?.lightingModel = .blinn
        picture.firstMaterial?.specular.contents = UIColor(white: 0.6, alpha: 1.0)
        picture.firstMaterial?.shininess = 100
        let pictureNode = SCNNode(geometry: picture)
        
        let frameDepth = min(CGFloat(max(frame.width, frame.height) / 1000), 0.03)
        let frameBox = SCNBox(width: CGFloat(frame.width / 100), height: CGFloat(frame.height / 100), length: frameDepth, chamferRadius: 0.001)
        frameBox.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/\(frame.material)Color.jpg")
        frameBox.firstMaterial?.normal.contents = UIImage(named: "art.scnassets/\(frame.material)Normal.jpg")
        frameBox.firstMaterial?.roughness.contents = UIImage(named: "art.scnassets/\(frame.material)Roughness.jpg")
        if frame.material == "Gold" || frame.material == "Silver" {
            frameBox.firstMaterial?.lightingModel = .physicallyBased
            frameBox.firstMaterial?.metalness.contents = UIColor(white: 0.7, alpha: 1.0)
            frameBox.firstMaterial?.shininess = 100
        }
        let frameNode = SCNNode(geometry: frameBox)
        
        if frame.isModern {
            let margin = CGFloat(frame.borderThickness / 100) / 2
            let background = SCNPlane(width: CGFloat(frame.width / 100) - margin, height: CGFloat(frame.height / 100) - margin)
            if frame.material == "White" {
                background.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/BlackColor.jpg")
            }
            else {
                background.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/WhiteColor.jpg")
            }
            background.firstMaterial?.lightingModel = .blinn
            background.firstMaterial?.specular.contents = UIColor(white: 0.6, alpha: 1.0)
            background.firstMaterial?.shininess = 100
            let backgroundNode = SCNNode(geometry: background)
            
            frameNode.addChildNode(backgroundNode)
            
            backgroundNode.position = SCNVector3(
                x: 0,
                y: 0,
                z: Float(frameDepth/2)+0.0005)
        }
        
        guard let hitResultAnchor = hitResult.anchor else {return}
        frameNode.transform = SCNMatrix4(hitResultAnchor.transform)
        frameNode.eulerAngles.x -= (.pi / 2)
        
        let location = hitResult.worldTransform.columns.3
        frameNode.position = SCNVector3(
            x: location.x,
            y: location.y,
            z: location.z + Float(frameDepth/2)
        )
        
        frameNode.addChildNode(pictureNode)
        
        pictureNode.position = SCNVector3(
            x: 0,
            y: 0,
            z: Float(frameDepth/2)+0.001)
        
        sceneView.scene.rootNode.addChildNode(frameNode.flattenedClone())
    }
    
    func indicateSelection(ofNode node: SCNNode) {
        guard let nodeMaterial = node.geometry?.firstMaterial else {return}
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            nodeMaterial.emission.contents = UIColor.black
            SCNTransaction.commit()
        }
        nodeMaterial.emission.contents = UIColor.blue
        SCNTransaction.commit()
    }
    
    @objc func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        let touchLocation = recognizer.location(in: recognizer.view)
        
        let hitTestResults = self.sceneView.hitTest(touchLocation, options: nil)
        if let tappedNode = hitTestResults.first?.node {
            if recognizer.state == .changed {
                let pinchScaleX = Float(recognizer.scale) * tappedNode.scale.x
                let pinchScaleY = Float(recognizer.scale) * tappedNode.scale.y
                let pinchScaleZ = Float(recognizer.scale) * tappedNode.scale.z
                tappedNode.scale = SCNVector3(x: pinchScaleX, y: pinchScaleY, z: pinchScaleZ)
                recognizer.scale = 1
            }
        }
    }
    
    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: recognizer.view)
        
        guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .vertical) else {return}
        let results = sceneView.session.raycast(query)
        guard let result = results.first else {return}

        let hitTestResults = self.sceneView.hitTest(touchLocation, options: nil)
        if let tappedNode = hitTestResults.first?.node {
            let position = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            tappedNode.position = position
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == K.Segues.goToFrameSizeVC) {
            let frameSizeVC = segue.destination as! frameSizeViewController
            frameSizeVC.frame = frame
        }
        if(segue.identifier == K.Segues.goToFrameTypeVC) {
            let frameTypeVC = segue.destination as! frameTypeViewController
            frameTypeVC.frame = frame
        }
    }
    
    @IBAction func frameSizeButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.goToFrameSizeVC, sender: self)
    }
    
    @IBAction func frameTypeButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.goToFrameTypeVC, sender: self)
    }
    
    @IBAction func unwindToMainViewController(segue: UIStoryboardSegue) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                if let sourceSegue = segue.source as? frameSizeViewController {
                    self.frame = sourceSegue.frame
                }
                if let sourceSegue = segue.source as? frameTypeViewController {
                    self.frame = sourceSegue.frame
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    //MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let scnLabel = self.scanningLabel {
                scnLabel.removeFromSuperview()
            }
            self.foundLabel.isHidden = false
            self.foundLabel.alpha = CGFloat(1)
            self.animatefadeOut(label: self.foundLabel)
        }
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode()
        planeNode.isHidden = true
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.geometry = plane
        return planeNode
    }
    
}

//MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension mainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBAction func choosePictureButtonPressed(_ sender: UIButton) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let choosenImage = info[.originalImage] as? UIImage {
            choosePictureButton.setImage(choosenImage, for: .normal)
            frame.pictureAspectRatio = Float(choosenImage.size.width / choosenImage.size.height)
            frame.calculateFrameHeight()
            imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
}
