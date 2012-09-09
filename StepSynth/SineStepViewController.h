//
//  ViewController.h
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SineStepView.h"
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
@end
