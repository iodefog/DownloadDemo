//
//  UIApplicationAdditions.h
//  icores
//
//  Created by jinzhu on 11-8-25.
//  Copyright 2011 Ruixin Online Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//{ added cxt 2012-2-6 
typedef enum _eIdleType 
{
    IdleType_No = 0,
    IdleType_videoPlayer = 1,
    IdleTypeDownloader = IdleType_videoPlayer << 1,
    IdleTypeUploader = IdleType_videoPlayer << 2,
    IdleTypeWirelessShare = IdleType_videoPlayer << 3
    
}eIdleType; 

// 离线数据目录 <Application_Home>/Library/Private Documents
UIKIT_EXTERN NSString *const OfflineDataPath;

@interface UIApplication(AppInfoAdditions)
- (NSString *)documentPath;
- (NSString *)offlineDataPath;
- (NSString *)upLoadVideoDataPath;
- (NSString *)personalSpaceDataPath;
- (NSString *)cachesPath;
- (NSString *)temporaryPath;
- (NSString *)userInfoPath;       //该文件夹不参与备份

- (NSString *)productId;
- (void)setProductId:(NSString *)ab;
- (NSString *)crackFlag; //破解标识，返回@“0”标识非破解，其它值为破解方式。

- (NSString *)productVersion;
- (NSString *)displayName;

//{ added cxt 2012-2-6 
-(void)idleTimerDisabled:(BOOL)bDisable forType:(eIdleType)eType;


@end
