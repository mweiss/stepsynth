//
//  SineStepView.h
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SineStepView : UIView {
    @public
    uint numSteps;
    BOOL *steps;
    double bpm;
}
- (BOOL) getStep:(uint)x y:(uint)y;
- (void) setStep:(uint)x y:(uint)y withValue:(BOOL)value;
- (void) animateStep:(uint)x;
- (void) registerStep:(uint)x y:(uint)y;
- (void) registerEnd;

@end
