Pod::Spec.new do |s|
  s.name         = "MCSFishEyeView"
  s.version      = "1.0"
  s.summary      = "The fisheye from Bubble Browser for iPad."
  s.homepage     = "https://github.com/macoscope/MCSFishEyeView"
  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author       = { "Bartosz Ciechanowski" => "ciechan@gmail.com" }
  s.source       = { :git => "https://github.com/macoscope/MCSFishEyeView.git", :tag => "1.0" }
  s.platform     = :ios
  s.source_files = 'FishEyeView/*.{h,m}'
  s.requires_arc = true
  s.frameworks   = 'QuartzCore', 'CoreGraphics'
  s.ios.deployment_target = '5.0'
end
