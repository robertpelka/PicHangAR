//
//  frameSizeViewController.swift
//  PicHangAR
//
//  Created by Robert Pelka on 03/04/2021.
//

import UIKit

class frameSizeViewController: UIViewController {

    @IBOutlet weak var widthLabel: UILabel!
    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var heightSlider: UISlider!
    @IBOutlet weak var borderLabel: UILabel!
    @IBOutlet weak var borderSlider: UISlider!
    @IBOutlet weak var ratioSwitch: UISwitch!
    @IBOutlet weak var doneButton: UIButton!
    
    var frame = Frame()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.layer.cornerRadius = 15
        widthSlider.value = frame.width
        heightSlider.value = frame.height
        borderSlider.maximumValue = min(widthSlider.value, heightSlider.value) / 2 - 1
        borderSlider.value = frame.borderThickness
        refreshLabels()
        if frame.preserveAspectRatio {
            ratioSwitch.isOn = true
        }
        else {
            ratioSwitch.isOn = false
            preserveAspectRatioSwitched(ratioSwitch)
        }
    }
    
    func refreshLabels() {
        borderLabel.text = String(format: "%.1f", borderSlider.value) + " cm"
        widthLabel.text = String(Int(round(widthSlider.value))) + " cm"
        heightLabel.text = String(Int(round(heightSlider.value))) + " cm"
    }
    
    func updateWidth() {
        frame.calculateFrameWidth()
        widthSlider.value = Float(frame.width)
        widthLabel.text = String(Int(round(widthSlider.value))) + " cm"
    }
    
    func updateHeight() {
        frame.calculateFrameHeight()
        heightSlider.value = Float(frame.height)
        heightLabel.text = String(Int(round(heightSlider.value))) + " cm"
    }
    
    @IBAction func widthChanged(_ sender: UISlider) {
        frame.width = sender.value
        
        if frame.preserveAspectRatio {
            updateHeight()
            
            if heightSlider.value >= heightSlider.maximumValue {
                frame.height = heightSlider.maximumValue
                updateWidth()
            }
            else if heightSlider.value <= heightSlider.minimumValue {
                frame.height = heightSlider.maximumValue
                updateWidth()
            }
        }
        
        widthLabel.text = String(Int(round(sender.value))) + " cm"
        recalculateMaximumBorderThickness()
    }
    
    @IBAction func heightChanged(_ sender: UISlider) {
        frame.height = sender.value
        heightLabel.text = String(Int(round(sender.value))) + " cm"
        recalculateMaximumBorderThickness()
    }
    
    func recalculateMaximumBorderThickness() {
        borderSlider.maximumValue = min(widthSlider.value, heightSlider.value) / 2 - 1
        if frame.isModern {
            borderSlider.value = borderSlider.maximumValue / 2
        }
        else {
            borderSlider.value = borderSlider.maximumValue / 5
        }
        frame.borderThickness = borderSlider.value
        borderLabel.text = String(format: "%.1f", borderSlider.value) + " cm"
    }
    
    @IBAction func preserveAspectRatioSwitched(_ sender: UISwitch) {
        if sender.isOn {
            frame.preserveAspectRatio = true
            heightSlider.isEnabled = false
            heightSlider.tintColor = UIColor.secondaryLabel
            widthChanged(widthSlider)
        }
        else {
            frame.preserveAspectRatio = false
            heightSlider.isEnabled = true
            heightSlider.tintColor = .none
        }
    }
    
    @IBAction func borderThicknessChanged(_ sender: UISlider) {
        frame.borderThickness = borderSlider.value
        
        if frame.preserveAspectRatio {
            updateHeight()
            
            if heightSlider.value >= heightSlider.maximumValue {
                frame.height = heightSlider.maximumValue
                updateWidth()
            }
            else if heightSlider.value <= heightSlider.minimumValue {
                frame.height = heightSlider.maximumValue
                updateWidth()
            }
        }
        
        borderLabel.text = String(format: "%.1f", sender.value) + " cm"
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.goToMainVC, sender: self)
    }
    
}
