//
//  ViewController.h
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SineStepView.h"
#import "CircleSelectView.h"
#import "BarSelectView.h"
#import <AudioUnit/AudioUnit.h>

@interface SineStepViewController : UIViewController {
    AudioComponentInstance toneUnit;
@public
    UInt32 totalFrames;
    BOOL *steps;
    UInt32 numSteps;
    double *frequencies;
    double bpm;
    double sampleRate;
    double theta;
    uint scale;
    uint shift;
    uint scaleType;
}
@property (nonatomic, retain) SineStepView *sineStepView;
@property (nonatomic, retain) CircleSelectView *freqCircleSelectView;
@property (nonatomic, retain) CircleSelectView *shiftCircleSelectView;
@property (nonatomic, retain) CircleSelectView *scaleCircleSelectView;
@property (nonatomic, retain) BarSelectView *bpmBarSelectView;
@end
