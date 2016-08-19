//
//  Reachability+.h
//  iPhoneVideo
//
//  Created by MingLQ on 2012-04-06.
//  Copyright 2012 SOHU. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SHReachability.h"


#if DEBUG

extern BOOL SimulatingReachabilityChange;

@interface SHReachability (test)

- (void)simulateReachabilityChange;
- (void)startSimulateReachabilityChange;
- (void)stopSimulateReachabilityChange;

@end

#endif


#pragma mark -

@interface SHReachability (plus)

+ (SHReachability *)sharedReachability;
+ (NetworkStatus)currentReachabilityStatus;

@end


#pragma mark -

// !!!: for typo
@interface SHReachability (typo)

- (BOOL)startNotifer;
- (void)stopNotifer;

@end

