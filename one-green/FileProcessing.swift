//
//  S3.swift
//  Ayero
//
//  Created by Yahor Paulikau on 7/17/17.
//  Copyright © 2017 OneGreen. All rights reserved.
//

import Foundation
import AWSS3


func getListOfLogFiles() -> [URL] {
    let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    do {
        // Get the directory contents urls (including subfolders urls)
        let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
        
        // if you want to filter the directory contents you can do like this:
        let textFiles = directoryContents.filter{ $0.pathExtension == "txt" }
        return textFiles.map{ $0.absoluteURL }
    } catch let error as NSError {
        print(error)
        return []
    }
}


func renameFile(fileName: String, newFileName: String) {
    do {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentDirectory = URL(fileURLWithPath: path)
        let originPath = documentDirectory.appendingPathComponent(fileName)
        let destinationPath = documentDirectory.appendingPathComponent(newFileName)
        try FileManager.default.moveItem(at: originPath, to: destinationPath)
    } catch {
        print(error)
    }
}

func syncDocumentsToS3 () {
    let files = getListOfLogFiles()
    
    for fileURL in files {
        let key = fileURL.lastPathComponent

        let transferManager = AWSS3TransferManager.default()
        
        if let uploadRequest = AWSS3TransferManagerUploadRequest() {
            uploadRequest.bucket = Constants.S3_BUCKET_NAME
            uploadRequest.key = "upload/" + userIdentifier + "/" + key
            //uploadRequest.contentType = "text/plain"
            uploadRequest.body = fileURL
        
            transferManager.upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
                
                if let error = task.error as NSError? {
                    if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch code {
                        case .cancelled, .paused:
                            break
                        default:
                            print("Error uploading: \(String(describing: uploadRequest.key)) Error: \(error)")
                        }
                    } else {
                        print("Error uploading: \(String(describing: uploadRequest.key)) Error: \(error)")
                    }
                    return nil
                }
                
                if (task.result != nil) {
                    renameFile(fileName: fileURL.absoluteString, newFileName: fileURL.absoluteString + ".done")
                    print("Upload complete for: \(String(describing: uploadRequest.key))")
                }
                return nil
            })
        }

        //let transferUtility = AWSS3TransferUtility.default()
        
        /*transferUtility.uploadFile(fileURL!,
            bucket: Constants.S3_BUCKET_NAME,
            key: file,
            contentType: "text",
            expression: nil,
            completionHandler: nil).continueWith {
                (task) -> AnyObject! in if let error = task.error {
                    print("Error: \(error)")
                }

                if let _ = task.result {
                    renameFile(fileName: file, newFileName: file + ".done")
                }
                return nil;
            }*/
    }
}
