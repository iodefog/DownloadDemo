//
//  NSArray+sort.m
//  DownloadCenter
//
//  Created by MingLQ on 2013-09-03.
//  Copyright (c) 2013年 SOHU. All rights reserved.
//

#import "NSArray+sort.h"

@implementation NSArray (sort)

- (NSArray*)sortArrayByKey:(id)key inAscending:(BOOL)ascending {
    if (self == nil || self.count == 0)
        return self;
    
    NSSortDescriptor *descriptor =
    [[[NSSortDescriptor alloc] initWithKey:key
                                 ascending:ascending
                                  selector:@selector(compare:)] autorelease];
    
    NSArray *descriptors = [NSArray arrayWithObjects:descriptor, nil];
    
    return [self sortedArrayUsingDescriptors:descriptors];
}

@end
