//
//  SignalLifetimeSpec.swift
//  ReactiveSwift
//
//  Created by Vadim Yelagin on 2015-12-13.
//  Copyright (c) 2015 GitHub. All rights reserved.
//

import Foundation

import Result
import Nimble
import Quick
import ReactiveSwift

class SignalLifetimeSpec: QuickSpec {
	override func spec() {
		describe("init") {
			var testScheduler: TestScheduler!

			beforeEach {
				testScheduler = TestScheduler()
			}

			it("should be disposed of if it does not have any observers") {
				var isDisposed = false

				weak var signal: Signal<AnyObject, NoError>? = {
					let signal: Signal<AnyObject, NoError> = Signal { _ in nil }
					return signal.on(disposed: { isDisposed = true })
				}()
				expect(signal).to(beNil())
				expect(isDisposed) == true
			}

			it("should be disposed of if no one retains it") {
				var isDisposed = false
				var signal: Signal<AnyObject, NoError>? = Signal { _ in nil }.on(disposed: { isDisposed = true })
				weak var weakSignal = signal

				expect(weakSignal).toNot(beNil())
				expect(isDisposed) == false

				var reference = signal
				signal = nil
				expect(weakSignal).toNot(beNil())
				expect(isDisposed) == false

				reference = nil
				expect(weakSignal).to(beNil())
				expect(isDisposed) == true
			}

			it("should be disposed of when the signal shell has deinitialized with no active observer regardless of whether the generator observer is retained or not") {
				var observer: Signal<AnyObject, NoError>.Observer?
				var isDisposed = false

				weak var signal: Signal<AnyObject, NoError>? = {
					let signal: Signal<AnyObject, NoError> = Signal { innerObserver in
						observer = innerObserver
						return nil
					}
					return signal.on(disposed: { isDisposed = true })
				}()
				expect(observer).toNot(beNil())
				expect(signal).to(beNil())
				expect(isDisposed) == true
			}

			it("should be disposed of when the generator observer has deinitialized even if it has an observer") {
				var isDisposed = false

				var disposable: Disposable? = nil
				weak var signal: Signal<AnyObject, NoError>? = {
					let signal: Signal<AnyObject, NoError> = Signal { _ in nil }
					disposable = signal.on(disposed: { isDisposed = true }).observe(Signal.Observer())
					return signal
				}()
				expect(signal).to(beNil())
				expect(isDisposed) == true

				disposable?.dispose()
				expect(signal).to(beNil())
				expect(isDisposed) == true
			}

			it("should be alive until erroring if it has at least one observer, despite not being explicitly retained") {
				var errored = false
				var isDisposed = false

				weak var signal: Signal<AnyObject, TestError>? = {
					let signal = Signal<AnyObject, TestError> { observer in
						testScheduler.schedule {
							observer.send(error: TestError.default)
						}
						return nil
					}
					signal.on(disposed: { isDisposed = true }).observeFailed { _ in errored = true }
					return signal
				}()

				expect(errored) == false
				expect(signal).to(beNil())
				expect(isDisposed) == false

				testScheduler.run()

				expect(errored) == true
				expect(signal).to(beNil())
				expect(isDisposed) == true
			}

			it("should be alive until completion if it has at least one observer, despite not being explicitly retained") {
				var completed = false
				var isDisposed = false

				weak var signal: Signal<AnyObject, NoError>? = {
					let signal = Signal<AnyObject, NoError> { observer in
						testScheduler.schedule {
							observer.sendCompleted()
						}
						return nil
					}
					signal.on(disposed: { isDisposed = true }).observeCompleted { completed = true }
					return signal
				}()

				expect(completed) == false
				expect(signal).to(beNil())
				expect(isDisposed) == false

				testScheduler.run()

				expect(completed) == true
				expect(signal).to(beNil())
				expect(isDisposed) == true
			}

			it("should be alive until interruption if it has at least one observer, despite not being explicitly retained") {
				var interrupted = false
				var isDisposed = false

				weak var signal: Signal<AnyObject, NoError>? = {
					let signal = Signal<AnyObject, NoError> { observer in
						testScheduler.schedule {
							observer.sendInterrupted()
						}

						return nil
					}
					signal.on(disposed: { isDisposed = true }).observeInterrupted { interrupted = true }
					return signal
				}()

				expect(interrupted) == false
				expect(signal).to(beNil())
				expect(isDisposed) == false

				testScheduler.run()

				expect(interrupted) == true
				expect(signal).to(beNil())
				expect(isDisposed) == true
			}
		}

		describe("Signal.pipe") {
			it("should deallocate") {
				weak var signal = Signal<(), NoError>.pipe().0

				expect(signal).to(beNil())
			}

			it("should be alive until erroring if it has at least one observer, despite not being explicitly retained") {
				let testScheduler = TestScheduler()
				var errored = false
				weak var weakSignal: Signal<(), TestError>?
				var isDisposed = false

				// Use an inner closure to help ARC deallocate things as we
				// expect.
				let test = {
					let (signal, observer) = Signal<(), TestError>.pipe()
					weakSignal = signal
					testScheduler.schedule {
						// Note that the input observer has a weak reference to the signal.
						observer.send(error: TestError.default)
					}
					signal.on(disposed: { isDisposed = true }).observeFailed { _ in errored = true }
				}
				test()

				expect(weakSignal).to(beNil())
				expect(isDisposed) == false
				expect(errored) == false

				testScheduler.run()

				expect(weakSignal).to(beNil())
				expect(isDisposed) == true
				expect(errored) == true
			}

			it("should be alive until completion if it has at least one observer, despite not being explicitly retained") {
				let testScheduler = TestScheduler()
				var completed = false
				weak var weakSignal: Signal<(), TestError>?
				var isDisposed = false

				// Use an inner closure to help ARC deallocate things as we
				// expect.
				let test = {
					let (signal, observer) = Signal<(), TestError>.pipe()
					weakSignal = signal
					testScheduler.schedule {
						// Note that the input observer has a weak reference to the signal.
						observer.sendCompleted()
					}
					signal.on(disposed: { isDisposed = true }).observeCompleted { completed = true }
				}
				test()

				expect(weakSignal).to(beNil())
				expect(isDisposed) == false
				expect(completed) == false

				testScheduler.run()

				expect(weakSignal).to(beNil())
				expect(isDisposed) == true
				expect(completed) == true
			}

			it("should be alive until interruption if it has at least one observer, despite not being explicitly retained") {
				let testScheduler = TestScheduler()
				var interrupted = false
				weak var weakSignal: Signal<(), NoError>?
				var isDisposed = false

				let test = {
					let (signal, observer) = Signal<(), NoError>.pipe()
					weakSignal = signal

					testScheduler.schedule {
						// Note that the input observer has a weak reference to the signal.
						observer.sendInterrupted()
					}

					signal.on(disposed: { isDisposed = true }).observeInterrupted { interrupted = true }
				}

				test()
				expect(weakSignal).to(beNil())
				expect(isDisposed) == false
				expect(interrupted) == false

				testScheduler.run()

				expect(weakSignal).to(beNil())
				expect(isDisposed) == true
				expect(interrupted) == true
			}
		}

		describe("testTransform") {
			it("should be disposed of") {
				var isDisposed = false
				weak var signal: Signal<AnyObject, NoError>? = Signal { _ in nil }
					.testTransform()
					.on(disposed: { isDisposed = true })

				expect(signal).to(beNil())
				expect(isDisposed) == true
			}

			it("should be disposed of if it is not explicitly retained and its generator observer is not retained") {
				var disposable: Disposable? = nil
				var isDisposed = false

				weak var signal: Signal<AnyObject, NoError>? = {
					let signal: Signal<AnyObject, NoError> = Signal { _ in nil }.testTransform()
					disposable = signal.on(disposed: { isDisposed = true }).observe(Signal.Observer())
					return signal
				}()
				expect(signal).to(beNil())
				expect(isDisposed) == true
			}

			it("should deallocate if it is unreachable and has no observer") {
				let (sourceSignal, sourceObserver) = Signal<Int, NoError>.pipe()

				var firstCounter = 0
				var secondCounter = 0
				var thirdCounter = 0

				func run() {
					_ = sourceSignal
						.map { value -> Int in
							firstCounter += 1
							return value
						}
						.map { value -> Int in
							secondCounter += 1
							return value
						}
						.map { value -> Int in
							thirdCounter += 1
							return value
						}
				}

				run()

				sourceObserver.send(value: 1)
				expect(firstCounter) == 0
				expect(secondCounter) == 0
				expect(thirdCounter) == 0

				sourceObserver.send(value: 2)
				expect(firstCounter) == 0
				expect(secondCounter) == 0
				expect(thirdCounter) == 0
			}

			it("should not deallocate if it is unreachable but still has at least one observer") {
				let (sourceSignal, sourceObserver) = Signal<Int, NoError>.pipe()

				var firstCounter = 0
				var secondCounter = 0
				var thirdCounter = 0

				var disposable: Disposable?

				func run() {
					disposable = sourceSignal
						.map { value -> Int in
							firstCounter += 1
							return value
						}
						.map { value -> Int in
							secondCounter += 1
							return value
						}
						.map { value -> Int in
							thirdCounter += 1
							return value
						}
						.observe { _ in }
				}

				run()

				sourceObserver.send(value: 1)
				expect(firstCounter) == 1
				expect(secondCounter) == 1
				expect(thirdCounter) == 1

				sourceObserver.send(value: 2)
				expect(firstCounter) == 2
				expect(secondCounter) == 2
				expect(thirdCounter) == 2

				disposable?.dispose()

				sourceObserver.send(value: 3)
				expect(firstCounter) == 2
				expect(secondCounter) == 2
				expect(thirdCounter) == 2
			}
		}

		describe("observe") {
			var signal: Signal<Int, TestError>!
			var observer: Signal<Int, TestError>.Observer!

			var token: NSObject? = nil
			weak var weakToken: NSObject?

			func expectTokenNotDeallocated() {
				expect(weakToken).toNot(beNil())
			}

			func expectTokenDeallocated() {
				expect(weakToken).to(beNil())
			}

			beforeEach {
				let (signalTemp, observerTemp) = Signal<Int, TestError>.pipe()
				signal = signalTemp
				observer = observerTemp

				token = NSObject()
				weakToken = token

				signal.observe { [token = token] _ in
					_ = token!.description
				}
			}

			it("should deallocate observe handler when signal completes") {
				expectTokenNotDeallocated()

				observer.send(value: 1)
				expectTokenNotDeallocated()

				token = nil
				expectTokenNotDeallocated()

				observer.send(value: 2)
				expectTokenNotDeallocated()

				observer.sendCompleted()
				expectTokenDeallocated()
			}

			it("should deallocate observe handler when signal fails") {
				expectTokenNotDeallocated()

				observer.send(value: 1)
				expectTokenNotDeallocated()

				token = nil
				expectTokenNotDeallocated()

				observer.send(value: 2)
				expectTokenNotDeallocated()

				observer.send(error: .default)
				expectTokenDeallocated()
			}
		}
	}
}

private extension Signal {
	func testTransform() -> Signal<Value, Error> {
		return Signal { observer in
			return self.observe(observer.action)
		}
	}
}
