//
//  RouteButton.swift
//  Ayero
//
//  Created by Yahor Paulikau on 5/4/17.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import UIKit

@IBDesignable
class StartButton: UIButton {
    
    @IBInspectable var isStarted: Bool = false
    @IBInspectable var fillColor: UIColor = UIColor.green

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        
        if isStarted {
            fillColor = UIColor.init(red: 20/255, green: 140/255, blue: 50/255, alpha: 0.8)
        } else {
            fillColor = UIColor.purple
        }

        fillColor.setFill()
        path.fill()

        let rect2 = CGRect(
            x: rect.origin.x + 4,
            y: rect.origin.y + 4,
            width: rect.width - 8,
            height: rect.height - 8
        )
        
        let circlePath = UIBezierPath(ovalIn: rect2)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 3
        shapeLayer.strokeColor = UIColor.white.cgColor
        self.layer.addSublayer(shapeLayer)

    }
    
}

@IBDesignable
class LoadRouteButton: UIButton {
    @IBInspectable var fillColor: UIColor = UIColor.green
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect)
        fillColor.setFill()
        path.fill()
        
        let rect2 = CGRect(
            x: rect.origin.x + 3,
            y: rect.origin.y + 3,
            width: rect.width - 6,
            height: rect.height - 6
        )
        
        let circlePath = UIBezierPath(ovalIn: rect2)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor

        shapeLayer.strokeColor = UIColor.green.cgColor
        shapeLayer.lineWidth = 1.5
        
        self.layer.addSublayer(shapeLayer)
    }
}

