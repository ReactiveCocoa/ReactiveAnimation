Pod::Spec.new do |s|
  s.name         = "ReactiveAnimation"
  s.version      = "0.1"
  s.summary      = "Declarative animations using ReactiveCocoa signals"
  s.homepage     = "https://github.com/ohwutup/ReactiveAnimation"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Josh Abernathy": "josh@github.com" }
  s.platform     = :ios, '8.0'
  s.source       = { :git => "https://github.com/ohwutup/ReactiveAnimation.git", :tag => "0.1" }
  s.source_files = 'ReactiveAnimation/*.{h,m}'
  s.frameworks   = 'UIKit'
  s.requires_arc = 'true'
end