//
//  NSURLAdditions.h
//  icores
//
//  Created by jinzhu on 11-3-23.
//  Copyright 2011 Ruixin Online Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


#pragma mark -
@interface NSURL(ExtendedForURLTypes)
- (BOOL)isAppURL;
- (BOOL)isExternalStoreURL;
- (BOOL)isOtherLoginCallback;
- (BOOL)isOtherBindCallback;
@end


#pragma mark -
@interface NSURL(ExtendedForURLComponents)

- (NSString *)stringByReplacingUrlHost:(NSString *)newHost;
- (NSURL *)urlByReplacingHost:(NSString *)newHost;
@end

@interface NSURL (ExtendedForSkipBackup)
-(BOOL)urlShouldSkipBackup:(BOOL)shouldSkipBackup;
@end