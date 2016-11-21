//
//  FallDetection.h
//  PRES
//
//  Created by Arai on 8/10/16.
//  Copyright © 2016 ddb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#include <sys/types.h>
#include <sys/sysctl.h>


@protocol FallDetectionDelegate;

@interface DataSegment : NSObject
-(BOOL)addData:(double)a;
-(void)reset;
@property (nonatomic) BOOL isDeciding;
@property (nonatomic) float dropThreshold;
@end


@interface FallDetection : NSObject
@property (nonatomic) DataSegment *dataSegment;
@property (nonatomic,strong) id<FallDetectionDelegate> delegate;

+ (FallDetection*)shareInstance;
- (void) startUpdatesWithInterval:(NSTimeInterval)updateInterval;
- (void) stopUpdates;
- (BOOL) checkIsActive;
- (void) resumeCheck;


@end

@protocol FallDetectionDelegate
-(void) fallScoreAlarm:(FallDetection*)controller score:(int)score;
-(void) fallGraphDraw:(double)value;
-(void) fallScoreUpdate:(int)value;
@end
