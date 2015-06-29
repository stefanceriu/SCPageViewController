//
//  SCCardsPageLayouter.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 23/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageLayouter.h"

/**
 * A SCPageLayouter subclass that shrinks the page sizes
 * to a percentage of the page view controller bounds and
 * centers them on screen
 */
@interface SCCardsPageLayouter : SCPageLayouter

@property (nonatomic, assign) CGFloat pagePercentage;

@end
