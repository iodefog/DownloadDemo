//
//  NSURLAdditions.m
//  icores
//
//  Created by jinzhu on 11-3-23.
//  Copyright 2011 Ruixin Online Ltd. All rights reserved.
//

#import "NSURLAdditions.h"
#include <sys/xattr.h>

#define OtherBruHost @"mobile.tv.sohu.com"
#define OtherLoginKey @"operator=login"
#define OtherBindKey @"operator=bind"


#pragma mark -
@implementation NSURL(ExtendedForURLTypes)
- (BOOL)isAppURL {
    if ([self.host isEqualToString:@"itunes.apple.com"]
        || [self.host isEqualToString:@"phobos.apple.com"]) {
        return YES;
        
    } else if ([self.scheme isEqualToString:@"mailto"]
               || [self.scheme isEqualToString:@"tel"]
               || [self.scheme isEqualToString:@"sms"]) {
        return YES;
        
    } else {
        return NO;
    }
}

- (BOOL)isOtherLoginCallback 
{
    if ([[self scheme] isEqualToString:@"http"] &&
		[[self host] isEqualToString:OtherBruHost])
	{
		NSString *string = [NSString stringWithFormat:@"%@", self];
        NSRange range = [string rangeOfString:OtherLoginKey];
        if (range.length) 
        {
            return YES;
        }
	}
	
	return NO;
}

- (BOOL)isOtherBindCallback {
    if ([[self scheme] isEqualToString:@"http"] &&
		[[self host] isEqualToString:OtherBruHost])
	{
	    NSString *string = [NSString stringWithFormat:@"%@", self];
        NSRange range = [string rangeOfString:OtherBindKey];
        if (range.length) 
        {
            return YES;
        }
	}
    return NO;
}


- (BOOL)isExternalStoreURL
{
	if ([[self scheme] isEqualToString:@"http"]&&
		([[self host] isEqualToString:@"item.taobao.com"]))
	{
		
		return YES;
	}
	
	return NO;
}

@end


#pragma mark -
@implementation NSURL(ExtendedForURLComponents)

- (NSString *)stringByReplacingUrlHost:(NSString *)newHost
{
	NSString *oriUrlStr = [self absoluteString];
	
	if(newHost == nil)
		return oriUrlStr;

	NSMutableString *newUrlStr = [NSMutableString stringWithString:oriUrlStr];
	NSUInteger err = [newUrlStr replaceOccurrencesOfString:[self host] 
												withString:newHost 
												   options:NSCaseInsensitiveSearch 
													 range:NSMakeRange(0, [newUrlStr length])];
	
	if (err == 0)
	{
		return oriUrlStr;
	}
	
	return newUrlStr;
}

- (NSURL *)urlByReplacingHost:(NSString *)newHost
{
	NSString *newUrl = [self stringByReplacingUrlHost:newHost];
	return [NSURL URLWithString:newUrl];
}
@end

@implementation NSURL (ExtendedForSkipBackup)

-(BOOL)urlShouldSkipBackup:(BOOL)shouldSkipBackup
{
    NSString * sysVersionString = [UIDevice currentDevice].systemVersion;
    if ([sysVersionString isEqualToString:@"5.0.1"])
    {
        u_int8_t b;
        if (shouldSkipBackup) 
        {
            b = 1;
        }
        else {
            b = 0;
        }
        int value = setxattr([[self path] fileSystemRepresentation], "com.apple.MobileBackup", &b, 1, 0, 0);
        if (value == 0)
        {
            return YES;
        }
        else {
            return NO;
        }
    }
    else 
    {
        double sysVersion = [sysVersionString doubleValue];
        if (sysVersion < 5.1) 
        {
            return NO;
        }
        else 
        {
            NSNumber * backUpValue = [NSNumber numberWithBool:shouldSkipBackup];
            if ([self respondsToSelector:@selector(setResourceValue:forKey:error:)]) 
            {
                // !!!: NSURLIsExcludedFromBackupKey available since sysVersion >= 5.1
                #ifndef NSURLIsExcludedFromBackupKey
                    #define NSURLIsExcludedFromBackupKey @"NSURLIsExcludedFromBackupKey"
                #endif
                return [self setResourceValue:backUpValue forKey:NSURLIsExcludedFromBackupKey error:nil];
            }
            else 
            {
                return NO;
            }
        }
    }
    return NO;
}
@end
