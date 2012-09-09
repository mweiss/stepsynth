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
    UInt32 numSteps = viewController->numSteps;
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
            BOOL step = steps[x + (y * numSteps)];
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
// Ensures the shake is strong enough on at least two axes before declaring it a shake.
// "Strong enough" means "greater than a client-supplied threshold" in G's.
static BOOL L0AccelerationIsShaking(UIAcceleration* last, UIAcceleration* current, double threshold) {
    double
    deltaX = fabs(last.x - current.x),
    deltaY = fabs(last.y - current.y),
    deltaZ = fabs(last.z - current.z);
    
    return
    (deltaX > threshold && deltaY > threshold) ||
    (deltaX > threshold && deltaZ > threshold) ||
    (deltaY > threshold && deltaZ > threshold);
}

@interface SineStepViewController () {
    BOOL histeresisExcited;
    UIAcceleration* lastAcceleration;
}
@property(retain) UIAcceleration* lastAcceleration;
@end

@implementation SineStepViewController

@synthesize sineStepView, lastAcceleration;
- (void)viewDidLoad
{
    theta = 0;
    totalFrames = 0;
    sampleRate = 44100;
    bpm = 200;
    scaleType = 0;
    
    [super viewDidLoad];
    [UIAccelerometer sharedAccelerometer].delegate = self;

    float m = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    SineStepView *ssView = [[SineStepView alloc] initWithFrame:CGRectMake(0, 0, m, m)];
    [self setSineStepView:ssView];
    numSteps = ssView->numSteps;
    frequencies = malloc(sizeof(double) * numSteps);
    [self updateFrequenciesForScaleAndShift];
    
    steps = ssView->steps;
    [self.view setBackgroundColor:[UIColor blackColor]];
    float otherMin = MIN(self.view.bounds.size.height - m,  m / 3.);
    
    CircleSelectView *freqCSView = [[CircleSelectView alloc] initWithFrame:CGRectMake(CIRCLE_SELECT_VIEW_PADDING, m + CIRCLE_SELECT_VIEW_PADDING, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2))];
    freqCSView->totalNumIndexes = 10;
    freqCSView->selector = @selector(updateFrequenciesForScale:);
    [freqCSView setDelegate:self];
    
    CircleSelectView *shiftCSView = [[CircleSelectView alloc] initWithFrame:CGRectMake(otherMin, m + CIRCLE_SELECT_VIEW_PADDING, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2))];
    shiftCSView->totalNumIndexes = 5;
    shiftCSView->selectedIndex = 0;
    shiftCSView->selector = @selector(updateFrequenciesForShift:);
    [shiftCSView setDelegate:self];
    
    CircleSelectView *scaleCSView = [[CircleSelectView alloc] initWithFrame:CGRectMake(2 * otherMin - CIRCLE_SELECT_VIEW_PADDING, m + CIRCLE_SELECT_VIEW_PADDING, otherMin - (CIRCLE_SELECT_VIEW_PADDING  * 2), otherMin - (CIRCLE_SELECT_VIEW_PADDING * 2))];
    scaleCSView->totalNumIndexes = 5;
    scaleCSView->selectedIndex = 0;
    scaleCSView->selector = @selector(updateFrequenciesForScaleType:);
    [scaleCSView setDelegate:self];
    
    BarSelectView *barSelectView = [[BarSelectView alloc] initWithFrame:CGRectMake(3 * otherMin - (2 * CIRCLE_SELECT_VIEW_PADDING), m + CIRCLE_SELECT_VIEW_PADDING, (self.view.bounds.size.width - (3 * otherMin - (2 * CIRCLE_SELECT_VIEW_PADDING))) - CIRCLE_SELECT_VIEW_PADDING, self.view.bounds.size.height - m - 2 *CIRCLE_SELECT_VIEW_PADDING)];
    barSelectView->ratio = .56;
    barSelectView->selector = @selector(updateBPM:);
    [barSelectView setDelegate:self];
    
    [self.view addSubview:ssView];
    [self.view addSubview:freqCSView];
    [self.view addSubview:shiftCSView];
    [self.view addSubview:scaleCSView];
    [self.view addSubview:barSelectView];
    [self.view setNeedsDisplay];
    [self createToneUnit];
    // Stop changing parameters on the unit
    OSErr err = AudioUnitInitialize(toneUnit);
    NSAssert1(err == noErr, @"Error initializing unit: %ld", err);
    
    // Start playback
    err = AudioOutputUnitStart(toneUnit);
    NSAssert1(err == noErr, @"Error starting unit: %ld", err);
    // 
}

- (void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    
    if (lastAcceleration) {
        if (!histeresisExcited && L0AccelerationIsShaking(lastAcceleration, acceleration, 0.7)) {
            histeresisExcited = YES;
            
            [self.sineStepView resetSteps];
        } else if (histeresisExcited && !L0AccelerationIsShaking(lastAcceleration, acceleration, 0.2)) {
            histeresisExcited = NO;
        }
    }
    
    [self setLastAcceleration:acceleration];
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
	NSAssert1(toneUnit, @"Error creating unit: %ld", err);
	
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
	NSAssert1(err == noErr, @"Error setting callback: %ld", err);
	
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
	NSAssert1(err == noErr, @"Error setting stream format: %ld", err);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

@end
