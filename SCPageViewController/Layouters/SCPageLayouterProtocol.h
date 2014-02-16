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

@protocol SCPageLayouterProtocol <NSObject>

@property (nonatomic, assign) SCPageLayouterNavigationType navigationType;

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
                   inPageViewController:(SCPageViewController *)pageViewController;


@end
