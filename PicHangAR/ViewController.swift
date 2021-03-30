//
//  ViewController.swift
//  PicHangAR
//
//  Created by Robert Pelka on 28/03/2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var lastNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
        registerGestureRecognizers()
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
        let touchLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchLocation, options: nil)
        if let hitTestResult = hitTestResults.first {
            lastNode = hitTestResult.node
            indicateSelection(ofNode: lastNode)
            return
        }
        guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .vertical) else {return}
        let results = sceneView.session.raycast(query)
        if let hitResult = results.first {
            hangPicture(atLocation: hitResult)
        }
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
        let touchLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchLocation, options: nil)
        if let hitTestResult = hitTestResults.first {
            lastNode = hitTestResult.node
        }
        if recognizer.state == .changed {
            let pinchScaleX = Float(recognizer.scale) * lastNode.scale.x
            let pinchScaleY = Float(recognizer.scale) * lastNode.scale.y
            let pinchScaleZ = Float(recognizer.scale) * lastNode.scale.z
            lastNode.scale = SCNVector3(x: pinchScaleX, y: pinchScaleY, z: pinchScaleZ)
            recognizer.scale = 1
        }
    }
    
    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let touchLocation = recognizer.location(in: recognizer.view)
        guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .vertical) else {return}
        let results = sceneView.session.raycast(query)

        guard let result = results.first else {
            return
        }

        let hits = self.sceneView.hitTest(recognizer.location(in: recognizer.view), options: nil)
        if let tappedNode = hits.first?.node {
            let position = SCNVector3Make(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            tappedNode.position = position
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
    
    func hangPicture(atLocation hitResult: ARRaycastResult) {
        let frame = SCNBox(width: 0.15, height: 0.2, length: 0.015, chamferRadius: 0.003)
        frame.firstMaterial?.diffuse.contents = UIColor.red
        let frameNode = SCNNode(geometry: frame)
        guard let hitResultAnchor = hitResult.anchor else {return}
        frameNode.transform = SCNMatrix4(hitResultAnchor.transform)
        frameNode.eulerAngles.x -= (.pi / 2)
        let location = hitResult.worldTransform.columns.3
        frameNode.position = SCNVector3(
            x: location.x,
            y: location.y,
            z: location.z)
        sceneView.scene.rootNode.addChildNode(frameNode)
        lastNode = frameNode
    }
    
    //MARK: - ARSCNViewDelegateMethods
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: 1, height: 1)
        plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.6)
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.geometry = plane
        print("Plane detected")
        return planeNode
    }
    
}
