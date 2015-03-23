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
		#if os(iOS)
			= UIViewAnimationCurve.EaseInOut
		#endif

	/// Begins the animation slowly and speeds up to a stop.
	case EaseIn
		#if os(iOS)
			= UIViewAnimationCurve.EaseIn
		#endif

	/// Begins the animation quickly and slows down to a stop.
	case EaseOut
		#if os(iOS)
			= UIViewAnimationCurve.EaseOut
		#endif

	/// Animates with the same pace over the duration of the animation.
	case Linear
		#if os(iOS)
			= UIViewAnimationCurve.Linear
		#endif

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

extension AnimationCurve: Printable {
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
