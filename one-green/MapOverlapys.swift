//
//  ColorPolyLine.swift
//  Ayero
//
//  Created by Yahor Paulikau on 4/28/17.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import Foundation
import UIKit
import MapKit


enum routeDot {
    case regular
    case temporary
    case cursor
}



class ColorPolyline : MKPolyline {
    var color: String?
    var dotSelector: routeDot?
}


class ColorCicrle : MKCircle {
    var color: UIColor?
    var dotSelector: routeDot?
}


class ColorCicrleRenderer: MKOverlayRenderer {
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        if let circle = overlay as? ColorCicrle {
            let theMapRect = overlay.boundingMapRect
            let theRect = rect(for: theMapRect)
            let glow = UIColor(displayP3Red: 254/255, green: 215/255, blue: 252/255, alpha: 0.9)
            
            let inset: CGRect = theRect.insetBy(dx: 3, dy: 3)
            context.setStrokeColor(glow.cgColor)
            context.setFillColor((circle.color?.cgColor)!)
            context.setLineWidth(3/zoomScale)
            context.addEllipse(in: inset)
            context.drawPath(using: .fillStroke)
            
            let border = UIColor(displayP3Red: 100/255, green: 100/255, blue: 100/255, alpha: 0.6)
            context.setStrokeColor(border.cgColor)
            context.setLineWidth(1/zoomScale)
            context.addEllipse(in: theRect)
            context.drawPath(using: .stroke)
        }
    }
}


