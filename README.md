# SCPageViewController


SCPageViewController is a container view controller similar to UIPageViewController but which provides more control, is much more customizable and, arguably, has a better overall design. 
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

#### Screenshots

![](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/2.0/SCPageViewController%202.0.gif)

## Implementation details

SCPageViewController is build on top of an UIScrollView subclass ([SCScrollView](https://github.com/stefanceriu/SCScrollView)) which provides it with correct physics, callbacks for building the pagination, navigational constraints and custom transitions. It also can work with user defined interaction areas and minimum/maximum number of touches. It's worth noting that SCScrollView also powers [SCStackViewController](https://github.com/stefanceriu/SCStackViewController)

SCPageViewController relies on page layouters to know where to place each of the controllers at every point. Page layouters are built on top of a simple protocol with methods for providing the final and intermediate view controller frames, and custom animations for page insertions, deletions, moves and reloads. The demo project contains 4 examples: plain with inter-item spacings, parallax, sliding and cards.

## Usage

- Create a new instance and set its data source and delegate

```objc
    self.pageViewController = [[SCPageViewController alloc] init];
    [self.pageViewController setDataSource:self];
    [self.pageViewController setDelegate:self];
```

- SCPageViewController relies on layouters that define how pages are layed out. You can use one of the included ones or create a custom class that implements the SCPageLayouterProtocol.

```objc
    [self.pageViewController setLayouter:[[SCPageLayouter alloc] init] animated:NO completion:nil];
```

- Implement the SCPageViewControllerDataSource which defines the total number of pages and the view controllers to be used for each of them.

```objc
- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController;

- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex;
```

- Optionally, modify the following properties to your liking

```objc
    // Enable/disable pagination
    [self.pageViewController setPagingEnabled:NO];
    
    // Ignore navigation contraints (bounce between pages)
    [self.pageViewController setContinuousNavigationEnabled:YES];

    // Have the page view controller come to a rest slower
    [self.pageViewController setDecelerationRate:UIScrollViewDecelerationRateNormal];

    // Disable bouncing
    [self.pageViewController setBounces:NO];

    // Customize how many number of touches are required to interact with the pages
    [self.pageViewController setMinimumNumberOfTouches:2];
    [self.pageViewController setMaximumNumberOfTouches:1];
    
    // Allow interaction only in the specified area
    [self.pageViewController setTouchRefusalArea:[UIBezierPath bezierPathWithRect:CGRectInset(self.view.bounds, 50, 50)]];
    
    //Use different easing functions for animations and navigation
    [self.pageViewController setEasingFunction:[SCEasingFunction easingFunctionWithType:SCEasingFunctionTypeLinear]];
    
    // Change the default animation durations
    [self.pageViewController setAnimationDuration:1.0f];
```

#####Incremental updates
SCPageViewController also supports incremental updates and all the animations are customizable through the layouter.

```objc
	[self.pageViewController insertPagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:^(void)completion];

	[self.pageViewController deletePagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:^(void)completion]

	[self.pageViewController reloadPagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:^(void)completion]

	[self.pageViewController movePageAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated completion:^(void)completion]
```

#####Easing functions

SCPageViewController can work with custom easing functions defined through the SCEasingFunctionProtocol. It comes bundled with 31 different ones (thanks to AHEasing) and new ones can be created with ease.

* Ease In Out Back
![Plain+BackEaseInOut](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/BackEaseInOut-Page.gif)

* Ease Out Bounce
![Plain+BounceEaseOut](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/BounceEaseOut-Page.gif)
    
* Ease Out Elastic
![Plain+ElasticEaseOut](https://dl.dropboxusercontent.com/u/12748201/Recordings/SCPageViewController/ElasticEaseOut-Page.gif)

##### For more usage examples please have a look at the included demo project (or `pod try SCPageViewController`)

## License
SCPageViewController is released under the MIT License (MIT) (see the LICENSE file)

## Contact
Any suggestions or improvements are more than welcome and I would also love to know if you are using this component in a published application.
Feel free to contact me at [stefan.ceriu@yahoo.com](mailto:stefan.ceriu@yahoo.com) or [@stefanceriu](https://twitter.com/stefanceriu). 
