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

typedef enum {
    SCPageLayouterNavigationTypeHorizontal,
    SCPageLayouterNavigationTypeVertical,
} SCPageLayouterNavigationType;

/** Navigation contraint types that can be used used when continuous
 * navigation is disabled
 */
typedef enum {
    SCPageLayouterNavigationContraintTypeForward = 1 << 0, /** Scroll view bounces on steps only when unfolding the stack*/
    SCPageLayouterNavigationContraintTypeReverse = 1 << 1  /** Scroll view bounces on steps only when folding the stack*/
} SCPageLayouterNavigationContraintType;


@protocol SCPageLayouterProtocol <NSObject>

/** Defines the direction the pages are layed out */
@property (nonatomic, assign) SCPageLayouterNavigationType navigationType;


/** Defines the direction the pages are layed out */
@property (nonatomic, assign) SCPageLayouterNavigationContraintType navigationConstraintType;


/** Defines the spacing between each page */
@property (nonatomic, assign) CGFloat interItemSpacing;


/** Defines the empty space useds before and after pages 
 * Based on the navigationType the pageController only uses a pair (top/bottom,
 * left/right)
 */
@property (nonatomic, assign) UIEdgeInsets contentInsets;


/** Returns the final frame for the given view controller
 *
 * @param index The index of the view controller in the Stack's children array
 * @param pageViewController The calling PageViewController
 *
 * @return The frame for the viewController's view
 *
 */
- (CGRect)finalFrameForPageAtIndex:(NSUInteger)index
              inPageViewController:(SCPageViewController *)pageViewController;


/** Returns the intermediate frame for the given view controller and current
 * offset
 *
 * @param viewController The view controller for which to calculate the frame
 * @param index The index of the view controller
 * @param contentOffset current offset in the PageViewController's scrollView
 * @param pageViewController The calling SCPageViewController
 *
 * @return The frame for the viewController's view
 *
 */
- (CGRect)currentFrameForViewController:(UIViewController *)viewController
                              withIndex:(NSUInteger)index
                          contentOffset:(CGPoint)contentOffset
                             finalFrame:(CGRect)finalFrame
                   inPageViewController:(SCPageViewController *)pageViewController;


/** The number of pages to preload and add to the page view controller before the current page */
@property (nonatomic, assign) NSUInteger numberOfPagesToPreloadBeforeCurrentPage;


/** The number of pages to preload and add to the page view controller after the current page */
@property (nonatomic, assign) NSUInteger numberOfPagesToPreloadAfterCurrentPage;


@end
