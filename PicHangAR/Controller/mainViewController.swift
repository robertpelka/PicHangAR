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
    var preserveAspectRatio = true
    var pictureAspectRatio: CGFloat = 0.668
    var frameHeight: CGFloat = 0.279
    var frameWidth: CGFloat = 0.2
    var borderThickness: CGFloat = 0.02
    
    
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
        let pictureHeight = frameHeight - (borderThickness * 2)
        let pictureWidth = preserveAspectRatio ? frameWidth - (borderThickness * 2) : pictureHeight * pictureAspectRatio
        let picture = SCNPlane(width: pictureWidth, height: pictureHeight)
        picture.firstMaterial?.diffuse.contents = choosePictureButton.image(for: .normal)
        let pictureNode = SCNNode(geometry: picture)
        
        let frameDepth: CGFloat = 0.016
        let frame = SCNBox(width: frameWidth, height: frameHeight, length: frameDepth, chamferRadius: 0.001)
        frame.firstMaterial?.diffuse.contents = UIColor.white
        let frameNode = SCNNode(geometry: frame)
        
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
            frameSizeVC.pictureAspectRatio = Float(pictureAspectRatio)
        }
    }
    
    @IBAction func frameSizeButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.goToFrameSizeVC, sender: self)
    }
    
    @IBAction func unwindToMainViewController(segue: UIStoryboardSegue) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                if let sourceSegue = segue.source as? frameSizeViewController {
                    self.preserveAspectRatio = sourceSegue.preserveAspectRatio
                    self.frameWidth = CGFloat(sourceSegue.widthSlider.value / 100)
                    self.frameHeight = CGFloat(sourceSegue.heightSlider.value / 100)
                    print("\(sourceSegue.borderSlider.value) i \(Int(sourceSegue.borderSlider.value))")
                    self.borderThickness = CGFloat(sourceSegue.borderSlider.value / 100)
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
            pictureAspectRatio = choosenImage.size.width / choosenImage.size.height
            calculateFrameHeight(for: pictureAspectRatio)
            imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
    func calculateFrameHeight(for aspectRatio: CGFloat) {
        let pictureWidth = frameWidth - (2 * borderThickness)
        let pictureHeight = pictureWidth / aspectRatio
        frameHeight = pictureHeight + (2 * borderThickness)
    }
    
}
