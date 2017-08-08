//
//  ViewController.m
//  StepSynth
//
//  Created by Michael Weiss on 9/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SineStepViewController.h"
#import "SineStepView.h"
#import "CircleSelectView.h"
#import "BarSelectView.h"
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>

#define CIRCLE_SELECT_VIEW_PADDING 20
OSStatus RenderTone(
                    void *inRefCon, 
                    AudioUnitRenderActionFlags 	*ioActionFlags, 
                    const AudioTimeStamp 		*inTimeStamp, 
                    UInt32 						inBusNumber, 
                    UInt32 						inNumberFrames, 
                    AudioBufferList 			*ioData)

{
	// Fixed amplitude is good enough for our purposes
	// Get the tone parameters out of the view controller
	SineStepViewController *viewController = (SineStepViewController *)inRefCon;
	double theta = viewController->theta;
    double* frequencies = viewController->frequencies;
    // TODO: replace
	double theta_increment = 2.0 * M_PI / viewController->sampleRate;
    
	// This is a mono tone generator so we only need the first buffer
	const int channel = 0;
	Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
	
    UInt32 frameToSwitch = floor( (60. *  viewController->sampleRate) / (viewController->bpm));
    UInt32 totalNumFrames = inNumberFrames + viewController->totalFrames;
    UInt32 totalFrames = viewController->totalFrames;
    UInt32 numSteps = 16;
    BOOL* steps = viewController->steps;
    UInt32 lastX = (totalFrames / frameToSwitch) % numSteps;
    viewController.sineStepView->bpm = viewController->bpm;
	// Generate the samples
	for (UInt32 frame = viewController->totalFrames; frame < totalNumFrames; frame++) 
	{
        UInt32 x = (frame / frameToSwitch) % numSteps;

        Float32 bufferValue = 0;
        if (lastX != x) {
            dispatch_async(dispatch_get_main_queue(), 
                           ^{
                               [viewController.sineStepView animateStep:x];
                           });
        }
        for (uint y = 0; y < numSteps; y += 1) {
            UInt32 stepIndex = x + (y * numSteps);
            BOOL step = steps[stepIndex % 255];
            // NSLog(@"%i", step);
            bufferValue += ((Float32)step) * (sin(theta * frequencies[y])) * (1. / 16.);
        } 
		buffer[frame - totalFrames] = bufferValue;
		theta += theta_increment;
        lastX = x;
	}
	
	// Store the theta back in the view controller
	viewController->theta = theta;
    viewController->totalFrames = totalNumFrames;
	return noErr;
}

@interface Dimensions : NSObject  {
@public
    CGRect sineStepView;
    CGRect freqCSView;
    CGRect shiftCSView;
    CGRect scaleCSView;
    CGRect barSelectView;
}
@end

@implementation Dimensions

@end

@interface SineStepViewController () {
    BOOL histeresisExcited;
}
@end

@implementation SineStepViewController

