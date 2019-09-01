//
//  SimpleChart.swift
//  Ayero
//
//  Created by Yahor Paulikau on 5/4/17.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import UIKit

@IBDesignable
class SimpleChart: UIView {

    let barWidth = 13
    let spaceWidth = 1
    var maxBars: Int = 0
    var bars: [(acc:Double, br:Double)] = []
    

    override func draw(_ rect: CGRect) {
        
        #if TESTMODE
        var a = 0.01
        for _ in 1...100 {
            bars.append((a, a))
            a = a + 0.025
        }
        #endif
        
        maxBars = Int(Double(frame.width) / (Double(barWidth + spaceWidth + 1)))
        var i = 0
        let halfHeight = Double(rect.height/2) - 1
                
        for p in bars {
            // acceleration bar
            let barHeight = Int(halfHeight / penaltyMax * p.acc)
            let x = i * barWidth + spaceWidth * (i-1)
            let y = Int(halfHeight) - barHeight
            let bar = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = UIBezierPath(rect:bar)
            mapColor2Penalty(penalty: p.acc, penaltyMax: penaltyMax).setFill()
            path.fill()

            
            // braking bar
            let barHeight2 = Int(Double(rect.height/2) / penaltyMax * p.br)
            let y2 = Int(halfHeight)
            let bar2 = CGRect(x: x, y: y2, width: barWidth, height: barHeight2)
            let path2 = UIBezierPath(rect:bar2)
            mapColor2Penalty(penalty: p.br, penaltyMax: penaltyMax).setFill()
            path2.fill()

            i += 1
        }
        
        // draw divider line
        let div = CGRect(x: 0, y: Int(halfHeight), width: Int(rect.width), height: 1)
        UIColor(red: 1, green: 1, blue: 1, alpha: 0.7).setFill()
        let path1 = UIBezierPath(rect:div)
        path1.fill()

    }
 
    func addBar(p:(Double, Double)) {
        bars.append(p)
        if bars.count >= maxBars {
            bars.remove(at: 0)
        }
        self.setNeedsDisplay()
    }


}

extension String {
    var hexColor: UIColor {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
