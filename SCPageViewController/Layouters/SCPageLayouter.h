//
//  SCPageLayouter.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

#import "SCPageLayouterProtocol.h"

/**
 * A page layouter that can show pages side by side, horizontally or vertically.
 * It defines simple incremental update animations and supports inter-item spacings.
 */
@interface SCPageLayouter : NSObject <SCPageLayouterProtocol>

@property (nonatomic, assign) CGFloat interItemSpacing;

@end
