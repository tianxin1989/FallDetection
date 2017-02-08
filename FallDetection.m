//
//  FallDetection.m
//  PRES
//
//  Created by Arai on 8/10/16.
//  Copyright © 2016 ddb. All rights reserved.
//

#import "FallDetection.h"



#pragma mark - DataSegment
@implementation DataSegment
{
    double ahistory[61];
    int index;
    int fallScore;
}
@synthesize dropThreshold;


-(id)init
{
    self = [super init];
    if (self != nil)
    {
        index = 61;
        fallScore = 10;
        _isDeciding = NO;
        dropThreshold = 1;
    }
    return self;
}


-(BOOL)addData:(double)a
{
   //  NSLog(@"addData");
    // If this segment is not full, add a new value to the history.
    if (index > 0) {
        --index;
        ahistory[index] = a;
     // NSLog(@"acce %f", a);
    } else {
        return 0;
    }
    return 1;
}


-(void)reset
{
    // Clear out our components and reset the index to 60 to start filling values again.
    NSLog(@"reset");
    memset(ahistory, 0, sizeof(ahistory));
    index = 61;
    fallScore = 10;
    _isDeciding = NO;
}


-(double) calculateAcceNorm:(double)x y:(double)y z:(double)z
{
   //  NSLog(@"calculateAcceNorm");
    return sqrt((x*x)+(y*y)+(z*z));
}


-(double) maxValue
{
  //  NSLog(@"maxValue");
    double max = 1.0;
    for (int t = 0; t < 60; ++t)
    {
        double dd = ahistory[t];
        if (dd > max) max = dd;
    }
    return max;
}


-(double) minValue
{
  //   NSLog(@"minValue");
    double min = 1.0;
    for (int i = 0; i < 60; ++i)
    {
        double dd = ahistory[i];
        if (dd < min) min = dd;
    }
    return min;
}


-(double) medianValue
{
    // sorting ahistory
    NSMutableArray *objcArray = [NSMutableArray array];
    for (int i = 0; i < 60; ++i) {
        [objcArray addObject:[NSNumber numberWithFloat:ahistory[i]]];
        NSLog(@"%f",[objcArray[i] floatValue]);
    }
    // smallest to largest
    [objcArray sortUsingSelector:@selector(compare:)];
    int findIdx = (60+1) /2; // find mid point..
    return [objcArray[findIdx] floatValue];
}



-(double) getMeanValueofRange
{
   //  NSLog(@"getMeanValueofRange");
    double sum = 0;
    for (int i=0; i<60; ++i) {
        sum += fabs(ahistory[i] - ahistory[i+1]);
    }
    return sum/60;
}


-(double) getMeanValue
{
 //   NSLog(@"getMeanValue");
    double sum = 0;
    for (int i=0; i<60; ++i) {
        sum += ahistory[i];
    }
    return sum/60;
}


-(double) normaliseThis:(double) val min:(double) min max:(double)max
{
    return fabs((val-min)/ (max-min)); 
}


-(void) testingFindPeaks
{
    NSLog(@"Testing findPeaks");
    int noOfPeaks = 0;
    double peakRange[60];
    double peaks[60];

    
    //Time t is a peak if (y(t) > y(t-1)) && (y(t) > y(t+1))
    for (int t=0; t<60; ++t)  {
//        // Logging purpose only...
//        if (ahistory[t] == uppThreshold) {
//             NSLog(@" %f at index: %d -----> highest", ahistory[t], t);
//        } else if (ahistory[t] == lowThreshold) {
//             NSLog(@" %f at index: %d -----> lowest", ahistory[t], t);
//        } else {
             NSLog(@" %f at index: %d", ahistory[t], t);
//        }
        
        // hits lower threshold
        if (ahistory[t] < [kLowerThreshold doubleValue] ) {
            if (ahistory[t] < ahistory[t-1] && ahistory[t] < ahistory[t+1]) {  // peak range
             //   if (ahistory[t-1] - ahistory[t] > 1.7) {
                noOfPeaks++;
                double diff = ahistory[t+1] - ahistory[t];
                peaks[t] = [self normaliseThis:diff min:ahistory[t] max:ahistory[t+1]];
                NSLog(@"        lower peak range %f", peaks[t]);
            //    }
            }
            
        }
        
        // hits upper threshold
        if (ahistory[t] > [kUpperThreshold doubleValue]) {
            if ( (ahistory[t] > ahistory[t-1]) && (ahistory[t] > ahistory[t+1])) { // peak range
              //  if (ahistory[t] - ahistory[t-1] > 1.7) {
                noOfPeaks++;
                double diff = ahistory[t] - ahistory[t+1];
                peaks[t] = [self normaliseThis:diff min:ahistory[t+1] max:ahistory[t]];
                NSLog(@"        upper peak range %f", peaks[t]);
             //   }
            }
        }
    }
}


