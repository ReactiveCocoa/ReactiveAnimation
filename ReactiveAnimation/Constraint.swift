//
//  Constraint.swift
//  ReactiveAnimation
//
//  Created by Indragie on 3/25/15.
//  Copyright (c) 2015 ReactiveCocoa. All rights reserved.
//

import Foundation
import ReactiveCocoa

// Wraps an NSLayoutConstraint for animating its constant using signals.
public struct RANConstraint {
	private weak var layoutConstraint: NSLayoutConstraint?
	private let willDealloc: SignalProducer<(), NoError>
	
	// Creates a wrapper for the given layout constraint.
	public init(_ layoutConstraint: NSLayoutConstraint) {
		self.layoutConstraint = layoutConstraint
		self.willDealloc = layoutConstraint.rac_willDeallocSignal().toSignalProducer()
			|> map { _ in () }
			|> catch { error in
				assert(false, "rac_willDeallocSignal failed with error: \(error)")
				return .empty
		}
	}
}

extension RANConstraint: SinkType {
	public mutating func put(x: CGFloat) {
		layoutConstraint?.constant = x
	}
}

/// Wraps an NSLayoutConstraint in a RANConstraint.
public func RAN(layoutConstraint: NSLayoutConstraint) -> RANConstraint {
	return RANConstraint(layoutConstraint)
}

/// Binds a (potentially animated) signal to the constant of a constraint.
public func <~ (constraint: RANConstraint, signal: Signal<CGFloat, NoError>) -> Disposable {
	let disposable = CompositeDisposable()
	let constraintDisposable = constraint.willDealloc.start(completed: {
		disposable.dispose()
	})
	
	disposable.addDisposable(constraintDisposable)
	
	let signalDisposable = signal.observe(next: {
		constraint.layoutConstraint?.constant = $0
	}, completed: {
		disposable.dispose()
	})
	
	disposable.addDisposable(signalDisposable)
	return disposable
}

/// Binds a (potentially animated) signal producer to the constant of a constraint.
public func <~ (constraint: RANConstraint, producer: SignalProducer<CGFloat, NoError>) -> Disposable {
	var disposable: Disposable!
	
	producer.startWithSignal { signal, signalDisposable in
		constraint <~ signal
		disposable = signalDisposable
		
		constraint.willDealloc.start(completed: {
			signalDisposable.dispose()
		})
	}
	
	return disposable
}

// Binds the constraint's constant to the latest values of `sourceProperty`.
public func <~ <P: PropertyType where P.Value == CGFloat>(destinationConstraint: RANConstraint, sourceProperty: P) -> Disposable {
	return destinationConstraint <~ sourceProperty.producer
}
