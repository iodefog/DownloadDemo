//
//  UIApplicationAdditions.m
//  icores
//
//  Created by jinzhu on 11-8-25.
//  Copyright 2011 Ruixin Online Ltd. All rights reserved.
//

#import "UIApplicationAdditions.h"
//#import "NSURLAdditions.h"

//{ added cxt 2012-2-6 
eIdleType idleTypeMask = IdleType_No; // initialize 

static NSString *theAppProductId = nil;

// 离线数据目录 <Application_Home>/Library/PrivateDocuments
NSString *const OfflineDataPath = @"SHPrivateDocuments";

// 上传（包括自动上传）暂时放置正在上传的视频的目录 <Application_Home>/Library/PrivateDocuments/UpLoadVideo
NSString *const UploadVideoData_Path = @"UploadVideo";

// 个人资料离线数据目录 <Application_Home>/Library/
NSString *const PersonalSpaceDataPath = @"PersonalSpace";

@implementation UIApplication(AppInfoAdditions)
- (NSString *)documentPath
{
	NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docPath = [pathList objectAtIndex:0];
	return docPath;
}

- (NSString *)offlineDataPath
{
    NSArray *libPathList = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libPath = [libPathList objectAtIndex:0];
    
    NSString *offlineDataPath = [libPath stringByAppendingPathComponent:OfflineDataPath];
    BOOL isDirectory = NO;
    BOOL needCreateDirectory = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:offlineDataPath isDirectory:&isDirectory]) {
        if (!isDirectory)
            [[NSFileManager defaultManager] removeItemAtPath:offlineDataPath error:nil];
        else 
            needCreateDirectory = NO;
    } 
    
    if (needCreateDirectory) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:offlineDataPath withIntermediateDirectories:YES attributes:nil error:nil])
            offlineDataPath = nil;
    }

    if (offlineDataPath) {
        NSURL * url = [NSURL fileURLWithPath:offlineDataPath isDirectory:YES];
        [url urlShouldSkipBackup:YES];
    }
    
    return offlineDataPath;
}

- (NSString *)upLoadVideoDataPath 
{
    NSString *offlineDataPath = [self offlineDataPath];
    NSString *upLoadVideoDataPath = [offlineDataPath stringByAppendingPathComponent:UploadVideoData_Path];
    BOOL isDirectory = NO;
    BOOL needCreateDirectory = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:upLoadVideoDataPath isDirectory:&isDirectory]) {
        if (!isDirectory)
            [[NSFileManager defaultManager] removeItemAtPath:upLoadVideoDataPath error:nil];
        else 
            needCreateDirectory = NO;
    } 
    
    if (needCreateDirectory) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:upLoadVideoDataPath withIntermediateDirectories:YES attributes:nil error:nil])
            upLoadVideoDataPath = nil;
    }
    
    if (upLoadVideoDataPath) {
        NSURL * url = [NSURL fileURLWithPath:upLoadVideoDataPath isDirectory:YES];
        [url urlShouldSkipBackup:YES];
    }

    return upLoadVideoDataPath;
}

- (NSString *)personalSpaceDataPath
{
    NSString *offlineDataPath = [self offlineDataPath];
    NSString *personalSpaceDataPath = [offlineDataPath stringByAppendingPathComponent:PersonalSpaceDataPath];
    BOOL isDirectory = NO;
    BOOL needCreateDirectory = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:personalSpaceDataPath isDirectory:&isDirectory]) {
        if (!isDirectory)
            [[NSFileManager defaultManager] removeItemAtPath:personalSpaceDataPath error:nil];
        else
            needCreateDirectory = NO;
    }
    
    if (needCreateDirectory) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:personalSpaceDataPath withIntermediateDirectories:YES attributes:nil error:nil])
            personalSpaceDataPath = nil;
    }
    
    if (personalSpaceDataPath) {
        NSURL * url = [NSURL fileURLWithPath:personalSpaceDataPath isDirectory:YES];
        [url urlShouldSkipBackup:YES];
    }
    
    return personalSpaceDataPath;
}

- (NSString *)cachesPath
{
	NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *docPath = [pathList objectAtIndex:0];
	return docPath;
}

- (NSString *)temporaryPath
{
	NSString *path = NSTemporaryDirectory();
	return path;
}

