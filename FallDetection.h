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


@interface FallDetection : NSObject

@property (nonatomic,strong) id<FallDetectionDelegate> delegate;

+ (FallDetection*)shareInstance;
- (void) startUpdatesWithInterval:(NSTimeInterval)updateInterval;
- (void) stopUpdates;

//- (void) registerUserToDbname:(NSString *)dbname
//                       withID:(NSString *) withId
//                     dictData:(NSDictionary *)dict
//                     onReturn:(void (^)(BOOL success)) returnBlock;
//
//- (void) queryUserfromDbname:(NSString*) dbname
//                 queryString:(NSString*) query
//                    onReturn:(void (^)(NSDictionary *response)) returnBlock;
//
//- (void) addMessageListener:(NSString*) dbname
//                queryString:(NSString*) query
//                   onReturn:(void (^) (NSDictionary *response)) returnBlock;
//
//-(void) removeMessageListener;
//

@end

@protocol FallDetectionDelegate
-(void) fallScoreAlarm:(FallDetection*)controller;
@end