@synthesize sineStepView, freqCircleSelectView, shiftCircleSelectView, scaleCircleSelectView, bpmBarSelectView;
- (void)viewDidLoad
{
    theta = 0;
    totalFrames = 0;
    sampleRate = 44100;
    bpm = 200;
    scaleType = 0;
    numSteps = 16;
    
    [super viewDidLoad];

    Dimensions *dim = [self calculate];
    SineStepView *ssView = [[SineStepView alloc] initWithFrame:dim->sineStepView];
    [self setSineStepView:ssView];
    frequencies = malloc(sizeof(double) * numSteps);
    [self updateFrequenciesForScaleAndShift];
    
    steps = ssView->steps;
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    CircleSelectView *freqCSView = [[CircleSelectView alloc] initWithFrame:dim->freqCSView];
    freqCSView->totalNumIndexes = 10;
    freqCSView->selector = @selector(updateFrequenciesForScale:);
    [freqCSView setDelegate:self];
    [self setFreqCircleSelectView:freqCSView];
    
    CircleSelectView *shiftCSView = [[CircleSelectView alloc] initWithFrame:dim->shiftCSView];
    shiftCSView->totalNumIndexes = 5;
    shiftCSView->selectedIndex = 0;
    shiftCSView->selector = @selector(updateFrequenciesForShift:);
    [shiftCSView setDelegate:self];
    [self setShiftCircleSelectView:shiftCSView];
    
    CircleSelectView *scaleCSView = [[CircleSelectView alloc] initWithFrame:dim->scaleCSView];
    scaleCSView->totalNumIndexes = 5;
    scaleCSView->selectedIndex = 0;
    scaleCSView->selector = @selector(updateFrequenciesForScaleType:);
    [scaleCSView setDelegate:self];
    [self setScaleCircleSelectView:scaleCSView];
    
    BarSelectView *barSelectView = [[BarSelectView alloc] initWithFrame:dim->barSelectView];
    barSelectView->ratio = .56;
    barSelectView->selector = @selector(updateBPM:);
    [barSelectView setDelegate:self];
    [self setBpmBarSelectView:barSelectView];
    
    [self.view addSubview:ssView];
    [self.view addSubview:freqCSView];
    [self.view addSubview:shiftCSView];
    [self.view addSubview:scaleCSView];
    [self.view addSubview:barSelectView];
    [self.view setNeedsDisplay];
    [self createToneUnit];
    // Stop changing parameters on the unit
    OSErr err = AudioUnitInitialize(toneUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %d", err);
    
    // Start playback
    err = AudioOutputUnitStart(toneUnit);
    NSAssert1(err == noErr, @"Error starting unit: %d", err);
    // 
}

- (void) viewWillAppear:(BOOL)animated
{
    [sineStepView becomeFirstResponder];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [sineStepView resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void)updateFrequenciesForScale:(uint) selIndex {
    scale = selIndex;
    [self updateFrequenciesForScaleAndShift];
}

- (void)updateFrequenciesForScaleType:(uint)selIndex {
    scaleType = selIndex;
    [self updateFrequenciesForScaleAndShift];
}
- (void)updateFrequenciesForScaleAndShift {
    uint scaleLength = 0;
    float pentatonic[5] = {0, 2, 4, 7, 9};
    float major[4] = {0, 4, 7, 11};
    float minor[4] = {0, 4, 7, 10};
    float normalMajor[8] = {0, 2, 4, 5, 7, 9, 11, 12};
    float normalMinor[8] = {0, 2, 3, 5, 7, 8, 10, 12};
    float *scaleArr;
    switch (scaleType) {
        case 0:
            scaleArr = pentatonic;
            scaleLength = 5;
            break;
        case 1:
            scaleArr = major;
            scaleLength = 4;
            break;
        case 2:
            scaleArr = minor;
            scaleLength = 4;
            break;
        case 3:
            scaleArr = normalMajor;
            scaleLength = 8;
            break;
        case 4:
        default:
            scaleArr = normalMinor;
            scaleLength = 8;
            break;
    }
    
    float a = pow(2, 1. / 12.);
    for (uint i = 0; i < numSteps; i += 1) {
        frequencies[i] = 440. * pow(a, floor(i / 5) * 12 + scaleArr[(i + shift) % scaleLength] - 12 - scale);
    }
}

- (void)updateFrequenciesForShift:(uint) selIndex {
    shift = selIndex;
    [self updateFrequenciesForScaleAndShift];
}

- (void)updateBPM:(float) ratio {
    bpm = 60 + ceil(240 * ratio);
}

- (Dimensions *) calculate {
    Dimensions * dim = [Dimensions new];
    BOOL landscape = self.view.bounds.size.width > self.view.bounds.size.height;
    float m = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    float otherMin = !landscape ? MIN(self.view.bounds.size.height - m,  m / 3.) : self.view.bounds.size.height / 4;
    float initYOffset = MAX(18, (self.view.bounds.size.height - m - otherMin - 18.) / 2.);
    
    if (landscape) {
        dim->sineStepView = CGRectMake(0, 0, m, m);
        dim->freqCSView = CGRectMake(m + 2 * CIRCLE_SELECT_VIEW_PADDING, initYOffset, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2));
        dim->shiftCSView = CGRectMake(m + 2 * CIRCLE_SELECT_VIEW_PADDING, initYOffset + otherMin, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2));
        dim->scaleCSView = CGRectMake(m + 2 * CIRCLE_SELECT_VIEW_PADDING, initYOffset + 2 * otherMin, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2));
        dim->barSelectView = CGRectMake(m + 2 * CIRCLE_SELECT_VIEW_PADDING + otherMin / 3, initYOffset + 3 * otherMin, 30, otherMin - 50);
    } else {
        dim->sineStepView = CGRectMake(0, initYOffset, m, m);
        dim->freqCSView = CGRectMake(CIRCLE_SELECT_VIEW_PADDING, m + CIRCLE_SELECT_VIEW_PADDING + initYOffset, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2));
        dim->shiftCSView = CGRectMake(otherMin, m + CIRCLE_SELECT_VIEW_PADDING + initYOffset, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2));
        dim->scaleCSView = CGRectMake(2 * otherMin - CIRCLE_SELECT_VIEW_PADDING, m + CIRCLE_SELECT_VIEW_PADDING + initYOffset, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2));
        dim->barSelectView = CGRectMake(3 * otherMin - (2 * CIRCLE_SELECT_VIEW_PADDING), m + CIRCLE_SELECT_VIEW_PADDING + initYOffset, (self.view.bounds.size.width - (3 * otherMin - (2 * CIRCLE_SELECT_VIEW_PADDING))) - CIRCLE_SELECT_VIEW_PADDING, MIN(self.view.bounds.size.height - m - 2 *CIRCLE_SELECT_VIEW_PADDING - 4, otherMin));
    }
    return dim;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Code here will execute before the rotation begins.
    // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        // Place code here to perform animations during the rotation.
        // You can pass nil or leave this block empty if not necessary.
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        Dimensions *dim = [self calculate];
        self.sineStepView.frame = dim->sineStepView;
        self.freqCircleSelectView.frame = dim->freqCSView;
        self.shiftCircleSelectView.frame = dim->shiftCSView;
        self.scaleCircleSelectView.frame = dim->scaleCSView;
        self.bpmBarSelectView.frame = dim->barSelectView;
        [self.view setNeedsDisplay];
        [self.sineStepView setNeedsDisplay];
        [self.freqCircleSelectView setNeedsDisplay];
        [self.shiftCircleSelectView setNeedsDisplay];
        [self.scaleCircleSelectView setNeedsDisplay];
        [self.bpmBarSelectView setNeedsDisplay];
        // Code here will execute after the rotation has finished.
        // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        
    }];
}

- (void)createToneUnit
{
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
	NSAssert1(toneUnit, @"Error creating unit: %d", err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = self;
	err = AudioUnitSetProperty(toneUnit, 
                               kAudioUnitProperty_SetRenderCallback, 
                               kAudioUnitScope_Input,
                               0, 
                               &input, 
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %d", err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;	
	streamFormat.mBytesPerFrame = four_bytes_per_float;		
	streamFormat.mChannelsPerFrame = 1;	
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %d", err);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

@end
