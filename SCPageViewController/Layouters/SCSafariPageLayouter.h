//
//  SCSafariPageLayouter.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 6/16/15.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import "SCPageLayouter.h"

@interface SCSafariPageLayouter : SCPageLayouter

@property (nonatomic, assign) CGSize pageSize;
@property (nonatomic, assign) UIEdgeInsets contentInset;

@property (nonatomic, assign) CGFloat pagePercentage;

@end
