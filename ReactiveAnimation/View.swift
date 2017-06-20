//
//  View.swift
//  ReactiveAnimation
//
//  Created by Justin Spahr-Summers on 2015-03-22.
//  Copyright (c) 2015 ReactiveCocoa. All rights reserved.
//

#if os(OSX)
  import AppKit

  public typealias View = NSView
#elseif os(iOS)
  import UIKit

  public typealias View = UIView
#endif

import ReactiveSwift
import ReactiveCocoa
import enum Result.NoError

extension Reactive where Base: View {
  public var frame: BindingTarget<CGRect> {
    return makeBindingTarget { $0.frame = $1 }
  }
  
  public var bounds: BindingTarget<CGRect> {
    return makeBindingTarget { $0.bounds = $1 }
  }
  
  #if os(iOS)
  public var center: BindingTarget<CGPoint> {
    return makeBindingTarget { $0.center = $1 }
  }
  
  public var backgroundColor: BindingTarget<UIColor> {
    return makeBindingTarget { $0.backgroundColor = $1 }
  }
  
  public var transform: BindingTarget<CGAffineTransform> {
    return makeBindingTarget { $0.transform = $1 }
  }
  #endif
  
  public var alpha: BindingTarget<CGFloat> {
    return makeBindingTarget {
      #if os(OSX)
        $0.alphaValue = $1
      #elseif os(iOS)
        $0.alpha = $1
      #endif
    }
  }
  
  #if os(OSX)
  public var frameOrigin: BindingTarget<CGPoint> {
    return viewProperty { $0.setFrameOrigin($1) }
  }
  
  public var frameSize: BindingTarget<CGSize> {
    return viewProperty { $0.setFrameSize($1) }
  }
  
  public var boundsOrigin: BindingTarget<CGPoint> {
    return viewProperty { $0.setBoundsOrigin($1) }
  }
  
  public var boundsSize: BindingTarget<CGSize> {
    return viewProperty { $0.setBoundsSize($1) }
  }
  #endif
}
