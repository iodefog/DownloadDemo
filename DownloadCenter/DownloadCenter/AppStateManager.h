//
//  AppStateManager.h
//  DownloadCenter
//
//  Created by yufei yan on 12-5-9.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
/****************************
       控制 管理应用程序状态
 ***************************/
@interface AppStateManager : NSObject <AVAudioSessionDelegate>

// 程序即将挂起
UIKIT_EXTERN NSString *const UIApplicationWillBecomeSuspendedNotification;

+ (AppStateManager*)sharedInstance;

// 阻止程序在进入后台之后被挂起
- (void)initPreventSuspending; // 初始化
- (BOOL)activePreventSuspending; // 激活
- (void)pausePreventSuspending; // 暂停
- (void)releasePreventSuspending; // 释放

// 延长后台执行时间
- (void)activePostponeEnterBackground;
- (void)disablePostponeEnterBackground;

// 阻止自动锁屏
- (void)disableAutolock;
// 恢复自动锁屏状态
- (void)resumeAutolock;

@end
