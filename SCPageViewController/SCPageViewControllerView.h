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

@property (nonatomic, weak) id<SCPageViewControllerViewDelegate> delegate;

@end

@protocol SCPageViewControllerViewDelegate <NSObject>

- (void)pageViewControllerViewWillChangeFrame:(SCPageViewControllerView *)pageViewControllerView;
- (void)pageViewControllerViewDidChangeFrame:(SCPageViewControllerView *)pageViewControllerView;

@end
