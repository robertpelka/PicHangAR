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
    @IBOutlet weak var doneButton: UIButton!
    
    var preserveAspectRatio = true
    var pictureAspectRatio: Float = 0.668
    
    override func viewDidLoad() {
        super.viewDidLoad()

        widthSlider.value = 55.0
        heightSlider.value = 69.2
        doneButton.layer.cornerRadius = 15
        
        recalculateMaximumBorderThickness()
        widthChanged(widthSlider)
    }
    
    @IBAction func widthChanged(_ sender: UISlider) {
        if preserveAspectRatio {
            calculateFrameHeight()
            
            if heightSlider.value >= heightSlider.maximumValue {
                calculateFrameWidth()
            }
            else if heightSlider.value <= heightSlider.minimumValue {
                calculateFrameWidth()
            }
        }
        
        widthLabel.text = String(Int(round(sender.value))) + " cm"
        recalculateMaximumBorderThickness()
    }
    
    func calculateFrameHeight() {
        let pictureWidth = widthSlider.value - (2 * borderSlider.value)
        let pictureHeight = pictureWidth / pictureAspectRatio
        heightSlider.value = pictureHeight + (2 * borderSlider.value)
        heightLabel.text = String(Int(round(heightSlider.value))) + " cm"
    }
    
    func calculateFrameWidth() {
        let pictureHeight = heightSlider.value - (2 * borderSlider.value)
        let pictureWidth = pictureHeight * pictureAspectRatio
        widthSlider.value = pictureWidth + (2 * borderSlider.value)
        widthLabel.text = String(Int(round(widthSlider.value))) + " cm"
    }
    
    @IBAction func heightChanged(_ sender: UISlider) {
        heightLabel.text = String(Int(round(sender.value))) + " cm"
        recalculateMaximumBorderThickness()
    }
    
    func recalculateMaximumBorderThickness() {
        borderSlider.maximumValue = min(widthSlider.value, heightSlider.value) / 2 - 1
        borderSlider.value = borderSlider.maximumValue / 2
        borderLabel.text = String(format: "%.1f", borderSlider.value) + " cm"
    }
    
    @IBAction func preserveAspectRatioSwitched(_ sender: UISwitch) {
        if sender.isOn {
            preserveAspectRatio = true
            heightSlider.isEnabled = false
            heightSlider.tintColor = UIColor.secondaryLabel
            widthChanged(widthSlider)
        }
        else {
            preserveAspectRatio = false
            heightSlider.isEnabled = true
            heightSlider.tintColor = .none
        }
    }
    
    @IBAction func borderThicknessChanged(_ sender: UISlider) {
        if preserveAspectRatio {
            calculateFrameHeight()
            
            if heightSlider.value >= heightSlider.maximumValue {
                calculateFrameWidth()
            }
            else if heightSlider.value <= heightSlider.minimumValue {
                calculateFrameWidth()
            }
        }
        
        borderLabel.text = String(format: "%.1f", sender.value) + " cm"
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.goToMainVC, sender: self)
    }
    
}
