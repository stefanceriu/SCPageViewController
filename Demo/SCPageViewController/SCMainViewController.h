//
//  SCMainViewController.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

typedef enum {
    SCPageLayouterTypePlain,
    SCPageLayouterTypeSliding,
    SCPageLayouterTypeParallax,
    SCPageLayouterTypeFacebookPaper,
    SCPageLayouterTypeCount
} SCPageLayouterType;

@protocol SCMainViewControllerDelegate;

@interface SCMainViewController : UIViewController

@property (nonatomic, weak, readonly) UILabel *pageNumberLabel;
@property (nonatomic, weak, readonly) UILabel *visiblePercentageLabel;

@property (nonatomic, weak) IBOutlet id<SCMainViewControllerDelegate> delegate;

@end

@protocol SCMainViewControllerDelegate <NSObject>

- (void)mainViewController:(SCMainViewController *)mainViewController
         didSelectLayouter:(SCPageLayouterType)type;

@end
