//
//  Animation.swift
//  ReactiveAnimation
//
//  Created by Justin Spahr-Summers on 2015-03-22.
//  Copyright (c) 2015 ReactiveCocoa. All rights reserved.
//

#if os(OSX)
	import AppKit

	public typealias AnimationCurveRawValue = Int
#elseif os(iOS)
	import UIKit

	public typealias AnimationCurveRawValue = UIViewAnimationCurve.RawValue
#endif

import ReactiveSwift
import ReactiveCocoa
import enum Result.NoError

/// Creates an animated SignalProducer for each value that arrives on
/// `producer`.
///
/// The `JoinStrategy` used on the inner producers will hint to
/// ReactiveAnimation whether the animations should be interruptible:
///
///  - `Concat` will result in new animations only beginning after all previous
///    animations have completed.
///  - `Merge` or `Latest` will start new animations as soon as possible, and
///    use the current (in progress) UI state for animating.
///
/// These animation behaviors are only a hint, and the framework may not be able
/// to satisfy them.
///
/// However the inner producers are joined, binding the resulting stream of
/// values to a view property will result in those value changes being
/// automatically animated.
///
/// To delay an animation, use delay() or throttle() _before_ this function.
/// Because the aforementioned operators delay delivery of `Next` events,
/// applying them _after_ this function may cause values to be delivered outside
/// of any animation block.
///
/// Examples
///
/// RAN(self.textField).alpha <~ alphaValues
///                              |> animateEach(duration: 0.2)
///	                             /* Animate alpha without interruption. */
///                              |> join(.Concat)
///
///	RAN(self.button).alpha <~ alphaValues
///                           /* Delay animations by 0.1 seconds. */
///                           |> delay(0.1)
///                           |> animateEach(curve: .Linear)
///                           /* Animate alpha, and interrupt for new animations. */
///                           |> join(.Latest)
///
/// Returns a producer of producers, where each inner producer sends one `next`
/// that corresponds to a value from the receiver, then completes when the
/// animation corresponding to that value has finished. Deferring the events of
/// the returned producer or having them delivered on another thread is considered
/// undefined behavior.


extension Signal {
  public func animateEach(duration: TimeInterval? = nil, curve: AnimationCurve = .Default) -> Signal<SignalProducer<Value, NoError>, Error> {
    return self.map { value in
      return SignalProducer { observer, lifetime in
        OSAtomicIncrement32(&runningInAnimationCount)
        lifetime.observeEnded {
          OSAtomicDecrement32(&runningInAnimationCount)
        }
        
        #if os(OSX)
        NSAnimationContext.runAnimationGroup({ context in
          if let duration = duration {
            context.duration = duration
          }
          
          if curve != .Default {
            context.timingFunction = CAMediaTimingFunction(name: curve.mediaTimingFunction)
          }
          
          observer.send(value: value as! Value) // TODO: Why is the downcast necessary?
        }, completionHandler: {
          // Avoids weird AppKit deadlocks when interrupting an
          // existing animation.
          UIScheduler().schedule {
            observer.sendCompleted()
          }
        })
        #elseif os(iOS)
        var options: UIViewAnimationOptions = [
          UIViewAnimationOptions(rawValue: UInt(curve.rawValue)),
          .layoutSubviews,
          .beginFromCurrentState]
          
        if curve != .Default {
          options.formUnion(.overrideInheritedCurve)
        }
          
        UIView.animate(withDuration: duration ?? 0.2, delay: 0, options: options, animations: {
          observer.send(value: value as! Value) // TODO: Why is the downcast necessary?
        }, completion: { finished in
          if(finished) {
            observer.sendCompleted()
          } else {
            observer.sendInterrupted()
          }
        })
        #endif
      }
    }
  }
}


extension SignalProducer {
  public func animateEach(duration: TimeInterval? = nil, curve: AnimationCurve = .Default) -> SignalProducer<SignalProducer<Value, NoError>, Error> {
    return self.lift { $0.animateEach(duration: duration, curve: curve) }
  }
}


/// The number of animated signals in the call stack.
///
/// This variable should be manipulated with OSAtomic functions.
private var runningInAnimationCount: Int32 = 0

/// Determines whether the calling code is running from within an animation
/// definition.
///
/// This can be used to conditionalize behavior based on whether a signal
/// somewhere in the chain is supposed to be animated.
///
/// This property is thread-safe.
public var runningInAnimation: Bool {
	return runningInAnimationCount > 0
}

/// Describes the curve (timing function) for an animation.
public enum AnimationCurve: AnimationCurveRawValue, Equatable {
	/// The default or inherited animation curve.
	case Default = 0

	/// Begins the animation slowly, speeds up in the middle, then slows to
	/// a stop.
  case EaseInOut
  case EaseIn
  case EaseOut
  case Linear
//  #if os(iOS)
//    case EaseInOut = UIViewAnimationCurve.EaseInOut.rawValue
//  #else
//    case EaseInOut
//  #endif
//
//  /// Begins the animation slowly and speeds up to a stop.
//  case EaseIn
//    #if os(iOS)
//      = UIViewAnimationCurve.EaseIn
//    #endif
//
//  /// Begins the animation quickly and slows down to a stop.
//  case EaseOut
//    #if os(iOS)
//      = UIViewAnimationCurve.EaseOut
//    #endif
//
//  /// Animates with the same pace over the duration of the animation.
//  case Linear
//    #if os(iOS)
//      = UIViewAnimationCurve.Linear
//    #endif
  
	/// The name of the CAMediaTimingFunction corresponding to this curve.
	public var mediaTimingFunction: String {
    
		switch self {
		case .Default:
			return kCAMediaTimingFunctionDefault

		case .EaseInOut:
			return kCAMediaTimingFunctionEaseInEaseOut

		case .EaseIn:
			return kCAMediaTimingFunctionEaseIn

		case .EaseOut:
			return kCAMediaTimingFunctionEaseOut

		case .Linear:
			return kCAMediaTimingFunctionLinear
		}
	}
}

public func == (lhs: AnimationCurve, rhs: AnimationCurve) -> Bool {
	switch (lhs, rhs) {
	case (.Default, .Default), (.EaseInOut, .EaseInOut), (.EaseIn, .EaseIn), (.EaseOut, .EaseOut), (.Linear, .Linear):
		return true
	
	default:
		return false
	}
}

extension AnimationCurve: CustomStringConvertible {
	public var description: String {
		switch self {
		case .Default:
			return "Default"

		case .EaseInOut:
			return "EaseInOut"

		case .EaseIn:
			return "EaseIn"

		case .EaseOut:
			return "EaseOut"

		case .Linear:
			return "Linear"
		}
	}
}
