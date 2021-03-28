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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.autoenablesDefaultLighting = true
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .vertical) else {return}
            let results = sceneView.session.raycast(query)
            if let hitResult = results.first {
                hangPicture(atLocation: hitResult)
            }
        }
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
    }
    
    //MARK: - ARSCNViewDelegateMethods
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor(white: 1.0, alpha: 0.5)
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        planeNode.geometry = plane
        print("Plane detected")
        return planeNode
    }
    
}
