//
//  DownloadManager+Observer.m
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadManager+Observer.h"
//#import "DataCenterHeaders.h"
#import "SHDownloadDataManager_Internal.h"
#import "AppStateManager.h"
#import "NSArray+sort.h"

// 记录最近一次的网络状态
static NetworkStatus gLastestNetworkStatus;
// 是否程序在后台状态
static BOOL gIsAppInBackground = NO;

@implementation SHDownloadManager (Observer)

// 注册监听通知
- (void)registerNotifications
{
    // 初始化网络状态
//    [[ConfigurationCenter sharedCenter] startReachabilityNotifier];
    gLastestNetworkStatus = [SHReachability currentReachabilityStatus];
//    [[ConfigurationCenter sharedCenter] currentReachabilityStatus];

    // 网络状态变化
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChanged:) name:kSoHuReachabilityChangedNotification object:nil];
    
    // 程序进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    // 程序进入活动状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // 程序进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    // 程序即将挂起
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeSuspended:) name:UIApplicationWillBecomeSuspendedNotification object:nil];
    
    // 程序启动
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    // 分段任务合并状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mp4boxStatusDidChanged:) name:
     kExporteStatusNotification object:nil];
}
// 取消监听通知
- (void)unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/*
 网络变化处理
 
 3G <-> WiFi <-> None
 暂停下载任务:
    1. [处于前台]WiFi->None
    2. 3G->None
    3. [处于前台]WiFi->3G
 恢复下载任务: 检测因网络不稳定而出错的任务
    1. [处于前台]None->WiFi
    2. [用户同意，且处于前台]None->3G
    3. 3G->WiFi
    4. [用户同意]WiFi->3G
 */
- (void)reachabilityDidChanged: (NSNotification*)notification
{
    if([notification.object isKindOfClass:[SHReachability class]])
    {
        NetworkStatus currentNetworkStatus = [SHReachability currentReachabilityStatus] ;//[[ConfigurationCenter sharedCenter] currentReachabilityStatus];
        if (gLastestNetworkStatus == currentNetworkStatus) {
            Log(@"网络状态未发生改变");
            return;
        }

        switch (currentNetworkStatus) {
            case NotReachable:
            {
                //无网络
                Log(@"无网络");
                
                [self saveAndPauseTasksWithCurrentStateOfRuningAndWaiting];
                
                break;
            }
            case ReachableViaWiFi:
            {
                //WiFi
                Log(@"WiFi");
                
                if (!gIsAppInBackground) {
                    [self restoreTasksWithRecordedStateOfRuningAndWaiting];
                }
                
                break;
            }
            case ReachableViaWWAN:
            {
                //非WiFi
                Log(@"非WiFi");
                
//                if (![[ConfigurationCenter sharedCenter] shouldProcessHugeFlowActionWhenWiFiTo3G])
                if (NO)
                {
                    [self saveAndPauseTasksWithCurrentStateOfRuningAndWaiting];
                }
                else
                {
                    //3G允许下载，考虑联通合作情况
                    NSArray * runningTaskArray = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateRunning];
                    for (int i = 0; i < [runningTaskArray count]; i++)
                    {
                        SHDownloadTask * task = [runningTaskArray objectOrNilAtIndex:i];
//                        task.shouldIngoreCarrierUrl = NO;
                        if (task.runningState == DownloadTaskRunningStateDownloading)
                        {
                            [self downloadFile:task];
                        }
                    }
//                    NSArray * waitingArray = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateWaiting];
//                    for (int i = 0 ; i < [runningTaskArray count]; i++)
//                    {
//                        DownloadTask * task = [waitingArray objectOrNilAtIndex:i];
//                        task.shouldIngoreCarrierUrl = NO;
//                    }
                }
                break;
            }
            default:
                //不处理
                break;
        }
        
        gLastestNetworkStatus = currentNetworkStatus;
    }
}

/* 
 程序进入活动状态
 
 设置阻止程序进入后台机制
 */
