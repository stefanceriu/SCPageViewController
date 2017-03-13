Pod::Spec.new do |s|
  s.name     = 'SCPageViewController'
  s.version  = '2.0.10'
  s.platform = :ios
  s.ios.deployment_target = '5.0'

  s.summary  = 'SCPageViewController is a container view controller similar to UIPageViewController which provies more control and is much more customizable'
  s.description = <<-DESC
                  SCPageViewController is a container view controller similar to UIPageViewController but which provies more control, is much more customizable and, arguably, has a better overall design. 
                  It supports the following features:

                  - Customizable transitions and animations (through layouters and custom easing functions)
                  - Incremental updates with user defined animations
                  - Bouncing and realistic physics
                  - Correct appearance calls, even while interactions are in progres
                  - Custom layouts and animated layout changes
                  - Vertical and horizontal layouts
                  - Pagination
                  - Content insets
                  - Completion blocks
                  - Customizable interaction area and number of touches required

                  and more..
                  DESC
  s.homepage = 'https://github.com/stefanceriu/SCPageViewController'
  s.author   = { 'Stefan Ceriu' => 'stefan.ceriu@yahoo.com' }
  s.social_media_url = 'https://twitter.com/stefanceriu'
  s.source   = { :git => 'https://github.com/stefanceriu/SCPageViewController.git', :tag => "v#{s.version}" }
  s.license      = { :type => 'MIT License', :file => 'LICENSE' }
  s.source_files = 'SCPageViewController/*', 'SCPageViewController/Layouters/*'
  s.requires_arc = true
  s.frameworks = 'UIKit', 'QuartzCore', 'CoreGraphics', 'Foundation'

  s.dependency 'SCScrollView', '~> 1.1'

end