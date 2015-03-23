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

import ReactiveCocoa

/// Wraps an NSView or UIView with bindable properties for animations.
public struct RAN {
	private weak var view: View?
	private let willDealloc: SignalProducer<(), NoError>

	private var animator: View? {
		#if os(OSX)
			if runningInAnimation {
				return view.map { $0.animator() }
			}
		#endif

		return view
	}

	/// Creates a wrapper for the given view's properties.
	public init(_ view: View) {
		self.view = view
		self.willDealloc = view.rac_willDeallocSignal().toSignalProducer()
			|> map { _ in () }
			|> catch { error in
				assert(false, "rac_willDeallocSignal failed with error: \(error)")
				return .empty
			}
	}

	private func viewProperty<T>(setter: T -> ()) -> ViewProperty<T> {
		return ViewProperty(willDealloc: self.willDealloc, setter: setter)
	}

	public var frame: ViewProperty<CGRect> {
		return viewProperty { self.animator?.frame = $0 }
	}

	public var bounds: ViewProperty<CGRect> {
		return viewProperty { self.animator?.bounds = $0 }
	}

    #if os(iOS)
    public var center: ViewProperty<CGPoint> {
        return viewProperty { self.animator?.center = $0 }
    }
    
    public var backgroundColor: ViewProperty<UIColor> {
        return viewProperty { self.animator?.backgroundColor = $0 }
    }
    
    public var transform: ViewProperty<CGAffineTransform> {
        return viewProperty { self.animator?.transform = $0 }
    }
    #endif
    
	public var alpha: ViewProperty<CGFloat> {
		return viewProperty { value in
			#if os(OSX)
				self.animator?.alphaValue = value
			#elseif os(iOS)
				self.animator?.alpha = value
			#endif
		}
	}
}

/// A property on a view that can be animated.
public struct ViewProperty<T> {
	private let willDealloc: SignalProducer<(), NoError>
	private let setter: T -> ()
}

extension ViewProperty: SinkType {
	public func put(value: T) {
		setter(value)
	}
}

/// Binds a (potentially animated) signal to a view property.
public func <~ <T>(property: ViewProperty<T>, signal: Signal<T, NoError>) -> Disposable {
	let disposable = CompositeDisposable()
	let propertyDisposable = property.willDealloc.start(completed: {
		disposable.dispose()
	})

	disposable.addDisposable(propertyDisposable)

	let signalDisposable = signal.observe(next: property.setter, completed: {
		disposable.dispose()
	})

	disposable.addDisposable(signalDisposable)
	return disposable
}

/// Binds a (potentially animated) signal producer to a view property.
public func <~ <T>(property: ViewProperty<T>, producer: SignalProducer<T, NoError>) -> Disposable {
	var disposable: Disposable!

	producer.startWithSignal { signal, signalDisposable in
		property <~ signal
		disposable = signalDisposable

		property.willDealloc.start(completed: {
			signalDisposable.dispose()
		})
	}

	return disposable
}

/// Binds the view property to the latest values of `sourceProperty`.
public func <~ <T, P: PropertyType where P.Value == T>(destinationProperty: ViewProperty<T>, sourceProperty: P) -> Disposable {
	return destinationProperty <~ sourceProperty.producer
}
