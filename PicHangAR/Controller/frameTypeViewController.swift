//
//  frameTypeViewController.swift
//  PicHangAR
//
//  Created by Robert Pelka on 04/04/2021.
//

import UIKit

class frameTypeViewController: UIViewController {

    @IBOutlet weak var typeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var materialImage: UIImageView!
    @IBOutlet weak var materialPicker: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    
    var frame = Frame()
    let materials = ["Black", "White", "Silver", "Gold", "Light Wood", "Dark Wood"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneButton.layer.cornerRadius = 15
        materialImage.image = UIImage(named: "art.scnassets/\(frame.material)Color.jpg")

        if !frame.isModern {
            typeSegmentedControl.selectedSegmentIndex = 1
        }
        
        materialPicker.dataSource = self
        materialPicker.delegate = self
        let selectedMaterialRow = materials.firstIndex(of: frame.material) ?? 0
        materialPicker.selectRow(selectedMaterialRow, inComponent: 0, animated: false)
    }

    @IBAction func doneButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: K.Segues.goToMainVC, sender: self)
    }
    
    @IBAction func typeSegmentedControlChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            frame.isModern = true
        }
        else {
            frame.isModern = false
        }
    }
}

//MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension frameTypeViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return materials.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return materials[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        frame.material = materials[row]
        materialImage.image = UIImage(named: "art.scnassets/\(frame.material)Color.jpg")
    }
}