- (void)applicationDidBecomeActive:(NSNotification*)notification
{
    Log(@"程序进入活动状态");

    BOOL isAvailable = NO;
    NetworkStatus networkStatus = [SHReachability currentReachabilityStatus];//[[ConfigurationCenter sharedCenter] currentReachabilityStatus];
    if (networkStatus == ReachableViaWiFi) 
    {
        isAvailable = YES;
    }
    else if (networkStatus == ReachableViaWWAN) 
    {
//        if ([[ConfigurationCenter sharedCenter] shouldProcessHugeFlowActionWhenWiFiTo3G])
        if(YES)
        {
            isAvailable = YES;
        }
        else
        {
            if (self.restoreTasks && [self.restoreTasks count] > 0)
            {
                return;
            }
        }
    }
    if (isAvailable) 
    {
        Log(@"网络状态正常，恢复下载状态");
        [self restoreTasksWithRecordedStateOfRuningAndWaiting];
    }
}
/* 
 程序进入后台
 
 记录并暂停当前状态为开始和等待的任务
 */
- (void)applicationDidEnterBackground:(NSNotification*)notification
{
    Log(@"程序进入后台");

    if ([self isThereAnyBusiness]) { // 还有下载任务，需要激活挂起阻止机制
//        [[AppStateManager sharedInstance] activePreventSuspending];
//        [[AppStateManager sharedInstance] activePostponeEnterBackground]; // 同时激活延迟挂起
    } else { // 没有下载任务，暂停挂起阻止机制
//        [[AppStateManager sharedInstance] pausePreventSuspending];
    }
}
/*
 程序进入前台
 
 [网络状态正常]恢复记录中的暂停任务为开始和等待状态
 */
- (void)applicationWillEnterForeground:(NSNotification*)notification
{
    Log(@"程序进入前台");
    if (gIsAppInBackground) {
        gIsAppInBackground = NO;
    } else {
//        [[AppStateManager sharedInstance] disablePostponeEnterBackground];
    }
}
/* 
 程序将要挂起
 */
- (void)applicationWillBecomeSuspended:(NSNotification*)notification
{
    [self saveAndPauseTasksWithCurrentStateOfRuningAndWaiting];
}
/*
 程序启动
 */
- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. 升级存盘位置和格式
        [SHDownloadDataManager upgradeDownloadTasksSaveInfo];
        // 2. 读取已下载任务信息
        self.downloadTasks = [SHDownloadDataManager loadDownloadTasksInfo];
        // 3. 删除冗余文件
        [SHDownloadDataManager deleteInvalidFilesAgainstTaskList:self.downloadTasks];
        // 4. 修正下载任务状态
        [self doPauseAllDownloadTasks];
        // 5. 恢复需要合并的任务
        [self mergeAllAvailableTasks];
        // 6. 恢复下载
        [self saveAndPauseTasksWithCurrentStateOfRuningAndWaiting];
    });
}

// 分段任务合并状态变化
- (void)mp4boxStatusDidChanged:(NSNotification*)notification
{
    MP4Box *aCurrBox = [notification object];
    exportStatus status = aCurrBox.exportSession.status;
    SHDownloadTask *task = aCurrBox.userInfo;
    NSAssert([task isKindOfClass:[SHDownloadTask class]], @"%@:UserInfo is invalid!", NSStringFromSelector(_cmd));
    
    switch (status) { 
        case EXPORT_Unknown:
            Log(@"合并《%@》出现未知错误", task.videoTitle);
        case EXPORT_Failed:
        {
            Log(@"合并《%@》失败", task.videoTitle);
            if (task.remainMergeRetryTimes > 0)
            {
                task.remainMergeRetryTimes--;
                task.downloadState = SHDownloadTaskStateRunning;
                [self mergeSegmentedTask:task];
            }
            else
            {
                BDebugLog(@"zy :: SHDownloadTaskErrorFileBroken...11");
                task.errorCode = SHDownloadTaskErrorFileBroken;
                [self handleError:task];
            }
            
            break;
        }
        case EXPORT_Cancelled:
        {
            Log(@"合并《%@》被取消", task.videoTitle);
            task.errorCode = SHDownloadTaskErrorMergeInterrupted;
            
            [self handleError:task];
            break; 
        }
        case EXPORT_Completed:
        {
            Log(@"合并《%@》完成", task.videoTitle);
            //分段视频下载完毕后，修正大小属性
            unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[task downloadFilePath] error:nil] fileSize];
            
            [task setTotalSize:fileSize];
            
            [task setDownloadState:SHDownloadTaskStateCompleted];//缓存状态
            task.errorCode = SHDownloadTaskNoError;
            
            //存盘
            [self saveDownloadTasks];
            [self postDownloadTaskStatusDidUpdated:task];
            [self finishOneDownloadTask:task];
            //删除缓存文件
            [task eraseCachedData];

            break; 
        }
        default:
            break;
    }
}

@end
