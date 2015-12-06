//
//  UIView+Shadows.h
//  SCPageViewController
//
//  Created by Stefan Ceriu on 15/02/2014.
//  Copyright (c) 2014 Stefan Ceriu. All rights reserved.
//

@import UIKit;

typedef enum {
    SCShadowEdgeNone   = 0,
    SCShadowEdgeTop    = 1 << 0,
    SCShadowEdgeLeft   = 1 << 1,
    SCShadowEdgeBottom = 1 << 2,
    SCShadowEdgeRight  = 1 << 3,
    SCShadowEdgeAll    = SCShadowEdgeTop | SCShadowEdgeLeft | SCShadowEdgeBottom | SCShadowEdgeRight
} SCShadowEdge;

@interface UIView (Shadows)

- (void)castShadowWithPosition:(SCShadowEdge)edge;

@end
