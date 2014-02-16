//
//  MOScrollView.m
//  MOScrollView
//
//  Created by Jan Christiansen on 6/20/12.
//  Copyright (c) 2012, Monoid - Development and Consulting - Jan Christiansen
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above
//  copyright notice, this list of conditions and the following
//  disclaimer in the documentation and/or other materials provided
//  with the distribution.
//
//  * Neither the name of Monoid - Development and Consulting - 
//  Jan Christiansen nor the names of other
//  contributors may be used to endorse or promote products derived
//  from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <QuartzCore/QuartzCore.h>
#import "MOScrollView.h"

// constants used for Newton approximation of cubic function root
const static double approximationTolerance = 0.00000001;
const static int maximumSteps = 10;

@interface MOScrollView ()

// display link used to trigger event to scroll the view
@property (nonatomic, strong) CADisplayLink *displayLink;

// animation properties
@property (nonatomic, strong) CAMediaTimingFunction *timingFunction;
@property (nonatomic, assign) CFTimeInterval duration;

// state at the start of an animation
@property (nonatomic, assign) CFTimeInterval beginTime;
@property (nonatomic, assign) CGPoint beginContentOffset;

// delta between the contentOffset at the start of the animation and
// the contentOffset at the end of the animation
@property (nonatomic, assign) CGPoint deltaContentOffset;

// animation completion block
@property (nonatomic, copy) void(^completionBlock)();

@end

@implementation MOScrollView

- (id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame]) {
        self.maximumNumberOfTouches = NSUIntegerMax;
    }
    
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        if(gestureRecognizer.numberOfTouches > self.maximumNumberOfTouches) {
            return NO;
        }
        
        CGPoint touchPoint = [gestureRecognizer locationInView:self];
        return ![self.touchRefusalArea containsPoint:touchPoint];
    }
    
    return YES;
}

#pragma mark - Set ContentOffset with Custom Animation

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    //Ignoring calls from any textView contained by this scroll
    if([[self performSelector:@selector(firstResponder)] isKindOfClass:[UITextField class]]) {
        return;
    }
    #pragma clang diagnostic pop
    
    [super scrollRectToVisible:rect animated:animated];
}

- (void)setContentOffset:(CGPoint)contentOffset
      withTimingFunction:(CAMediaTimingFunction *)timingFunction
                duration:(CFTimeInterval)duration
              completion:(void(^)())completion
{
    //Blocking interaction while active
    if(self.displayLink && !self.displayLink.paused) {
        NSLog(@"MOScrollView - Action canceled");
        return;
    }
    
    if(CGPointEqualToPoint(self.contentOffset, contentOffset)) {
        if(completion) {
            completion();
        }
        return;
    }
    
    if(duration == 0.0f) {
        
        [UIView setAnimationsEnabled:NO];
        self.contentOffset = contentOffset;
        [UIView setAnimationsEnabled:YES];
        
        if(completion) {
            completion();
        }
        return;
    }
    
    self.duration = duration;
    self.timingFunction = timingFunction;
    self.completionBlock = completion;
    
    self.deltaContentOffset = CGPointMake(contentOffset.x - self.contentOffset.x,
                                          contentOffset.y - self.contentOffset.y);
    
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink
                            displayLinkWithTarget:self
                            selector:@selector(updateContentOffset:)];
        self.displayLink.frameInterval = 1;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSRunLoopCommonModes];
    } else {
        self.displayLink.paused = NO;
    }
}

- (void)updateContentOffset:(CADisplayLink *)displayLink {
    
    // on the first invokation in an animation beginTime is zero
    if (self.beginTime == 0.0) {
        
        self.beginTime = displayLink.timestamp;
        self.beginContentOffset = self.contentOffset;
    } else {
        
        CFTimeInterval deltaTime = displayLink.timestamp - self.beginTime;
        
        // ratio of duration that went by
        CGFloat ratio = (CGFloat) (deltaTime / self.duration);
        // ratio adjusted by timing function
        CGFloat adjustedRatio;
        
        if (ratio > 1) {
            adjustedRatio = 1.0;
        } else {
            adjustedRatio = (CGFloat) timingFunctionValue(self.timingFunction, ratio);
        }
        
        if (1 - adjustedRatio < 0.001) {
            
            adjustedRatio = 1.0;
            self.displayLink.paused = YES;
            self.beginTime = 0.0;
        }
        
        CGPoint currentDeltaContentOffset = CGPointMake(self.deltaContentOffset.x * adjustedRatio,
                                                        self.deltaContentOffset.y * adjustedRatio);
        
        CGPoint contentOffset = CGPointMake(self.beginContentOffset.x + currentDeltaContentOffset.x,
                                            self.beginContentOffset.y + currentDeltaContentOffset.y);
        
        [UIView setAnimationsEnabled:NO];
        self.contentOffset = contentOffset;
        [UIView setAnimationsEnabled:YES];
        
        if (adjustedRatio == 1.0) {
            // inform delegate about end of animation
            if([self.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
                [self.delegate scrollViewDidEndScrollingAnimation:self];
            }
            
            if(self.completionBlock) {
                self.completionBlock();
            }
        }
    }
}

double cubicFunctionValue(double a, double b, double c, double d, double x) {
    
    return (a*x*x*x)+(b*x*x)+(c*x)+d;
}

double cubicDerivativeValue(double a, double b, double c, double __unused d, double x) {
    
    // derivation of the cubic (a*x*x*x)+(b*x*x)+(c*x)+d
    return (3*a*x*x)+(2*b*x)+c;
}

double rootOfCubic(double a, double b, double c, double d, double startPoint) {
    
    // we use 0 as start point as the root will be in the interval [0,1]
    double x = startPoint;
    double lastX = 1;
    
    // approximate a root by using the Newton-Raphson method
    int y = 0;
    while (y <= maximumSteps && fabs(lastX - x) > approximationTolerance) {
        lastX = x;
        x = x - (cubicFunctionValue(a, b, c, d, x) / cubicDerivativeValue(a, b, c, d, x));
        y++;
    }
    
    return x;
}

double timingFunctionValue(CAMediaTimingFunction *function, double x) {
    
    float a[2];
    float b[2];
    float c[2];
    float d[2];
    
    [function getControlPointAtIndex:0 values:a];
    [function getControlPointAtIndex:1 values:b];
    [function getControlPointAtIndex:2 values:c];
    [function getControlPointAtIndex:3 values:d];
    
    // look for t value that corresponds to provided x
    double t = rootOfCubic(-a[0]+3*b[0]-3*c[0]+d[0], 3*a[0]-6*b[0]+3*c[0], -3*a[0]+3*b[0], a[0]-x, x);
    
    // return corresponding y value
    double y = cubicFunctionValue(-a[1]+3*b[1]-3*c[1]+d[1], 3*a[1]-6*b[1]+3*c[1], -3*a[1]+3*b[1], a[1], t);
    
    return y;
}

@end