-(int) findPeaks
{
    NSLog(@"findPeaks");
    _isDeciding = YES;
    
    //Time t is a peak if (y(t) > y(t-1)) && (y(t) > y(t+1))
    for (int t=0; t<60; ++t)
    {
        // hits lower threshold
        if (ahistory[t] < [kLowerThreshold doubleValue]) {
            if (ahistory[t] < ahistory[t-1] && ahistory[t] < ahistory[t+1]) { // peak range
                double diff = ahistory[t+1] - ahistory[t];
                diff = [self normaliseThis:diff min:ahistory[t] max:ahistory[t+1]]; // normalised > 0.5
                if (diff > [kPeakRange doubleValue]) {
                    NSLog(@"        lower peak range %f", diff);
                    fallScore --;
                }
            }
        }
        
        // hits upper threshold
        if (ahistory[t] > [kUpperThreshold doubleValue]) {
            if ( (ahistory[t] > ahistory[t-1]) && (ahistory[t] > ahistory[t+1])) { // peak range
                double diff = ahistory[t] - ahistory[t+1];
                diff = [self normaliseThis:diff min:ahistory[t+1] max:ahistory[t]]; // normalised > 0.5
                if (diff > [kPeakRange doubleValue]) {
                    NSLog(@"        upper peak range %f", diff);
                    fallScore --;
                }
            }
        }
    }
    
    if (!(fallScore < [kFallScoreMax intValue]+dropThreshold &&
          fallScore >= [kFallScoreMin intValue]))
    {
        [self reset];
    }
    return fallScore;
}




-(int) findPeaksWithinThreshold
{
     NSLog(@"findPeaksWithinThreshold");
    _isDeciding = YES;

    // float dropThreshold = 1;
    double mean = [self getMeanValue];
    NSLog(@"mean: %f ", mean);
    
    for (int t=0; t<60; ++t) {
        if ((ahistory[t] - ahistory[t-1]) >  mean &&
            (ahistory[t] - ahistory[t+1]) >  mean )  //  peaks that are more than the average acceleration
        {
            if ((ahistory[t] - ahistory[t-1]) > mean+dropThreshold &&
                (ahistory[t] - ahistory[t+1]) > mean+dropThreshold )  //  peaks that exceeds mean + dropThreshold
            {
                NSLog(@"more than maxDelta: %f at index: %d", ahistory[t], t);
                fallScore = fallScore - 1;
            }
        }
    }
    
    if (!(fallScore < [kFallScoreMax intValue]+dropThreshold &&
          fallScore >= [kFallScoreMin intValue]))
    {
        [self reset];
    }
    return fallScore;
}

@end


//======================================FALL DETECTION=======================================

#pragma mark - FALL DETECTION CLASS



@interface FallDetection ()
@property (nonatomic,strong) CMMotionManager *motionManager;
@property (nonatomic) double acceNorm;
// @property (nonatomic) DataSegment *dataSegment;
@property (nonatomic) float startTime;

@end


@implementation FallDetection
@synthesize motionManager;
@synthesize dataSegment;
@synthesize delegate;


+(FallDetection*)shareInstance {
    static FallDetection *shareInstance;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        shareInstance = [[FallDetection alloc] init];
        shareInstance.motionManager = [[CMMotionManager alloc]init];
        shareInstance.dataSegment = [[DataSegment alloc] init];
    });
    return shareInstance;
}


// Note: 0.01 => 100 times a second, if sampling 6 secs of data, will be 100 x 6secs
// sampling readings 10 times / sec
- (void) startUpdatesWithInterval:(NSTimeInterval)updateInterval
{

    if ([motionManager isAccelerometerAvailable] == YES) {
        [motionManager setAccelerometerUpdateInterval:updateInterval];
        [motionManager startAccelerometerUpdates]; // startAccelerometerUpdates];
    }
    
   // ViewController * __weak weakSelf = self;
    [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
                                         withHandler:^(CMAccelerometerData *data, NSError *error)
     {
         // normalise acceleration
         _acceNorm = [dataSegment calculateAcceNorm:data.acceleration.x
                                                  y:data.acceleration.y
                                                  z:data.acceleration.z];
         // just for draw graph..
         [delegate fallGraphDraw:_acceNorm];
         
         // collect data
         if (![dataSegment addData:_acceNorm] && !dataSegment.isDeciding) {             
           
          //    NSLog (@"dataSegment.isDeciding: %i", dataSegment.isDeciding);
         /*    //for my testing..
              [self stopUpdates];
              [dataSegment testingFindPeaks];*/
         
             int score = [dataSegment findPeaks];
             if (score < [kFallScoreMax intValue] + dataSegment.dropThreshold &&
                 score >= [kFallScoreMin intValue])
             {
                 NSLog(@"fallscore %d", score); // NSLog(@"Are you ok!?");
                 [delegate fallScoreAlarm:self score:score];
             } else {
                 [delegate fallScoreUpdate:score];
             }
        
         };
     }];
}

-(void) resumeCheck
{
    [dataSegment reset];
}

- (void)stopUpdates
{
    [motionManager stopAccelerometerUpdates];
}

-(BOOL) checkIsActive
{
    return [motionManager isAccelerometerActive];
}



@end
