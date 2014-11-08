# SCPageViewController


SCPageViewController is a container view controller which allows you to paginate other view controllers and build custom transitions between them while providing correct physics and appearance calls.

It was build with the following points in mind:

1. Vertical or horizontal navigation
2. Customizable transitions and animations (through layouters and easing functions)
3. Pagination
4. Realistic physics
5. Correct appearance calls
6. Customizable interaction area
7. Completion blocks
and more..

### Change Log v1.1.0

* Switched to SCScrollView
* Drops CAMediaTimingFunction in favour of [AHEasing](https://github.com/warrenm/AHEasing) for more animation options and control (31 easing functions available ootb with support for creating custom ones through the SCEasingFunctionProtocol)
* Fixes display link retain cycles
* Allows content offset animation interruption
* Various other tweaks and fixes

* New easing functions examples
    * Ease In Out Back
![Plain+BackEaseInOut](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/BackEaseInOut-Page.gif)

    * Ease Out Bounce
![Plain+BounceEaseOut](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/BounceEaseOut-Page.gif)
    
    * Ease Out Elastic
![Plain+ElasticEaseOut](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/ElasticEaseOut-Page.gif)

## Screenshots

![Parallax+Sliding+Plain](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/SCPageViewController.gif)

## Implementation details

SCPageViewController is build on top of an UIScrollView which gives us the physics we need, content insets for all the 4 positions, callbacks for linking the custom transitions to and easy to build pagination. By overriding the scrollView's shouldReceiveTouch: method we also get the customizable interaction area.

The controller stack relies on layouters to know where to place each of the controllers at every point. They are build on top of a simple protocol and the demo project contains 4 examples with various effects.

## Usage

- Import the controller into your project

```
#import "SCPageViewController.h"
```

- Create a new instance and set its data source and delegate

```
	self.pageViewController = [[SCPageViewController alloc] init];
    [self.pageViewController setDataSource:self];
    [self.pageViewController setDelegate:self];
```

- Set a layouter

```
	[self.pageViewController setLayouter:[[SCPageLayouter alloc] init] animated:NO completion:nil];
```

- Set other optional properties

```
	[self.pageViewController setPagingEnabled:NO];

    [self.pageViewController setContinuousNavigationEnabled:YES];

    [self.pageViewController setDecelerationRate:UIScrollViewDecelerationRateNormal];

    [self.pageViewController setBounces:NO];

    [self.pageViewController setMinimumNumberOfTouches:2];
    [self.pageViewController setMaximumNumberOfTouches:1];

    [self.pageViewController setTouchRefusalArea:[UIBezierPath bezierPathWithRect:CGRectInset(self.view.bounds, 50, 50)]];
    
    [self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
    [self.pageViewController setAnimationDuration:1.0f];
```


- And, finally, implement the SCPageViewControllerDataSource

```
- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController;
- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex;
```

######Check out the demo project for more details.

## License
SCPageViewController is released under the MIT License (MIT) (see the LICENSE file)

## Contact
Any suggestions or improvements are more than welcome.
Feel free to contact me at [stefan.ceriu@yahoo.com](mailto:stefan.ceriu@yahoo.com) or [@stefanceriu](https://twitter.com/stefanceriu).
