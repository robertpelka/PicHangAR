//
//  frameModel.swift
//  PicHangAR
//
//  Created by Robert Pelka on 04/04/2021.
//

import Foundation
import SceneKit

struct Frame {
    var width: Float = 20
    var height: Float = 25.47
    var borderThickness: Float = 4.5
    var preserveAspectRatio = true
    var pictureAspectRatio: Float = 0.668
    var material = "Black"
    var isModern = true
    
    mutating func calculateFrameHeight() {
        let pictureWidth = width - (2 * borderThickness)
        let pictureHeight = pictureWidth / pictureAspectRatio
        height = pictureHeight + (2 * borderThickness)
    }
    
    mutating func calculateFrameWidth() {
        let pictureHeight = height - (2 * borderThickness)
        let pictureWidth = pictureHeight * pictureAspectRatio
        width = pictureWidth + (2 * borderThickness)
    }
    
    mutating func resetBorderThickness() {
        let maximumValue = min(width, height) / 2 - 1
        if isModern {
            borderThickness = maximumValue / 2
        }
        else {
            borderThickness = maximumValue / 5
        }
        calculateFrameHeight()
    }
}
