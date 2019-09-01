//
//  Shared.swift
//  Ayero
//
//  Created by Yahor Paulikau on 6/26/17.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import Foundation
import UIKit

// Constants
struct Constants {
    static let S3_BUCKET_NAME = "ayero-tracking"
}


// Support functions //

func mapColor2Penalty(penalty: Double, penaltyMax: Double) -> UIColor {
    let colors: [String] = [
        "#00ffff","#00faff","#00f5ff","#00f0ff","#00ebff","#00e6ff","#00e1ff","#00dcff",
        "#00d7ff","#00d2ff","#00cdff","#00c8ff","#00c3ff","#00beff","#00b4ff","#00afff",
        "#00aaff","#00a5ff","#00a0ff","#009bff","#0096ff","#0091ff","#008cff","#0087ff",
        "#0082ff","#007dff","#0078ff","#0073ff","#006eff","#0069ff","#0064ff","#005fff",
        "#005aff","#0050ff","#004bff","#0046ff","#0041ff","#003cff","#0037ff","#0032ff",
        "#002dff","#0028ff","#0023ff","#001eff","#0019ff","#0014ff","#000fff","#000aff",
        "#0000ff","#0500ff","#0a00ff","#0f00ff","#1400ff","#1900ff","#1e00ff","#2300ff",
        "#2800ff","#2d00ff","#3200ff","#3700ff","#3c00ff","#4100ff","#4600ff","#4600ff",
        "#4b00ff","#5000ff","#5500ff","#5a00ff","#5f00ff","#6400ff","#6900ff","#6e00ff",
        "#7300ff","#7800ff","#7d00ff","#8200ff","#8700ff","#8c00ff","#9100ff","#9600ff",
        "#9b00ff","#a000ff","#a500ff","#aa00ff","#af00ff","#b400ff","#b900ff","#be00ff",
        "#c300ff","#C800FF","#CD00FF","#D200FF","#D700FF","#DC00FF","#E100FF","#E600FF",
        "#EB00FF","#F000FF","#F500FF","#FA00FF","#FF00FF","#FF00FA","#FF00F5","#FF00F0",
        "#FF00EB","#FF00E6","#FF00E1","#FF00DC","#FF00D7","#FF00D2","#FF00CD","#FF00C8",
        "#FF00C3","#FF00BE","#FF00B9","#FF00B4","#FF00AF","#FF00AA","#FF00A5","#FF00A0",
        "#FF009B","#FF0096","#FF0091","#FF008C","#FF0087","#FF0082","#FF007D","#FF0078",
        "#FF0073","#FF006E","#FF0069","#FF0064","#FF005F","#FF005A","#FF0055","#FF0050",
        "#FF004B","#FF0046","#FF0041","#FF003C","#FF0037","#FF0032","#FF002D","#FF0028",
        "#FF0023","#FF001E","#FF0019","#FF0014","#FF000F","#FF000A","#FF0005","#FF0000",
    ]
    
    var ind = Int(penalty / Double(penaltyMax) * Double(colors.count-1))
    ind = min(colors.count-1, ind)
    
    return hexStringToUIColor(hex:colors[ind])
}
    

func readFromFile(fileName: String) -> [(penalty:Double, lat:Double, long:Double, speed:Double)] {
    var res: [(penalty:Double, lat:Double, long:Double, speed:Double)] = []
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileUrl = dir.appendingPathComponent(fileName)
        
        do {
            let file = try String(contentsOf: fileUrl)
            let rows = file.components(separatedBy: .newlines)
            for row in rows {
                if (row == "") { continue }
                let fields = row.components(separatedBy: ",")
                //print(fields)
                if (fields.count == 5) {
                    let pen  = Double(fields[1])
                    let lat  = Double(fields[2])
                    let long = Double(fields[3])
                    let speed = Double(fields[4])
                    res.append((pen!, lat!, long!, speed!))
                }
            }
        } catch {
            print(error)
        }
    }
    return res
}


func writeToFile(content: String, fileName: String) {
    let contentToAppend = content + "\n"
    let filePath = NSHomeDirectory() + "/Documents/" + fileName
    
    //Check if file exists
    if let fileHandle = FileHandle(forWritingAtPath: filePath) {
        //Append to file
        fileHandle.seekToEndOfFile()
        fileHandle.write(contentToAppend.data(using: String.Encoding.utf8)!)
    }
    else {
        //Create new file
        do {
            try contentToAppend.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Error creating \(filePath)")
        }
    }
}


func lowFrequencyFilter(alpha: Double, valFilt: Double, valAcc: Double) -> (delta: Double, value: Double) {
    let newFilt = valFilt + alpha * (valAcc - valFilt)
    return (newFilt - valFilt, newFilt)
}

func lowFrequencyFilt(_ alpha: Double, _ valFilt: inout Double, _ valAcc: Double) -> Double {
    let newFilt = valFilt + alpha * (valAcc - valFilt)
    return newFilt - valFilt
}


func hexStringToUIColor (hex:String) -> UIColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if (cString.hasPrefix("#")) {
        cString.remove(at: cString.startIndex)
    }
    
    if ((cString.characters.count) != 6) {
        return UIColor.gray
    }
    
    var rgbValue:UInt32 = 0
    Scanner(string: cString).scanHexInt32(&rgbValue)
    
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

    
