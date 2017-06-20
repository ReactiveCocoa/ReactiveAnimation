//
//  ViewController.swift
//  ReactiveAnimationDemo_iOS
//
//  Created by Markus Chmelar on 16/06/2017.
//  Copyright © 2017 Innovaptor OG. All rights reserved.
//

import UIKit

import ReactiveSwift
import ReactiveCocoa
import ReactiveAnimation

class ViewController: UIViewController {
  @IBOutlet weak var label: UILabel!
  
  private func randomPoint() -> CGPoint {
    let random: (CGFloat) -> CGFloat = { max in
        return CGFloat(arc4random_uniform(UInt32(max)))
    }
    
    let x = random(view.frame.size.width)
    let y = random(view.frame.size.height)
    
    return CGPoint(x: x, y: y)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    label.reactive.center <~ SignalProducer.timer(interval: .seconds(1), on: QueueScheduler.main)
      .map { _ in return self.randomPoint() }
      // In order to demonstrate different flatten strategies,
      // the animation duration is larger than the animation interval,
      // thus a new animation begins before the running animation is finished
      .animateEach(duration: 1.5, curve: .EaseInOut)
      // With the .concat flatten strategy, each animations are concatenated.
      // Each animation finisheds, before the next one starts.
      // This also means, that animations are queued
      .flatten(.concat)
      // With the .merge flatten strategy, each animation is performed immediately
      // If an animation is currently running, it is cancelled and the next animation starts from the current animation state
//      .flatten(.merge)
  }
}