- (NSString *)userInfoPath
{
    // 
	NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *libPath = [pathList objectAtIndex:0];
	NSString *infoPath = [libPath stringByAppendingPathComponent:@"UserInfo"];
	
	BOOL isDir;
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	if(![fileManager fileExistsAtPath:infoPath isDirectory:&isDir] || !isDir)
	{//不存在userInfo文件夹，先创建
		[fileManager createDirectoryAtPath:infoPath withIntermediateDirectories:YES attributes:nil error:NULL];
        NSURL * url = [NSURL fileURLWithPath:infoPath isDirectory:YES];
        [url urlShouldSkipBackup:YES];
        //该文件不参加备份 (解决还原后 DeviceID 相同的问题)
        
	}
	return infoPath;
}

- (void)setProductId:(NSString *)ab
{
	if(ab != theAppProductId)
	{
		[theAppProductId release];
		theAppProductId = [ab copy];
	}
}

- (NSString *)productId
{
	if(theAppProductId)
	{
		return theAppProductId;
	}
	
	NSString *innerProductId = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{	
		innerProductId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"appid_iPad"];
	}
	else
	{
		innerProductId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"appid_iPhone"];
	}
	if(innerProductId == nil)
		innerProductId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"appid"];
	
	if(innerProductId == nil)
		innerProductId = @"000000";
	return innerProductId;
}

- (NSString *)crackFlag
{
	NSBundle *bundle = [NSBundle mainBundle];
	
	//1. 检查Info.plist 是否存在 SignerIdentity这个键名(Key). ;
	if([bundle objectForInfoDictionaryKey:@"SignerIdentity"] != nil)
	{
		return @"1";
	}
	
	//2. 检查3个文件是否存在
	NSFileManager *fileMan = [[[NSFileManager alloc] init] autorelease];
	NSString *bundlePath = [bundle bundlePath];
	NSString *sigPath = [bundlePath stringByAppendingPathComponent:@"_CodeSignature"];	
	if (![fileMan fileExistsAtPath:sigPath]) 
	{
		return @"2";
	}
	
	sigPath = [bundlePath stringByAppendingPathComponent:@"CodeResources"];
	if (![fileMan fileExistsAtPath:sigPath]) 
	{
		return @"3";
	}
	
	sigPath = [bundlePath stringByAppendingPathComponent:@"ResourceRules.plist"];
	if (![fileMan fileExistsAtPath:sigPath]) 
	{
		return @"4";
	}
	
	//3. 对比文件修改时间是否一致, 检测程序是不是被二进制编辑器修改过了	
	NSString *infoPath = [bundlePath stringByAppendingPathComponent:@"Info.plist"];
	NSDate* infoModifiedDate = [[fileMan attributesOfItemAtPath:infoPath error:NULL] fileModificationDate];
	NSString *pkgPath = [[bundle resourcePath] stringByAppendingPathComponent:@"PkgInfo"];
	NSDate* pkgModifiedDate = [[fileMan attributesOfItemAtPath:pkgPath error:NULL] fileModificationDate];
	if([infoModifiedDate timeIntervalSinceReferenceDate] > [pkgModifiedDate timeIntervalSinceReferenceDate])
	{
		return @"5";
	}
	
	NSString *exeName = [bundle objectForInfoDictionaryKey:@"CFBundleExecutable"];
	NSString *exePath = [bundlePath stringByAppendingPathComponent:exeName];
	NSDate* exeModifiedDate = [[fileMan attributesOfItemAtPath:exePath error:NULL] fileModificationDate];
	if([exeModifiedDate timeIntervalSinceReferenceDate] > [pkgModifiedDate timeIntervalSinceReferenceDate])
	{
		return @"6";
	}
	
	return @"0";
}

- (NSString *)productVersion
{
	NSBundle *mainBundle = [NSBundle mainBundle];
	return [mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

- (NSString *)displayName
{
	NSBundle *mainBundle = [NSBundle mainBundle];
	return [mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}

//{ added cxt 2012-2-6 
// bDisable == YES, 不自动锁屏幕
// bDisable == NO,自动锁屏

-(void)idleTimerDisabled:(BOOL)bDisable forType:(eIdleType)eType
{
    if(bDisable)
    {
        idleTypeMask = idleTypeMask | eType;
    }
    else
    {
        idleTypeMask = (eIdleType)(idleTypeMask & (~eType));
    }
    
    if(idleTypeMask == IdleType_No)
    {
        // 自动锁屏
        self.idleTimerDisabled = NO;
    }
    else
    {
        // 不自动锁屏
        self.idleTimerDisabled = YES;
    }
//    self.idleTimerDisabled = bDisable;
}

@end
