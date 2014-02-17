//
//  SCPageViewController.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

@protocol SCPageViewControllerDataSource;
@protocol SCPageViewControllerDelegate;
@protocol SCPageLayouterProtocol;

@interface SCPageViewController : UIViewController

/**
 * Reloads and re-layouts all the pages in the page view controller
 */
- (void)reloadData;

/**
 * The currently used layouter
 */
@property (nonatomic, strong) id<SCPageLayouterProtocol> layouter;


/**
 * Page view controller's data source
 */
@property (nonatomic, weak) id<SCPageViewControllerDataSource> dataSource;


/**
 * Page view controller's delegate
 */
@property (nonatomic, weak) id<SCPageViewControllerDelegate> delegate;


/**
 * The current page in the page view controller
 */
@property (nonatomic, readonly) NSUInteger currentPage;


/**
 * An array of currently visible view controllers in the page view controller
 */
@property (nonatomic, readonly) NSArray *visibleViewControllers;


/**
 * @param pageIndex The page index to navigate to
 * @param animated Whether the transition will be animated
 */
- (void)navigateToPageAtIndex:(NSUInteger)pageIndex animated:(BOOL)animated;


/**
 * @return Float value representing the visible percentage
 * @param viewController The view controller for which to fetch the
 * visible percentage
 *
 * A view controller is visible when any part of it is visible (within the
 * PageController's scrollView bounds and not covered by any other view)
 *
 * Ranges from 0.0f to 1.0f
 */
- (CGFloat)visiblePercentageForViewController:(UIViewController *)viewController;


/** UIBezierPath inside which the pageController's scrollView doesn't respond to touch
 * events
 */
@property (nonatomic, strong) UIBezierPath *touchRefusalArea;


/** Boolean value that controls whether the pageController's scrollView bounces past the
 *  edge of content and back again
 *
 * Default value is set to true
 */
@property (nonatomic, assign) BOOL bounces;


/** A Boolean value that determines whether scrolling is enabled for the pageController's
 * scrollView.
 *
 * Default value is set to true
 */
@property (nonatomic, assign) BOOL scrollEnabled;


/** A Boolean value that controls whether the pageController's scrollView indicators are
 * visible.
 *
 * Default value is set to false
 */
@property (nonatomic, assign) BOOL showsScrollIndicators;


/** A Boolean value that determines whether paging is enabled for the pageController's
 * scrollView.
 *
 * Default value is set to true
 */
@property (nonatomic, assign) BOOL pagingEnabled;


/** The minimum number of fingers that can be touching the view for this gesture to be recognized.
 *
 * Default value is set to 1
 */
@property (nonatomic, assign) NSUInteger minimumNumberOfTouches;


/** The maximum number of fingers that can be touching the view for this gesture to be recognized.
 *
 * Default value is set to NSUIntegerMax
 */
@property (nonatomic, assign) NSUInteger maximumNumberOfTouches;

@end



@protocol SCPageViewControllerDataSource <NSObject>

/**
 * @return Number of items in the page view controller
 * @param pageViewController The calling PageViewController
 *
 */
- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController;


/**
 * @return The view controller to be uses for the given index
 * @param pageViewController The calling PageViewController
 * @param pageIndex The index for which to retrieve the view controller
 *
 */
- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex;

@end



@protocol SCPageViewControllerDelegate <NSObject>

@optional

/** Delegate method that the Stack calls when a view controller becomes visible
 *
 * @param pageViewController The calling PageViewController
 * @param controller The view controller that became visible
 * @param position The position where the view controller resides
 *
 * A view controller is visible when any part of it is visible (within the
 * PageController's scrollView bounds and not covered by any other view)
 *
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
     didShowViewController:(UIViewController *)controller
                   atIndex:(NSUInteger)index;


/** Delegate method that the pageController calls when a view controller is hidden
 * @param pageViewController The calling PageViewController
 * @param controller The view controller that was hidden
 * @param index The position where the view controller resides
 *
 * A view controller is hidden when it view's frame rests outside the pageController's
 * scrollView bounds or when it is fully overlapped by other views
 *
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
     didHideViewController:(UIViewController *)controller
                   atIndex:(NSUInteger)index;


/** Delegate method that the pageController calls when its scrollView scrolls
 * @param stackViewController The calling StackViewController
 * @param offset The current offset in the Stack's scrollView
 *
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
       didNavigateToOffset:(CGPoint)offset;


/** Delegate method that the pageController calls when its scrollView rests
 * on a page
 * @param stackViewController The calling StackViewController
 * @param pageIndex The index of the page
 *
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
  didNavigateToPageAtIndex:(NSUInteger)pageIndex;

@end