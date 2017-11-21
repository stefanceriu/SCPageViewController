//
//  SCPageViewControllerView.m
//  SCPageViewController
//
//  Created by Stefan Ceriu on 18/01/2015.
//  Copyright (c) 2015 Stefan Ceriu. All rights reserved.
//

#import "SCPageViewControllerView.h"

@implementation SCPageViewControllerView

- (void)setFrame:(CGRect)frame
{
    [self.delegate pageViewControllerViewWillChangeFrame:self];
    
    super.frame = frame;
    
    [self.delegate pageViewControllerViewDidChangeFrame:self];
}

@end
