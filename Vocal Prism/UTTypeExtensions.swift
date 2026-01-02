//
//  UTTypeExtensions.swift
//  Vocal Prism
//
//  Created by Aarush Prakash on 12/7/25.
//

import Foundation
import UniformTypeIdentifiers

// Extension to support additional audio file types
extension UTType {
    static var flac: UTType {
        UTType(filenameExtension: "flac") ?? .audio
    }
    
    static var m4a: UTType {
        UTType(filenameExtension: "m4a") ?? .mpeg4Audio
    }
}
