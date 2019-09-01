//
//  Accelerometer.swift
//  Ayero
//
//  Created by Yahor Paulikau on 7/10/17.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import Foundation
import CoreMotion


typealias XyzVector = (x:Double, y:Double, z:Double)


class GyroSensor {
    func getData(_ rotation: CMRotationRate) -> XyzVector {
        return (0, 0, 0)
    }
}


class GravitySensor {
    
    var run_gr_x: Double = 0.0
    var run_gr_y: Double = 0.0
    var run_gr_z: Double = 0.0
    var gravityArray: [(gr_x: Double, gr_y: Double, gr_z: Double)] = []
    
    var gravityTicks: Int = 0

    init(ticks: Int) {
        gravityTicks = ticks
    }

    func getData(_ gravity: CMAcceleration) -> XyzVector {
        run_gr_x += gravity.x
        run_gr_y += gravity.y
        run_gr_z += gravity.z
        
        if (gravityArray.count > gravityTicks) {
            run_gr_x -= gravityArray[0].gr_x
            run_gr_y -= gravityArray[0].gr_y
            run_gr_z -= gravityArray[0].gr_z
            gravityArray.remove(at: 0)
        }
        
        // gravity vector
        let avg_gr_x = run_gr_x / Double(gravityTicks)
        let avg_gr_y = run_gr_y / Double(gravityTicks)
        let avg_gr_z = run_gr_z / Double(gravityTicks)
        let grTotal = abs(avg_gr_x) + abs(avg_gr_y) + abs(avg_gr_z)
            
        return (abs(avg_gr_x) / grTotal,
          abs(avg_gr_y) / grTotal,
          abs(avg_gr_z) / grTotal)
    }

}


class AccelerometerWrapper {

    var filtX: Double = 0.0
    var filtY: Double = 0.0
    var filtZ: Double = 0.0
    var alpha: Double = 0.0
    var accMA: Int = 25
    var MAV:   [(dx: Double, dy: Double, dz: Double)] = []

    
    init(alpha: Double, accMA: Int) {
        self.alpha = alpha
        self.accMA = accMA
    }
    
    
    func getData (_ acceleration: CMAcceleration, gravityCorrection: XyzVector) -> (Double, XyzVector) {
        let accX = acceleration.x
        let accY = acceleration.y
        let accZ = acceleration.z

        var d: XyzVector;
        d.x = lowFrequencyFilt(alpha, &filtX, accX)
        d.y = lowFrequencyFilt(alpha, &filtY, accY)
        d.z = lowFrequencyFilt(alpha, &filtZ, accZ)
        
        // moving average of deltas
        MAV.append((d.x, d.y, d.z))
        let mav_len = MAV.count
        if (mav_len >= self.accMA) {
            MAV.remove(at: 0)
        }
        
        var x_ma = 0.0, y_ma = 0.0, z_ma = 0.0
        for item in MAV {
            x_ma += item.dx
            y_ma += item.dy
            z_ma += item.dz
        }
        x_ma = x_ma / Double(self.accMA)
        y_ma = y_ma / Double(self.accMA)
        z_ma = z_ma / Double(self.accMA)
        
        // calculating delta penalty and cancelling movement along gravity vector
        let v_corr = x_ma - x_ma * gravityCorrection.x
            + y_ma - y_ma * gravityCorrection.y
            + z_ma - z_ma * gravityCorrection.z
        
        return (v_corr, d)

    }
}
