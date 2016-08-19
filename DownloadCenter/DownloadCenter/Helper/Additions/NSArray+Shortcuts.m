//
//  NSArray+Shortcuts.m
//  SoHuHDVideo
//
//  Created by MingLQ on 2011-08-04.
//  Copyright 2011 SOHU. All rights reserved.
//

#import "NSArray+Shortcuts.h"


@implementation NSArray (Shortcuts)

@dynamic count;
@dynamic firstObject, lastObject;

- (id)firstObject {
    return [self objectOrNilAtIndex:0];
}

- (id)objectOrNilAtIndex:(NSUInteger)index {
    return [self containsIndex:index] ? [self objectAtIndex:index] : nil;
}

- (BOOL)containsIndex:(NSUInteger)index {
    return index < self.count;
}

@end


@implementation NSMutableArray (Shortcuts)

- (void)addObjectOrNil:(id)anObject {
    if (anObject) {
        [self addObject:anObject];
    }
}

- (BOOL)insertObjectOrNil:(id)anObject atIndex:(NSUInteger)index {
    if (anObject && index <= self.count) {
        [self insertObject:anObject atIndex:index];
        return YES;
    }
    return NO;
}

- (BOOL)replaceObjectAtIndex:(NSUInteger)index withObjectOrNil:(id)anObject {
    if (anObject && index < self.count) {
        [self replaceObjectAtIndex:index withObject:anObject];
        return YES;
    }
    return NO;
}

@end

