//
//  NSCosteliqueSwift.swift
//  Photo Wall - Collage Maker
//
//  Created by Олег on 12.12.2017.
//  Copyright © 2017 Олег. All rights reserved.
//

import Cocoa

class NSCosteliqueSwift: NSObject {
    
}

extension NSImage {
    convenience init?(_ name: String) {
        self.init(named: NSImage.Name(rawValue: name))
    }
}

extension Array {
    var randomObject:Element? {
        if self.count > 0 {
            return (self as NSArray).randomObject() as? Element
        }
        return nil
    }
}

extension NSColor {
    convenience init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        self.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
}

extension CGRect {
    func roundcg(_ cfloat: CGFloat) -> CGFloat {
        return CGFloat(Darwin.round(Double(cfloat)) )
    }
    
    var round: CGRect {
        return CGRect(x: roundcg(origin.x), y: roundcg(origin.y), width: roundcg(size.width), height: roundcg(size.height))
    }
}
