//
//  AppStateManager.m
//  DownloadCenter
//
//  Created by yufei yan on 12-5-9.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "AppStateManager.h"
#import "UIApplicationAdditions.h"
//#import "M9.h"

NSString *const UIApplicationWillBecomeSuspendedNotification = @"UIApplicationWillBecomeSuspendedNotification";

@interface AppStateManager ()

@property(nonatomic,retain) AVAudioPlayer *appSoundPlayer;
@property(nonatomic,assign) BOOL playing;
@property(nonatomic,retain) NSURL *soundFileURL;
@property(nonatomic,assign) UIBackgroundTaskIdentifier backgroundTask;
@property(nonatomic,assign) NSInteger backgroundRequestRef;

- (BOOL)isMultitaskingSupported; // 判断是否支持后台任务
- (BOOL)doesNeedPreventSuspending; // 判断是否需要阻止被挂起
- (BOOL)doesNeedPreventPostponeEnterBackground; // 判断是否需要推迟进入后台

@end

@implementation AppStateManager

static AppStateManager *manager = nil;

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
       if (manager == nil) {
           manager = [[AppStateManager alloc] init];
       }
   });
    return manager;
}

@synthesize appSoundPlayer = _appSoundPlayer, playing = _playing, soundFileURL = _soundFileURL, backgroundTask = _backgroundTask, backgroundRequestRef = _backgroundRequestRef;

- (void)dealloc
{
    [self releasePreventSuspending];
    self.soundFileURL = nil;
    self.appSoundPlayer = nil;
    
    [super dealloc];
}

#pragma mark - 阻止程序在进入后台之后被挂起
- (BOOL)doesNeedPreventSuspending
{
    // 暂时禁止该方案
//    return NO;
    // 目前对iPhone不做处理，因其SDK为早于5.0
//    if (!ISIPAD)
//        return NO;
    
    BOOL doesNeedPreventSuspending = NO;
    double systemVersion = [[UIDevice currentDevice].systemVersion doubleValue];
    // 5.0之后需要防止锁屏程序进入后台被挂起
    if (systemVersion >= 5.0f)
        doesNeedPreventSuspending = YES;
    
    return doesNeedPreventSuspending;
}
// 判断是否需要推迟进入后台
- (BOOL)doesNeedPreventPostponeEnterBackground
{
    // 目前对iPhone不做处理，因其SDK为早于5.0
//    if (!ISIPAD)
//        return NO;
    
    BOOL doesNeedPreventPostponeEnterBackground = NO;
    double systemVersion = [[UIDevice currentDevice].systemVersion doubleValue];
    // 5.0之后需要防止锁屏程序进入后台被挂起失败后，延迟程序被挂起
    if (systemVersion >= 5.0f)
        doesNeedPreventPostponeEnterBackground = YES;
    
    return doesNeedPreventPostponeEnterBackground;
}
// 处理声音播放中断
- (void)beginInterruption 
{
    Log(@"阻止程序在进入后台之后被挂起-被打断");
    [self pausePreventSuspending];
}
- (void)endInterruption 
{
    Log(@"阻止程序在进入后台之后被挂起-打断结束");
    [self activePreventSuspending];
}
- (void)initPreventSuspending
{
    // 不需要阻止程序进入后台
    if (![self doesNeedPreventSuspending])
        return;
    
    Log(@"阻止程序在进入后台之后被挂起-初始化");
    if (self.soundFileURL == nil) {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"mute" ofType:@"mp3"];
        NSURL *newURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];
        self.soundFileURL = newURL;
        [newURL release];
    }
    
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
	// 初始化播放器
    if (self.appSoundPlayer == nil) {
        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.soundFileURL error:nil];
        self.appSoundPlayer = newPlayer;
        [newPlayer release];
        [self.appSoundPlayer prepareToPlay];
        [self.appSoundPlayer setVolume:0]; // 无声播放
        [self.appSoundPlayer setNumberOfLoops:-1]; // 无限循环
    }
    
    // 初始化状态
//	[[AVAudioSession sharedInstance] setActive:YES error:nil];
    [self.appSoundPlayer pause];
    self.playing = NO;
}
- (BOOL)activePreventSuspending
{
    // 不需要阻止程序进入后台
    if (![self doesNeedPreventSuspending])
        return NO;
    
    BOOL res = YES;
    Log(@"阻止程序在进入后台之后被挂起-激活");

    if (self.appSoundPlayer == nil)
        [self initPreventSuspending];
    
	res = [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if (res) {
        [[AVAudioSession sharedInstance] setDelegate:self];
        [self.appSoundPlayer play];
        self.playing = YES;
    }
    
    return res;
}
- (void)pausePreventSuspending
{
    // 不需要阻止程序进入后台
    if (![self doesNeedPreventSuspending])
        return;
    
    Log(@"阻止程序在进入后台之后被挂起-暂停");
    if (self.appSoundPlayer == nil)
        return;
    
	NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setActive:NO withFlags:AVAudioSessionSetActiveFlags_NotifyOthersOnDeactivation error:&activationError];
    
    [self.appSoundPlayer pause];
    self.playing = NO;
}
- (void)releasePreventSuspending
{
    Log(@"阻止程序在进入后台之后被挂起-解除");
    if (self.appSoundPlayer != nil) {
        [self pausePreventSuspending];
        self.appSoundPlayer = nil;
    }
}
#pragma mark - 延长后台执行时间
- (void)activePostponeEnterBackground
{
    if (![self doesNeedPreventPostponeEnterBackground])
        return;

    @synchronized (self) {
        if ([self isMultitaskingSupported]) {
            Log(@"backgroundRequestRef is %d", self.backgroundRequestRef);
            if (self.backgroundRequestRef++ != 0)
                return;
            
            if (self.backgroundTask == UIBackgroundTaskInvalid) {
                Log(@"request to run in background");
                self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        Log(@"the program is going to be suspended");
                        // 发送通知，停止当前下载任务
                        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillBecomeSuspendedNotification object:nil];
                    });
                    [self disablePostponeEnterBackground];
                }];
            }
        }
    }
}
- (void)disablePostponeEnterBackground
{
    if (![self doesNeedPreventPostponeEnterBackground])
        return;

    @synchronized (self) {
        if ([self isMultitaskingSupported]) {
            self.backgroundRequestRef = --self.backgroundRequestRef < 0 ? 0 : self.backgroundRequestRef;
            Log(@"backgroundRequestRef is %d", self.backgroundRequestRef);
            if (self.backgroundRequestRef > 0)
                return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.backgroundTask != UIBackgroundTaskInvalid) {
                    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
                    Log(@"requested to quit background");
                    self.backgroundTask = UIBackgroundTaskInvalid;
                }
            });
        }
    }
}
- (BOOL)isMultitaskingSupported
{
	BOOL multiTaskingSupported = NO;
	if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
		multiTaskingSupported = [(id)[UIDevice currentDevice] isMultitaskingSupported];
	}
	return multiTaskingSupported;
}

#pragma mark - 锁屏管理
// 阻止自动锁屏
- (void)disableAutolock
{
    Log(@"阻止自动锁屏");
    // 系统设置已经打开
//    if ([ConfigurationCenter sharedCenter].shouldDisableAutoLockDuringDownload) {
//        [[UIApplication sharedApplication] idleTimerDisabled:YES forType:IdleTypeDownloader];
//    }
}
// 恢复自动锁屏状态
- (void)resumeAutolock
{
    Log(@"恢复自动锁屏");
    [[UIApplication sharedApplication] idleTimerDisabled:NO forType:IdleTypeDownloader];
}

@end
