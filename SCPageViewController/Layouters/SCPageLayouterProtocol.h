//
//  SCPageLayouterProtocol.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageViewController.h"

/** An object adopting the SCPageLayouter protocol is responsible for returning
 * the itermediate and final frames for the PageViewControllers's children when called.
 * They have access the the actual children so that they can customize the navigation
 * effects at each point of the transition.
 */

typedef NS_ENUM(NSUInteger, SCPageLayouterNavigationType) {
    SCPageLayouterNavigationTypeHorizontal,
    SCPageLayouterNavigationTypeVertical,
};

/** Navigation contraint types that can be used used when continuous navigation is disabled */
typedef NS_OPTIONS(NSUInteger, SCPageLayouterNavigationContraintType) {
    SCPageLayouterNavigationContraintTypeNone = 0,
    SCPageLayouterNavigationContraintTypeForward = 1 << 0, /** Scroll view bounces on page bounds only when navigating forward*/
    SCPageLayouterNavigationContraintTypeReverse = 1 << 1  /** Scroll view bounces on page bounds only when navigating backwards*/
};


/**
 * The page layouter protocol specifies the required and optional methods that define
 * how pages are laid out on screen and how they are animated while performing
 * incremental updates
 */
@protocol SCPageLayouterProtocol <NSObject>

/** Defines the direction the pages are laid out */
@property (nonatomic, assign) SCPageLayouterNavigationType navigationType;


/** Defines when the page view controller should enforce page bounds while navigating */
@property (nonatomic, assign) SCPageLayouterNavigationContraintType navigationConstraintType;


/** The number of pages to preload and add to the page view controller before the current page */
@property (nonatomic, assign) NSUInteger numberOfPagesToPreloadBeforeCurrentPage;


/** The number of pages to preload and add to the page view controller after the current page */
@property (nonatomic, assign) NSUInteger numberOfPagesToPreloadAfterCurrentPage;


/** Returns the final frame for the given view controller
 *
 * @param index The index of the view controller in the PageViewController's children array
 * @param pageViewController The calling PageViewController
 * @return The frame for the viewController's view
 */
- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
                pageViewController:(SCPageViewController *)pageViewController;


@optional

/** The amount of space in between each page
 *
 * @param pageViewController the calling page view controller
 * @return the spacing to be used
 */
- (CGFloat)interItemSpacingForPageViewController:(SCPageViewController *)pageViewController;


/** Defines the empty space useds before and after pages
 * Based on the navigationType the pageController only uses a pair (top/bottom,
 * left/right)
 *
 * @param pageViewController the calling page view controller
 * @return the insets to be used
 */
- (UIEdgeInsets)contentInsetForPageViewController:(SCPageViewController *)pageViewController;


/** Returns the intermediate frame for the given view controller and current
 * offset
 *
 * @param index The index of the view controller
 * @param contentOffset current offset in the PageViewController's scrollView
 * @param pageViewController The calling SCPageViewController
 * @return The frame for the viewController's view
 */
- (CGRect)currentFrameForPageAtIndex:(NSUInteger)index
                       contentOffset:(CGPoint)contentOffset
                          finalFrame:(CGRect)finalFrame
                  pageViewController:(SCPageViewController *)pageViewController;


/** Defines the z position which should be used when laying out the given view controller
 * Defaults to the inverse of the page order
 *
 * @param index the page index for the given view controller
 * @param pageViewController the calling page view controller
 * @return the index the view controller we be places at in the view hierarchy
 */
- (NSUInteger)zPositionForPageAtIndex:(NSUInteger)index
                   pageViewController:(SCPageViewController *)pageViewController;


/** Returns the view controller sublayer transformation that should be used
 * for the current offset
 *
 * @param index The index of the view controller in the Stack's children array
 * @param pageViewController The calling page view controller
 * @return The sublayer transformation to be applied
 */
- (CATransform3D)sublayerTransformForPageAtIndex:(NSUInteger)index
                                   contentOffset:(CGPoint)contentOffset
                              pageViewController:(SCPageViewController *)pageViewController;


/** Method that the pageController calls when its scrollView scrolls
 * @param pageViewController The calling PageViewController
 * @param offset The current offset in the PageViewController's scrollView
 */
- (void)pageViewController:(SCPageViewController *)pageViewController
       didNavigateToOffset:(CGPoint)offset;


/** Called by the pageViewController when it receives a reload page animated
 * request.
 * The completion call must be called after finishing customizations so that
 * the pageViewController can continue the layout
 *
 * @param index The index of the page about to be reloaded
 * @param oldViewController The view controller about to be removed
 * @param newViewController The view controller that is going to be inserted
 * @param pageViewController the calling pageViewController
 * @param completion block that lets the pageViewController know that it can
 * proceed with the layout
 */
- (void)animatePageReloadAtIndex:(NSUInteger)index
               oldViewController:(UIViewController *)oldViewController
               newViewController:(UIViewController *)newViewController
              pageViewController:(SCPageViewController *)pageViewController
                      completion:(void(^)(void))completion;


/** Called by the pageViewController when it receives an insert page animated
 * request.
 * The completion call must be called after finishing customizations so that
 * the pageViewController can continue the layout
 *
 * @param index The index where a new page will be inserted
 * @param viewController The view controller that is going to be inserted
 * @param pageViewController the calling pageViewController
 * @param completion block that lets the pageViewController know that it can
 * proceed with the layout
 */
- (void)animatePageInsertionAtIndex:(NSUInteger)index
                     viewController:(UIViewController *)viewController
                 pageViewController:(SCPageViewController *)pageViewController
                         completion:(void(^)(void))completion;

/** Called bue the pageViewController when inserting a new page that
 * would affect the current content offset
 *
 * @param index The index where a new page will be inserted
 * @param pageViewController the calling pageViewController
 * @return a boolean indicating whether the current offset should be kept
 */
- (BOOL)shouldPreserveOffsetForInsertionAtIndex:(NSUInteger)index
                             pageViewController:(SCPageViewController *)pageViewController;


/** Called by the pageViewController when it receives a delete page animated
 * request.
 * The completion call must be called after finishing customizations so that
 * the pageViewController can continue the layout
 *
 * @param index The index where a new page will be deleted
 * @param viewController The view controller that is going to be deleted
 * @param pageViewController the calling pageViewController
 * @param completion block that lets the pageViewController know that it can
 * proceed with the layout
 */
- (void)animatePageDeletionAtIndex:(NSUInteger)index
                    viewController:(UIViewController *)viewController
                pageViewController:(SCPageViewController *)pageViewController
                        completion:(void(^)(void))completion;


/** Called by the pageViewController when it receives an move page animated
 * request.
 * The completion call must be called after finishing customizations so that
 * the pageViewController can continue the layout
 *
 * @param fromIndex The orinal index of the page
 * @param toIndex The final index of the page after updates
 * @param viewController The view controller that is going to be moved
 * @param pageViewController the calling pageViewController
 * @param completion block that lets the pageViewController know that it can
 * proceed with the layout
 */
- (void)animatePageMoveFromIndex:(NSUInteger)fromIndex
                         toIndex:(NSUInteger)toIndex
                  viewController:(UIViewController *)viewController
              pageViewController:(SCPageViewController *)pageViewController
                      completion:(void(^)(void))completion;

@end
