//
//  SCMainViewController.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

@import UIKit;

#import "SCEasingFunction.h"

typedef enum {
	SCPageLayouterTypePlain,
	SCPageLayouterTypeSliding,
	SCPageLayouterTypeParallax,
	SCPageLayouterTypeCards,
	SCPageLayouterTypeCount
} SCPageLayouterType;

@protocol SCMainViewControllerDelegate;

@interface SCMainViewController : UIViewController

@property (nonatomic, weak, readonly) UIView *contentView;

@property (nonatomic, weak, readonly) UILabel *pageNumberLabel;
@property (nonatomic, weak, readonly) UILabel *visiblePercentageLabel;

@property (nonatomic, weak) IBOutlet id<SCMainViewControllerDelegate> delegate;

@property (nonatomic, assign) SCPageLayouterType layouterType;
@property (nonatomic, assign) SCEasingFunctionType easingFunctionType;
@property (nonatomic, assign) NSTimeInterval duration;

@end

@protocol SCMainViewControllerDelegate <NSObject>

- (void)mainViewControllerDidChangeLayouterType:(SCMainViewController *)mainViewController;

- (void)mainViewControllerDidChangeAnimationType:(SCMainViewController *)mainViewController;

- (void)mainViewControllerDidChangeAnimationDuration:(SCMainViewController *)mainViewController;

- (void)mainViewControllerDidRequestNavigationToPreviousPage:(SCMainViewController *)mainViewController;

- (void)mainViewControllerDidRequestNavigationToNextPage:(SCMainViewController *)mainViewController;

- (void)mainViewControllerDidRequestPageInsertion:(SCMainViewController *)mainViewController;

- (void)mainViewControllerDidRequestPageDeletion:(SCMainViewController *)mainViewController;

@end
