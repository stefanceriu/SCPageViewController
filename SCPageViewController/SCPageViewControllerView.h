//
//  SCPageViewControllerView.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 18/01/2015.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

@import UIKit;

@protocol SCPageViewControllerViewDelegate;

/** A custom view used inside the page view controller
 * which notifies it about impending frame changes
 */
@interface SCPageViewControllerView : UIView

/** The pageViewControllerView's delegate */
@property (nonatomic, weak) id<SCPageViewControllerViewDelegate> delegate;

@end

/** The pageViewControllerView's delegate protocol */
@protocol SCPageViewControllerViewDelegate <NSObject>

/** Called when the view's frame is about to be changed */
- (void)pageViewControllerViewWillChangeFrame:(SCPageViewControllerView *)pageViewControllerView;

/** Called after the view's frame has been changed */
- (void)pageViewControllerViewDidChangeFrame:(SCPageViewControllerView *)pageViewControllerView;

@end
