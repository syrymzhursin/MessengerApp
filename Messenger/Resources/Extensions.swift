//
//  Extensions.swift
//  Messenger
//
//  Created by User on 7/15/20.
//  Copyright © 2020 Syrym Zhursin. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    public var width: CGFloat {
        return frame.size.width
    }
    
    public var height: CGFloat {
         return frame.size.height
     }
    
    public var top: CGFloat {
        return frame.origin.y
     }
    
    public var bottom: CGFloat {
        return frame.size.height + frame.origin.y
     }
    
    public var left: CGFloat {
        return frame.origin.x
     }
    
    public var right: CGFloat {
        return frame.size.width + frame.origin.x
     }
}

extension Notification.Name {
    /// Notification when user logs in
    static let didLogInNotification = Notification.Name("didLogInNotification")
}
