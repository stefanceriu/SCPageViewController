//
//  SCPageViewControllerView.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 18/01/2015.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

@protocol SCPageViewControllerViewDelegate;

@interface SCPageViewControllerView : UIView

@property (nonatomic, weak) id<SCPageViewControllerViewDelegate> delegate;

@end

@protocol SCPageViewControllerViewDelegate <NSObject>

- (void)pageViewControllerViewWillChangeFrame:(SCPageViewControllerView *)pageViewControllerView;
- (void)pageViewControllerViewDidChangeFrame:(SCPageViewControllerView *)pageViewControllerView;

@end
