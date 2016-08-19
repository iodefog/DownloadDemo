//
//  Reachability+.m
//  iPhoneVideo
//
//  Created by MingLQ on 2012-04-06.
//  Copyright 2012 SOHU. All rights reserved.
//

#import "SHReachability+.h"


#if DEBUG

BOOL SimulatingReachabilityChange = NO;

@implementation SHReachability (test)

- (void)simulateReachabilityChange {
    SimulatingReachabilityChange = !SimulatingReachabilityChange;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSoHuReachabilityChangedNotification object:nil];
}
- (void)startSimulateReachabilityChange {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startSimulateReachabilityChange) object:nil];
    [self performSelector:_cmd withObject:nil afterDelay:5];
    [self simulateReachabilityChange];
}
- (void)stopSimulateReachabilityChange {
    SimulatingReachabilityChange = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startSimulateReachabilityChange) object:nil];
}

@end

#endif


#pragma mark -

@implementation SHReachability (plus)

static SHReachability *SharedReachability = nil;

+ (SHReachability *)sharedReachability {
    if (SharedReachability) {
        return SharedReachability;
    }
    
    @synchronized(self) {
        if (!SharedReachability) {
            SharedReachability = [[SHReachability reachabilityForInternetConnection] retain];
        }
    }
    
    return SharedReachability;
}

+ (NetworkStatus)currentReachabilityStatus {
#if DEBUG
    /* TEST: awayls returns WWAN
    return ReachableViaWWAN;
    #warning simulating WWAN! */
    
    /* TEST: returns WWAN if WiFi */
//    if (SimulatingReachabilityChange) {
//        NetworkStatus currentReachabilityStatus = [[self sharedReachability] currentReachabilityStatus];
//        if (currentReachabilityStatus == ReachableViaWiFi) {
//            return ReachableViaWWAN;
//        }
//        return currentReachabilityStatus;
//    }
#endif
    
    // return [[ConfigurationCenter sharedCenter] currentReachabilityStatus];
    
    // without ConfigurationCenter
    return [[self sharedReachability] currentReachabilityStatus];
}

@end


#pragma mark -

// !!!: for old code
@implementation SHReachability (typo)

- (BOOL)startNotifer {
    return [self startNotifier];
}

- (void)stopNotifer {
    [self stopNotifier];
}

@end

