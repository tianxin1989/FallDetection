//
//  FallDetection.m
//  PRES
//
//  Created by Arai on 8/10/16.
//  Copyright © 2016 ddb. All rights reserved.
//

#import "FallDetection.h"



#pragma mark - DataSegment

@interface DataSegment : NSObject

-(BOOL)addData:(double)a;
-(void)reset;
@property (nonatomic) BOOL isDeciding;
@end


@implementation DataSegment
{
    double ahistory[61];
    int index;
    int fallScore;
}


-(id)init
{
    self = [super init];
    if (self != nil)
    {
        index = 61;
        fallScore = 10;
        _isDeciding = NO;
    }
    return self;
}


-(BOOL)addData:(double)a
{
    // If this segment is not full, add a new value to the history.
    if (index > 0) {
        --index;
        ahistory[index] = a;
     //   NSLog(@"acce %f", a);
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
    return sqrt((x*x)+(y*y)+(z*z));
}


-(double) maxValue
{
    double max = 0.0;
    for (int t = 0; t < 60; ++t)
    {
        double dd = ahistory[t];
        if (dd > max) max = dd;
    }
    return max;
}


-(double) minValue
{
    double min = 0.0;
    for (int i = 0; i < 60; ++i)
    {
        double dd = ahistory[i];
        if (dd < min) min = dd;
    }
    return min;
}


-(double) getMeanValueofRange
{ //return ([self maxValue] - [self minValue])/60;
    double sum = 0;
    for (int i=0; i<60; ++i) {
        sum += fabs(ahistory[i] - ahistory[i+1]);
    }
    return sum/60;
}


-(double) getMeanValue
{
    double sum = 0;
    for (int i=0; i<60; ++i) {
        sum += ahistory[i];
    }
    return sum/60;
}

//-(void) writeJson
//{
//    NSError *err;
//    id obj = ahistory;
//    NSData *newData = [NSJSONSerialization dataWithJSONObject:[id (ahistory)]
//                                                      options:NSJSONWritingPrettyPrinted
//                                                        error:&err];
//}

-(void) findPeaks
{
    NSMutableArray *peaks = [[NSMutableArray alloc] init];
    //Time t is a peak if (y(t) > y(t-1)) && (y(t) > y(t+1))
    for (int t=0; t<60; ++t) {
        if ( (ahistory[t] > ahistory[t-1]) && (ahistory[t] > ahistory[t+1]) ) {
            NSLog(@"its a peak: %f at index: %d", ahistory[t], t);
            [peaks addObject:[NSNumber numberWithDouble:ahistory[t]]];
        }
    }
}


-(int) findPeaksWithinThreshold
{
    _isDeciding = YES;
    
    //NSLog(@"findPeaksWithinThreshold");
    float dropThreshold = 1;
    double mean = [self getMeanValue];
    NSLog(@"mean: %f", mean);
    
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
    
    if (!(fallScore < 10 && fallScore >= 7)) {
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
@property (nonatomic) DataSegment *dataSegment;
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
        shareInstance.dataSegment = [[DataSegment alloc]init];
    });
    return shareInstance;
}


// Note: 0.01 => 100 times a second, if sampling 6 secs of data, will be 100 x 6secs
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
         [delegate fallGraphDraw:_acceNorm];
         // collect data
         if (![dataSegment addData:_acceNorm] && !dataSegment.isDeciding) {             
            // if (!dataSegment.isDeciding)
            // {
                 int score = [dataSegment findPeaksWithinThreshold];
                 if (score < 10 && score >= 7) {
                     NSLog(@"fallscore %d", score);
                     //NSLog(@"Are you ok!?");
                     [delegate fallScoreAlarm:self score:score];
                 } else {
                     [delegate fallScoreUpdate:score];
                 }
           //  }
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
