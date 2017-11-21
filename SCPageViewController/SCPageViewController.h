//
//  SCPageViewController.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

@import UIKit;

@class SCScrollView;

@protocol SCPageViewControllerDataSource;
@protocol SCPageViewControllerDelegate;
@protocol SCPageLayouterProtocol;

@protocol SCEasingFunctionProtocol;

/** SCPageViewController is a container view controller which allows 
 * you to paginate other view controllers and build custom transitions
 * between them while providing correct physics and appearance calls.
 */
@interface SCPageViewController : UIViewController

/** Sets the layouter that the pageController should use
 * @param layouter the layouter that should be used
 * @param animated whether the change should be animated
 * @param completion the block to be called when the transition is over
 */
- (void)setLayouter:(id<SCPageLayouterProtocol>)layouter
           animated:(BOOL)animated
         completion:(void(^)(void))completion;


/** Sets the layouter and also focuses on the given index
 * @param layouter the layouter that should be used
 * @param pageIndex the page index to focus on
 * @param animated whether the change should be animated
 * @param completion the block to be called when the transition is over
 */
- (void)setLayouter:(id<SCPageLayouterProtocol>)layouter
    andFocusOnIndex:(NSUInteger)pageIndex
           animated:(BOOL)animated
         completion:(void(^)(void))completion;


/** Reloads and re-lays out all the pages */
- (void)reloadData;


/** Reloads and re-layouts the pages at the given indexes
 * @param indexes the indexes of the pages that should be reloaded
 * @param animated whether the reload should be animated
 * @param completion the block to be called when the pages have been reloaded
 */
- (void)reloadPagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:(void(^)(void))completion;


/** Inserts new pages at the given indexes
 * @param indexes the indexes where new pages should be inserted
 * @param animated whether the insertions should be animated
 * @param completion the block to be called when the pages have been inserted
 */
- (void)insertPagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:(void(^)(void))completion;


/** Removes the pages from the given indexes
 * @param indexes the indexes from where pages should be deleted
 * @param animated whether the deletions should be animated
 * @param completion the block to be called when the pages have been deleted
 */
- (void)deletePagesAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated completion:(void(^)(void))completion;


/** Moves a page from one index to another
 * @param fromIndex the initial page index
 * @param toIndex the final page index
 * @param animated whether the move should be animated
 * @param completion the block to be called when the page has been moved
 */
- (void)movePageAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated completion:(void(^)(void))completion;


/** Navigates to the given page index
 * @param pageIndex The page index to navigate to
 * @param animated Whether the transition will be animated
 * @param completion the block to be called when the navigation finished
 */
- (void)navigateToPageAtIndex:(NSUInteger)pageIndex
                     animated:(BOOL)animated
                   completion:(void(^)(void))completion;


/**
 * @param viewController The view controller for which to fetch the
 * visible percentage
 * @return Float value representing the visible percentage
 *
 * @discussion A view controller is visible when any part of it is visible (within the
 * PageController's scrollView bounds and not covered by any other view)
 * Ranges from 0.0f to 1.0f
 */
- (CGFloat)visiblePercentageForViewController:(UIViewController *)viewController;


/** Retrieves the view controller for the given page, if loaded, nil otherwise
 * @param pageIndex The page index you want to retrieve the view controller for
 * @return the view controller for the given page index if already loaded, nil otherwise
 */
- (UIViewController *)viewControllerForPageAtIndex:(NSUInteger)pageIndex;


/** Retrieves the page index for the given view controller
 * @param viewController The viewController for which to retrieve the page index
 * @return The page index for the given view controller or NSNotFound
 */
- (NSUInteger)pageIndexForViewController:(UIViewController *)viewController;


/** Currently used layouter */
@property (nonatomic, readonly) id<SCPageLayouterProtocol> layouter;


/** The page view controller's data source */
@property (nonatomic, weak) id<SCPageViewControllerDataSource> dataSource;


/** The page view controller's delegate */
@property (nonatomic, weak) id<SCPageViewControllerDelegate> delegate;


/** The internal scroll view */
@property (nonatomic, strong, readonly) SCScrollView *scrollView;


/** The current page in the page view controller */
@property (nonatomic, readonly) NSUInteger currentPage;


/** The total number of pages the page view controllers holds at any given time */
@property (nonatomic, readonly) NSUInteger numberOfPages;


/** Whether the page controller's view is visible or not */
@property (nonatomic, readonly) BOOL visible;


/** An array of currently loaded view controllers in the page view controller */
@property (nonatomic, readonly) NSArray *loadedViewControllers;


/** An array of currently visible view controllers in the page view controller */
@property (nonatomic, readonly) NSArray *visibleViewControllers;


/** A Boolean value that determines whether paging is enabled for the pageController's
 * scrollView.
 *
 * Default value is set to true
 */
@property (nonatomic, assign) BOOL pagingEnabled;


/** A Boolean value that determines whether the user can freely scroll between
 * pages
 *
 * When set to true the PageController's scrollView bounces on every page. Navigating
 * through more than 1 page will require multiple swipes.
 *
 * Default value is set to false
 */
@property (nonatomic, assign) BOOL continuousNavigationEnabled;


/** Tells the pageViewController to layout pages only when the scroll rests
 * @discussion Setting this to true will prevent the page view controller from using
 * the layouter to set current page frames while navigating
 */
@property (nonatomic, assign) BOOL shouldLayoutPagesOnRest;


/** Timing function used when navigating beteen pages
 *
 * Default value is set to SCEasingFunctionTypeSineEaseInOut
 */
@property (nonatomic, strong) id<SCEasingFunctionProtocol> easingFunction;


/** Animation duration used when navigating beteen pages
 *
 * Default value is set to 0.25f
 */
@property (nonatomic, assign) NSTimeInterval animationDuration;


@end


/** The page view controller's dataSource protocol */
@protocol SCPageViewControllerDataSource <NSObject>

/**
 * @param pageViewController The calling PageViewController
 * @return Number of items in the page view controller
 */
- (NSUInteger)numberOfPagesInPageViewController:(SCPageViewController *)pageViewController;


/**
 * @param pageViewController The calling PageViewController
 * @param pageIndex The index for which to retrieve the view controller
 * @return The view controller to be uses for the given index
 */
- (UIViewController *)pageViewController:(SCPageViewController *)pageViewController viewControllerForPageAtIndex:(NSUInteger)pageIndex;

/**
 * @param pageViewController The calling PageViewController
 * @return The initial page that should be loaded, otherwise the first is chosen.
 */
@optional
- (NSUInteger)initialPageInPageViewController:(SCPageViewController *)pageViewController;

@end


/** The page view controller's delegate protocol */
@protocol SCPageViewControllerDelegate <NSObject>

@optional

/** Delegate method that the PageViewController calls when a view controller becomes visible
 *
 * @param pageViewController The calling PageViewController
 * @param controller The view controller that became visible
 * @param index The view controller index
 *
 * A view controller is visible when any part of it is visible (within the
 * internal scrollView's bounds and not covered by any other view)
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
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
     didHideViewController:(UIViewController *)controller
                   atIndex:(NSUInteger)index;


/** Delegate method that the pageController calls when its scrollView scrolls
 * @param pageViewController The calling PageViewController
 * @param offset The current offset in the PageViewController's scrollView
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
       didNavigateToOffset:(CGPoint)offset;


/** Delegate method that the pageController calls when its scrollView rests
 * on a page
 * @param pageViewController The calling PageViewController
 * @param pageIndex The index of the page
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
  didNavigateToPageAtIndex:(NSUInteger)pageIndex;

@end
