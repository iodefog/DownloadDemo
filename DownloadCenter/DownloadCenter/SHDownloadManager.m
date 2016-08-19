//
//  DownloadManager.m
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadManager_Internal.h"
//#import "M9.h"
#import "SHDownloadDataManager_Internal.h"
#import "AppStateManager.h"   
#import "JSONKit.h"
//#import "ConfigurationCenter.h"
#import "SHDownloadTask.h"
#import "ASIHTTPRequest.h"
#import "NSArray+sort.h"
// for get disk size
#import <sys/param.h>
#import <sys/mount.h>
#import <sys/xattr.h>
//#import "LogCenterHeaders.h"

//获取硬盘剩余空间
long long freeSpaceSize();

@interface SHDownloadManager () {
    
}

@property (nonatomic, retain) NSMutableArray *logArray;
@end

@implementation SHDownloadManager

// 下载任务请求中用户数据字段
NSString *const HTTPRequestDownloadTaskKey = @"HTTPRequestDownloadTaskKey";
// 下载文件保存子路径
NSString *const DownloadStoreSubPath = @"SHVideoDownload";
// 下载缓存文件后缀
NSString *const DownloadCacheFileExtension = @"tmp";
// 下载文件后缀
NSString *const DownloadFileExtension = @"mp4";
// 下载任务队列状态发生变化
NSString *const DownloadTaskQueueUpdatedNotification = @"DownloadTaskQueueUpdatedNotification";
// 下载发送本地通知的内容
NSString *const kDownloadTaskStateLocalNotificationKey = @"kDownloadTaskStateLocalNotificationKey";
// 任务下载状态变化:
NSString *const DownloadTaskStatusDidUpdatedNotification = @"DownloadTaskStatusDidUpdatedNotification";
//下载进度变化
NSString *const DownloadTaskProgressDidUpdatedNotification = @"DownloadTaskProgressDidUpdatedNotification";

// 下载任务
NSString *const DownloadTaskNotificationKey = @"DownloadTaskNotificationKey";

NSString *const kDownloadBaseForderPathKey = @"kDownloadBaseForderPathKey";

#pragma mark - NSObject
static SHDownloadManager *manager = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (manager == nil) {
            manager = [[SHDownloadManager alloc] init];
        }
    });
    return manager;
}

- (id)init {
    if (self = [super init]) {
        // 0. 内部数据初始化
        self.priorTasks = [NSMutableArray array];
        self.logArray = [NSMutableArray array];
        [self.logArray addObject:@"初始化 SHDownloadManager :: "];
        [SHDownloadDataManager saveDownloadTasksLog:self.logArray];
        [self initDownloadQueue];
        self.needUpdateRestoreTasks = YES;
        self->_organizedForm = SHDownloadTaskOrganizedFormCreatedTime;
    }
    return self;
}

- (void)dealloc {
    self.downloadTasks = nil;
    self.priorTasks = nil;
    self.organizedDownloadTasks = nil;
    [self cleanupRestoreLists];
    [self deallocDownloadQueue];

    [self.failedRetryTimer invalidate];
    self.failedRetryTimer = nil;
    [self.taskListRetryTimer invalidate];
    self.taskListRetryTimer = nil;

    [super dealloc];
}

#pragma mark - 辅助方法
//根据任务状态获取任务列表
- (NSMutableArray*)getAllDownloadTasksByDownloadState:(SHDownloadTaskState)downloadState {
    if (self.downloadTasks == nil || [self.downloadTasks count] == 0) {
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (SHDownloadTask *task in self.downloadTasks) {
        task = [task isKindOfClass:[SHDownloadTask class]] ? task : nil;
        if (task && task.downloadState == downloadState) {
            [array addObject:task];
        }
    }
    
    return array;
}
// 获取除某个状态之外的任务列表
- (NSMutableArray*)getAllDownloadTasksExceptDownloadState:(SHDownloadTaskState)downloadState {
    if (self.downloadTasks == nil || [self.downloadTasks count] == 0) {
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (SHDownloadTask *task in self.downloadTasks) {
        task = [task isKindOfClass:[SHDownloadTask class]] ? task : nil;
        if (task && task.downloadState != downloadState) {
            [array addObject:task];
        }
    }
    
    return array;
}

// 初始化下载队列
- (void)initDownloadQueue {
	self.downloadQueue = [[[ASINetworkQueue alloc] init] autorelease];
	self.downloadQueue.showAccurateProgress = YES;//显示精确的进度
	self.downloadQueue.shouldCancelAllRequestsOnFailure = NO;//防止队列的行动全部被取消
    
    [self.downloadQueue go];
}

// 释放下载队列
- (void)deallocDownloadQueue {
    if (self.downloadQueue) {
        [self.downloadQueue reset];
        self.downloadQueue = nil;  
    }
}

//获取硬盘剩余空间
long long freeSpaceSize() {
	
    struct statfs buf;
    long long freespace = -1; 
    if (statfs("/var", &buf) >= 0)
        freespace = (long long)buf.f_bsize * buf.f_bfree;

    return freespace;
}

// 检查下载目标任务还差多少可用空间
// 返回值: 0 表示有足够的可用空间
- (UInt64)moreNecessaryFreeSpaceForTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil) {
        return 0;
    }
    
    // 需要的额外可用的空间
    SInt64 extraSize = 0;

    // 磁盘空间检查策略
    UInt64 availableFreeDiskSize = freeSpaceSize(); // 磁盘可用空间
    UInt64 reservedRatio = [downloadTask isMultiSegment] ? 2 : 1; // 下载任务预留空间大小倍率（分段下载  ？ 2 : 1）
    UInt64 taskTotalSize = [downloadTask totalSize]; // 当前任务总大小
    UInt64 taskDownloadedSize = [downloadTask downloadedSize]; // 当前任务已下载大小
    SInt64 availableDiskSize = availableFreeDiskSize - MinReservedDiskSpaceBytes; // 可用于下载的空间
    
    // 未获取下载总大小时仅检查最小预留硬盘空间
    if (downloadTask.totalSize == 0) {
        extraSize = -availableDiskSize;
    } else {
        extraSize = (reservedRatio * taskTotalSize - taskDownloadedSize) - availableDiskSize;
    }
    
    // 有空余空间
    if (extraSize < 0) {
        extraSize = 0;
    }
    
    return extraSize;
}

// 下载文件夹基础路径
+ (NSString *)setupDownloadStoreBasePath:(NSString *)targetForder {
    if (!targetForder) {
        return nil;
    }
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setValue:targetForder forKey:kDownloadBaseForderPathKey];
    [userDefault synchronize];
    return [SHDownloadManager makeDirectoryWithBase:targetForder andSub:DownloadStoreSubPath createIfNotExist:YES];
}

+ (NSString *)downloadStoreBasePath {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *basePath = [userDefault stringForKey:kDownloadBaseForderPathKey];
    if (basePath.length == 0) {
        NSArray *libPathList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        basePath = [libPathList objectAtIndex:0];
        [SHDownloadManager setupDownloadStoreBasePath:basePath];
    }

    return [SHDownloadManager makeDirectoryWithBase:basePath andSub:DownloadStoreSubPath createIfNotExist:NO];
}

// 创建文件夹
+ (NSString *)makeDirectoryWithBase:(NSString*)basePath andSub:(NSString*)subPath createIfNotExist:(BOOL)isCreate {
    if (basePath) {
        basePath = [basePath stringByAppendingPathComponent:subPath];
        BOOL needCreateDirectory = YES;
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:basePath isDirectory:&isDirectory]) {
            if (!isDirectory) {
                [[NSFileManager defaultManager] removeItemAtPath:basePath error:nil];
            } else {
                needCreateDirectory = NO;
            }
        }
        
        if (needCreateDirectory && isCreate) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil])
                basePath = nil;
            if (basePath) {
                NSURL * url = [NSURL fileURLWithPath:basePath isDirectory:YES];
                [url urlShouldSkipBackup:YES];
            }
        }
    }
    
    return basePath;
}

// 计算文件/文件夹大小
+ (UInt64)caculateSizeOfPath:(NSString*)filePath {
    UInt64 totalSize = 0;
    BOOL isDirectory = NO;
    NSFileManager *fileMgr = [NSFileManager defaultManager];

    if (![fileMgr fileExistsAtPath:filePath isDirectory:&isDirectory])
        return 0;
    
    if (isDirectory) {
        NSArray *contents = [fileMgr contentsOfDirectoryAtPath:filePath error:nil];
        NSString *fullPath = nil;
        for (NSString *component in contents) {
            fullPath = [filePath stringByAppendingPathComponent:component];
            
            [fileMgr fileExistsAtPath:fullPath isDirectory:&isDirectory];
            if (isDirectory)
                totalSize += [self caculateSizeOfPath:fullPath];
            else
                totalSize += [[fileMgr attributesOfItemAtPath:fullPath error:nil] fileSize];
        } 
    } else {
        totalSize += [[fileMgr attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    
    return totalSize;
}

// 获取当前下载任务的处理方法
+ (SEL)downloadOperation:(SHDownloadTask *)downloadTask {
    SEL operation = nil;
    
    switch (downloadTask.runningState) {
        case DownloadTaskRunningStateRequestingTaskInfo: {
            if ([downloadTask needRequestURLListForTask])
                operation = @selector(downloadURLListForTask:);
            else 
                operation = @selector(downloadFile:);
            break;
        }
        case DownloadTaskRunningStateDownloading: {
            operation = @selector(downloadFile:);
            break;
        }
        case DownloadTaskRunningStateMerging: {
            operation = @selector(mergeSegmentedTask:);
            break;
        }
        default:
            break;
    }
    
    return operation;
}

// 下载任务已存在
- (SHDownloadTask *)containTask:(SHDownloadTask *)downloadTask {
    SHDownloadTask* existedTask = nil;
    for (SHDownloadTask *task in self.downloadTasks) {
        if ([task isEqualTo:downloadTask]) {
            existedTask = task;
            break;
        }
    }
    
    return existedTask;
}

- (SHDownloadTask *)containTaskByVid:(NSString *)vid {
    SHDownloadTask* existedTask = nil;
    for (SHDownloadTask *task in self.downloadTasks) {
        if ([task.vid isEqualToString:vid]) {
            existedTask = task;
            break;
        }
    }
    
    return existedTask;
}

// 网络状况允许开始下载
- (BOOL)isNetworkAvailableToDownload {
    BOOL isAvailable = NO;
    
    // 网络状态
    NetworkStatus networkStatus = [SHReachability currentReachabilityStatus];//[[ConfigurationCenter sharedCenter] currentReachabilityStatus];
    
    if (networkStatus == ReachableViaWiFi) {
        isAvailable = YES;
    } else if (networkStatus == ReachableViaWWAN) {
        return YES;
    }
    
    return isAvailable;
}

// 暂停并保存当前处于开始和等待状态的列表
- (void)saveAndPauseTasksWithCurrentStateOfRuningAndWaiting {
    return;
    // 已经保存过，跳过
    if (!self.needUpdateRestoreTasks) {
        Log(@"暂停并保存当前处于开始和等待状态的列表--已经保存过，跳过");
        return;
    }
    Log(@"暂停并保存当前处于开始和等待状态的列表--保存");
    self.needUpdateRestoreTasks = NO;

    if (!self.restoreTasks)
        self.restoreTasks = [NSMutableDictionary dictionary];
    
    // 准备处理的任务状态
    SHDownloadTaskState stateOfTasks = SHDownloadTaskStateInvalid;
    // 先暂停当前状态为等待的任务
    {
        stateOfTasks = SHDownloadTaskStateWaiting;

        NSArray *taskNeedProcess = [self getAllDownloadTasksByDownloadState:stateOfTasks];
        if (taskNeedProcess.count > 0) {
            NSString *key = [NSString stringWithFormat:@"%d", stateOfTasks];
            NSMutableArray *array = [self.restoreTasks objectForKey:key];
            if (array == nil) {
                array = [NSMutableArray array];
                [self.restoreTasks setObject:array forKey:key];
            }
            // 记录当前状态为等待的任务
            [array addObjectsFromArray:taskNeedProcess];
            // 暂停当前状态为等待的任务
            for (SHDownloadTask *task in taskNeedProcess) {
                [task pause];
            }
        }
    }
    // 再暂停当前状态为开始的任务
    {
        stateOfTasks = SHDownloadTaskStateRunning;
        
        NSArray *taskNeedProcess = [self getAllDownloadTasksByDownloadState:stateOfTasks];
        if (taskNeedProcess.count > 0) {
            NSString *key = [NSString stringWithFormat:@"%d", stateOfTasks];
            NSMutableArray *array = [self.restoreTasks objectForKey:key];
            if (array == nil) {
                array = [NSMutableArray array];
                [self.restoreTasks setObject:array forKey:key];
            }
            // 记录当前状态为开始的任务
            [array addObjectsFromArray:taskNeedProcess];
            // 暂停当前状态为开始的任务
            for (SHDownloadTask *task in taskNeedProcess) {
                [task pause];
            }
        }
    }
    // 暂停并保存状态为错误但是可以恢复的任务
    {
        stateOfTasks = SHDownloadTaskStateFailed;
        
        NSArray *taskNeedProcess = [self getAllDownloadTasksByDownloadState:stateOfTasks];
        if (taskNeedProcess.count > 0) {
            NSString *key = [NSString stringWithFormat:@"%d", stateOfTasks];
            NSMutableArray *array = [self.restoreTasks objectForKey:key];
            if (array == nil) {
                array = [NSMutableArray array];
                [self.restoreTasks setObject:array forKey:key];
            }
            // 记录当前状态为错误但是可以恢复的任务
            [array addObjectsFromArray:taskNeedProcess];
            for (int i = 0; i < taskNeedProcess.count; ++i) {
                SHDownloadTask *task = [array objectOrNilAtIndex:i];
                // 暂停当前状态为错误但是可以恢复的任务
                if ([task canBeRetried]) {
                    [task pause];
                } else {
                    [array removeObject:task];
                }
            }
        }
    }
    
    SEL selector = @selector(downloadManager:didUpdateStatusOfDownloadTasks:);
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:self withObject:self.downloadTasks];
    }
}

// 恢复记录中处于开始和等待状态的列表
- (void)restoreTasksWithRecordedStateOfRuningAndWaiting {
    // 未保存过，跳过
    if (self.restoreTasks == nil) {
        Log(@"恢复记录中处于开始和等待状态的列表--未保存过，跳过");
        return;
    }
    Log(@"恢复记录中处于开始和等待状态的列表--恢复");
    self.needUpdateRestoreTasks = NO;
    
    // 优先恢复需要合并的任务
    [self mergeAllAvailableTasks];
    
    // 如果没有可恢复任务，尝试恢复可重试的任务
    if (self.restoreTasks.count == 0) {
        [self cleanupRestoreLists];
        [self retryTasks];
    } else {
        // 准备处理的任务状态
        SHDownloadTaskState stateOfTasks = SHDownloadTaskStateInvalid;
        // 先恢复记录状态为等待的任务
        {
            stateOfTasks = SHDownloadTaskStateWaiting;
            NSString *key = [NSString stringWithFormat:@"%d", stateOfTasks];
            // 获取记录状态为等待的任务
            NSArray *array = [self.restoreTasks objectForKey:key];
            [array retain];
            // 恢复记录状态为等待的任务
            for (SHDownloadTask *task in array) {
                Log(@"准备恢复的任务《%@》当前状态为：%d", task.videoTitle, task.downloadState);
                // 只恢复状态为暂停的任务
                if (task.downloadState == SHDownloadTaskStatePaused) {
                    task.downloadState = SHDownloadTaskStateWaiting;
                }
            }
            
            SEL selector = @selector(downloadManager:didUpdateStatusOfDownloadTasks:);
            if (self.delegate && [self.delegate respondsToSelector:selector])
                [self.delegate performSelector:selector withObject:self withObject:array];
            [array release];
        }
        // 恢复保存状态为错误但是可以恢复的任务
        {
            stateOfTasks = SHDownloadTaskStateFailed;
            NSString *key = [NSString stringWithFormat:@"%d", stateOfTasks];
            // 获取记录状态为错误但是可以恢复的任务
            NSArray *array = [self.restoreTasks objectForKey:key];
            [array retain];
            // 恢复记录状态为错误但是可以恢复的任务
            for (SHDownloadTask *task in array) {
                // 只恢复状态为暂停的任务
                if (task.downloadState == SHDownloadTaskStatePaused) {
                    task.downloadState = SHDownloadTaskStateFailed;
                }
            }
            
            SEL selector = @selector(downloadManager:didUpdateStatusOfDownloadTasks:);
            if (self.delegate && [self.delegate respondsToSelector:selector])
                [self.delegate performSelector:selector withObject:self withObject:array];
            [array release];
        }
        // 再恢复记录状态为开始的任务
        {
            stateOfTasks = SHDownloadTaskStateRunning;
            NSString *key = [NSString stringWithFormat:@"%d", stateOfTasks];
            // 获取记录状态为开始的任务
            NSArray *array = [self.restoreTasks objectForKey:key];
            [array retain];
            // 恢复记录状态为开始的任务
            for (SHDownloadTask *task in array) {
                // 只恢复状态为暂停的任务
                if (task.downloadState == SHDownloadTaskStatePaused) {
                    [self tryStartTask:task];
                }
            }
            [array release];
        }
        
        // 恢复完毕，清空保存列表
        [self cleanupRestoreLists];
        
        // 如果记录中无正在下载的任务或被删除，确保有等待任务可以继续进行
        [self downloadNextTask];
    }
}

// 清空恢复列表
- (void)cleanupRestoreLists {
    self.needUpdateRestoreTasks = YES;
    self.restoreTasks = nil;
}

// 当前所有下载任务占用磁盘空间大小
- (UInt64)totalSizeOfAllTasks {
    UInt64 totalSize = 0;
    
    // 非互斥
    for (SHDownloadTask *task in self.downloadTasks) {
        totalSize += task.downloadedSize;
    }
    
    return totalSize;
}

// 更新优先下载队列
- (NSMutableArray*)updatePriorTasks {
    // 非合集不开启优先下载队列
    if (self.organizedForm != SHDownloadTaskOrganizedFormAlbum) {
        if (self.priorTasks) {
            self.priorTasks = nil;
        }
        return nil;
    }
    
    BOOL needRebuildPriorTasks = YES;
    
    NSArray *waitingList = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateWaiting];
    NSArray *runningList = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateRunning];

    // 下载队列为空且当期队列非空，则更新队列
    if ((runningList == nil || runningList.count == 0) &&
        (self.priorTasks && self.priorTasks.count != 0)) {
        // 当前等待队列非空
        if (waitingList && waitingList.count != 0) {
            // 更新队列
            SHDownloadTask *anyPriorTask = [self.priorTasks objectOrNilAtIndex:0];
            for (SHDownloadTask *task in waitingList) {
                if (![self.priorTasks containsObject:task] && [task doesBelongToSameAlbum:anyPriorTask])
                    [self.priorTasks addObjectOrNil:task];
            }
            // 当前队列中有等待任务则不需要重建队列
            for (SHDownloadTask *task in self.priorTasks) {
                if ([waitingList containsObject:task]) {
                    needRebuildPriorTasks = NO;
                    break;
                }
            }
        }
    }
    
    // 需要重建当前队列
    if (needRebuildPriorTasks) {
        if (self.priorTasks == nil)
            self.priorTasks = [NSMutableArray array];

        // 清空队列
        [self.priorTasks removeAllObjects];

        // 尝试用正在运行的任务生成新的队列
        if (runningList && runningList.count != 0)
            [self.priorTasks addObject:[runningList objectOrNilAtIndex:0]];
    }

    // 按照播放顺序进行排序
    NSString *sortKey = @"videoPlayOrder"; // 保存视频播放顺序的变量名
    NSMutableArray *sortedTasks = [[self.priorTasks sortArrayByKey:sortKey inAscending:YES] mutableCopy];
    self.priorTasks = sortedTasks;
    [sortedTasks release];
    
    return self.priorTasks;
}

// 是否还有下载任务
- (BOOL)isThereAnyBusiness {
    BOOL isThereAnyBusiness = NO;
    for (SHDownloadTask *task in self.downloadTasks) {
        if ((task.downloadState == SHDownloadTaskStateWaiting) || // 有任务在等待开始
            (task.downloadState == SHDownloadTaskStateRunning) || // 有任务正在运行
            (task.downloadState == SHDownloadTaskStateFailed && [task canBeRetried])) { // 有需要重试的任务
            isThereAnyBusiness = YES;
        }
    }

    return isThereAnyBusiness;
}

// 合并所有需要合并的任务
- (void)mergeAllAvailableTasks {
    for (SHDownloadTask *task in self.downloadTasks) {
        if (task.runningState == DownloadTaskRunningStateMerging &&
            task.errorCode != SHDownloadTaskErrorFileBroken &&
            task.downloadState != SHDownloadTaskStateCompleted &&
            task.downloadState != SHDownloadTaskStateMerging) {
            [self mergeSegmentedTask:task];
        }
    }
}

// 插入可恢复队列
- (void)addRestoreTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil) {
        return;
    }
    
    NSString *key = [NSString stringWithFormat:@"%d", SHDownloadTaskStateWaiting];
    NSMutableArray *array = nil;

    if (!self.restoreTasks) {
        self.restoreTasks = [NSMutableDictionary dictionary];
        array = [NSMutableArray array];
        [self.restoreTasks setObjectOrNil:array forKey:key];
    } else {
        array = [self.restoreTasks objectForKey:key];
    }
    
    self.needUpdateRestoreTasks = YES;
    [array addObjectOrNil:downloadTask];
}

// 发送状态变化回调
- (void)postDownloadTaskStatusDidUpdated:(SHDownloadTask *)task {
    if (task == nil) {
        return;
    }
    
    SEL selector = @selector(downloadManager:didUpdateStatusOfDownloadTask:);
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:self withObject:task];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DownloadTaskStatusDidUpdatedNotification object:nil userInfo:@{DownloadTaskNotificationKey: task}];
}

// 判断支持的并行下载文件个数
- (NSInteger)maxMultiTasks {
    if (self.allowMultiTask) {
        if (self.maxTaskNumber > MaxCocurrentTaskNum) {
            return MaxCocurrentTaskNum;
        }
        return self.maxTaskNumber;
    } else {
        return DefaultCocurrentTaskNum;
    }
}

#pragma mark - 管理下载任务
//添加一个新的
- (SHDownloadTaskCreationErrorCode)addDownloadTask:(SHDownloadTask *)downloadTask {
    SHDownloadTaskCreationErrorCode code = SHDownloadTaskCreationNoError;
    BOOL canTaskStart = YES;
    
    // 1. 任务已存在
    if ([self containTask:downloadTask]) {
        code = SHDownloadTaskCreationErrorAlreadyExist;
        canTaskStart = NO;
    }
    
    // 2. 离线缓存任务的上限由目前的200个，调整至10000个
    if (code == SHDownloadTaskCreationNoError) {
        if (self.downloadTasks.count >= MaxDownloadTaskNum) {
            code = SHDownloadTaskCreationErrorTaskCountLimited;
            canTaskStart = NO;
        }
    }
    
    // 3. 网络不符合下载需求时，任务置为暂停
    if (code == SHDownloadTaskCreationNoError) {
        if (![self isNetworkAvailableToDownload]) {
            downloadTask.downloadState = SHDownloadTaskStatePaused;
            canTaskStart = NO;
            // 3G不允许添加任务时返回错误
            if ([SHReachability currentReachabilityStatus] == ReachableViaWWAN)
                code = SHDownloadTaskCreationErrorNetworkUnavailable;
        }
    }
    
    // 4. 磁盘空间不足，新添加任务不需要做处理，设置状态为暂停
    if (code == SHDownloadTaskCreationNoError) {
        if ([self moreNecessaryFreeSpaceForTask:downloadTask] != 0) {
            downloadTask.downloadState = SHDownloadTaskStatePaused;
            canTaskStart = NO;
        }
    }
    
    // 5. 无任何错误,添加到下载任务列表中
    if (code == SHDownloadTaskCreationNoError) {
        // 设置创建时间
        downloadTask.createdTime = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        [self.downloadTasks addObjectOrNil:downloadTask];
        
        //存盘
        [self saveDownloadTasks];

        // 更新恢复列表
        [self addRestoreTask:downloadTask];
        
        SEL selector = @selector(downloadManager:didAddOneNewDownloadTask:);
        if (self.delegate && [self.delegate respondsToSelector:selector])
            [self.delegate performSelector:selector withObject:self withObject:downloadTask];
    }
    
    // 6. 开始下载任务
    if (code == SHDownloadTaskCreationNoError && canTaskStart) {
        [self tryStartTask:downloadTask];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DownloadTaskQueueUpdatedNotification object:nil];

    return code;
}

// 添加多个有效的任务
- (void)addDownloadTasks:(NSArray *)tasks {
    if (tasks == nil || ![tasks isKindOfClass:[NSArray class]] || tasks.count == 0)
        return;
    
    for (SHDownloadTask *task in tasks) {
        // 重置创建时间
        task.createdTime = [NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate]];
        [self.downloadTasks addObjectOrNil:task];
    }
    
    //存盘
    [self saveDownloadTasks];
    
    SEL selector = @selector(downloadManager:didUpdateStatusOfDownloadTasks:);
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:self withObject:tasks];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DownloadTaskQueueUpdatedNotification object:nil];
}

// 添加多个有效任务到下载队列
- (SHDownloadTaskCreationErrorCode)addNewDownloadTasks:(NSArray *)tasks {
    SHDownloadTaskCreationErrorCode code = SHDownloadTaskCreationNoError;
    
    if (tasks == nil || ![tasks isKindOfClass:[NSArray class]] || tasks.count == 0) {
        return code;
    }
    
    NSMutableArray *validTasks = [[NSMutableArray alloc] init];
    
    BOOL canTaskStart = NO;
    for (SHDownloadTask *downloadTask in tasks) {
        code = SHDownloadTaskCreationNoError;
        
        // 1. 任务已存在
        if ([self containTask:downloadTask]) {
            code = SHDownloadTaskCreationErrorAlreadyExist;
            continue;
        }
        
        // 2. 离线缓存任务的上限由目前的200个，调整至10000个
        if (code == SHDownloadTaskCreationNoError) {
            if (self.downloadTasks.count >= MaxDownloadTaskNum) {
                code = SHDownloadTaskCreationErrorTaskCountLimited;
                break;
            }
        }

        // 3. 网络不符合下载需求时，任务置为暂停
        if (code == SHDownloadTaskCreationNoError) {
            if (![self isNetworkAvailableToDownload]) {
                downloadTask.downloadState = SHDownloadTaskStatePaused;
                // 3G不允许添加任务时返回错误
                if ([SHReachability currentReachabilityStatus] == ReachableViaWWAN) {
                    code = SHDownloadTaskCreationErrorNetworkUnavailable;
                    break;
                }
            } else {
                downloadTask.downloadState = SHDownloadTaskStateWaiting;
            }
        }
        
        // 4. 无任何错误,添加到下载任务列表中
        if (code == SHDownloadTaskCreationNoError) {
            [validTasks addObjectOrNil:downloadTask];
            // 更新恢复列表
            [self addRestoreTask:downloadTask];
            canTaskStart = YES; // 存在可以下载的任务
        }
    }
    
    if (canTaskStart) {
        // 新增下载任务
        [self addDownloadTasks:validTasks];
        [self downloadNextTask];
    }
    
    [validTasks release];
    
    return code;
}

- (void)removeDownloadTaskByVid:(NSString *)vid removeVideoFile:(BOOL)removeFile {
    if (nil == vid || vid.length == 0) {
        return;
    }
    
    SHDownloadTask *tobeDeletedTask = [self containTaskByVid:vid];
    if (tobeDeletedTask) {
        // 删除已下载文件
        if (removeFile) {
            [tobeDeletedTask eraseDownloadedData];
        }
        // 从下载列表中移除
        [self.downloadTasks removeObject:tobeDeletedTask];
    }
    
    // 存盘
    [self saveDownloadTasks];
    
    SEL selector = @selector(downloadManagerDidRemoveDownloadTasks);
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DownloadTaskQueueUpdatedNotification object:nil];
    
    // 继续下一个
    [self downloadNextTask];
}

//删除
- (void)removeDownloadTasks:(NSArray *)downloadTaskList removeVideoFile:(BOOL)removeFile {
    if (downloadTaskList == nil || downloadTaskList.count == 0) {
        return;
    }
    
    for (SHDownloadTask *task in downloadTaskList) {
        SHDownloadTask *tobeDeletedTask = [self containTask:task];
        if (tobeDeletedTask) {
            // 删除已下载文件
            if (removeFile) {
                [tobeDeletedTask eraseDownloadedData];
            }
            // 从下载列表中移除
            [self.downloadTasks removeObject:tobeDeletedTask];
        }
    }

    // 存盘
    [self saveDownloadTasks];
    
    SEL selector = @selector(downloadManagerDidRemoveDownloadTasks);
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DownloadTaskQueueUpdatedNotification object:nil];
    
    // 继续下一个
    [self downloadNextTask];
}

//保存
- (void)saveDownloadTasks {
    [SHDownloadDataManager saveDownloadTasksInfo:self.downloadTasks];
}

#pragma mark - 调度下载任务
// 启动 - UI或下载模块之外会调用的接口
- (void)startDownloadTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil || downloadTask.downloadState == SHDownloadTaskStateCompleted) {
        return;
    }

    // 下载任务不可恢复
    if (![downloadTask canBeRecovered]) {
        [self handleError:downloadTask];
    } else { // 因为外界控制，开始任务则清理恢复列表
        [self cleanupRestoreLists];
        // 尝试开始下载任务
        [self tryStartTask:downloadTask];
    }
}

- (void)startAllDownloadTasks {
    if ([self isNetworkAvailableToDownload]) {
        // 因为外界控制，开始任务则清理恢复列表
        [self cleanupRestoreLists];

        [self doStartAllDownloadTasks];
    }
}

// 启动所有下载任务-内部使用
- (void)doStartAllDownloadTasks {
    for (SHDownloadTask *task in self.downloadTasks) {
        switch (task.downloadState) {
            case SHDownloadTaskStatePaused:
                task.downloadState = SHDownloadTaskStateWaiting;
                break;
            case SHDownloadTaskStateFailed:
                if ([task canBeRecovered])
                    task.downloadState = SHDownloadTaskStateWaiting;
                break;
            default:
                break;
        }
    }
    
    SEL selector = @selector(downloadManager:didUpdateStatusOfDownloadTasks:);
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:self withObject:self.downloadTasks];
    }
    
    [self downloadNextTask];
}

//暂停
- (void)pauseDownloadTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil ||
        downloadTask.downloadState == SHDownloadTaskStatePaused ||
        downloadTask.downloadState == SHDownloadTaskStateFailed ||
        downloadTask.downloadState == SHDownloadTaskStateMerging ||
        downloadTask.downloadState == SHDownloadTaskStateCompleted) {
        return;
    }
    
    // 因为外界控制，开始任务则清理恢复列表
    [self cleanupRestoreLists];
    
    [self doPauseDownloadTask:downloadTask];
}

// 暂停下载任务-内部使用
- (void)doPauseDownloadTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil ||
        downloadTask.downloadState == SHDownloadTaskStatePaused ||
        downloadTask.downloadState == SHDownloadTaskStateFailed ||
        downloadTask.downloadState == SHDownloadTaskStateMerging ||
        downloadTask.downloadState == SHDownloadTaskStateCompleted) {
        return;
    }

    [downloadTask pause];
    
    [self postDownloadTaskStatusDidUpdated:downloadTask];

    // 继续下一个
    [self downloadNextTask];
}

- (void)pauseAllDownloadTasks {
    // 因为外界控制，开始任务则清理恢复列表
    [self cleanupRestoreLists];
    
    [self doPauseAllDownloadTasks];
    
    [self saveDownloadTasks];
}

// 暂停所有下载任务-内部使用
- (void)doPauseAllDownloadTasks {
    for (SHDownloadTask *task in self.downloadTasks) {
        switch (task.downloadState) {
            case SHDownloadTaskStateRunning:
            case SHDownloadTaskStateWaiting: {
                [task pause];
            }
                break;
            default:
                break;
        }
    }

    SEL selector = @selector(downloadManager:didUpdateStatusOfDownloadTasks:);
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        [self.delegate performSelector:selector withObject:self withObject:self.downloadTasks];
    }
}

#pragma mark - 下载主逻辑
// 错误处理
- (void)handleError:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil) {
        return;
    }
    // 尝试重试任务
    if ([downloadTask canBeRetried] && [SHReachability currentReachabilityStatus] != kNotReachable) {
        int i = [SHReachability currentReachabilityStatus];
        NSLog(@"i %d", i);
        [self.failedRetryTimer invalidate];
        self.failedRetryTimer = nil;
        self.failedRetryTimer = [NSTimer scheduledTimerWithTimeInterval:FailedRetryIntervalSeconds target:self selector:@selector(timerFireMethod:) userInfo:downloadTask repeats:NO];
        return;
    } 
    
    // 清除已有连接
    [downloadTask cancel];
    // 设置任务状态
    downloadTask.downloadState = SHDownloadTaskStateFailed;
    // 重置重置状态
    [downloadTask resetRetryState];
    // 发送委托消息
    [self postDownloadTaskStatusDidUpdated:downloadTask];
    
    [downloadTask stopCalculatingSpeed];

    //存盘
    [self saveDownloadTasks];

    BOOL toBeContinue = YES;
    SHDownloadTaskErrorCode error = downloadTask.errorCode;
    switch (error) {
        case SHDownloadTaskErrorUnknown: // 未知错误
            break;
        case SHDownloadTaskErrorNetworkUnstable: // 网络不稳定
            [self addDownloadTastErrorLog:downloadTask errorString:@"SHDownloadTaskErrorNetworkUnstable-00"];
            break;
        case SHDownloadTaskErrorMergeInterrupted: // 分段合并中断
            break;
        case SHDownloadTaskErrorFileBroken: // 下载文件损坏
            [self addDownloadTastErrorLog:downloadTask errorString:@"SHDownloadTaskErrorFileBroken-00"];
            break;
        case SHDownloadTaskErrorURLInvalid: // 下载地址无效
            break;
        case SHDownloadTaskNoError: // 无错误
        default:
            //什么都不做
            break;
    }
    
    // 继续下载队列中任务
    if (toBeContinue && ![SHReachability currentReachabilityStatus]) {
        [self downloadNextTask];
    }
    
    [SHDownloadDataManager saveDownloadTasksLog:self.logArray];
}

// 尝试开始下载任务
- (BOOL)tryStartTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil || downloadTask.downloadState == SHDownloadTaskStateCompleted) {
        return NO;
    }
    
    BOOL canTaskBeLaunched = YES;
    
    // 网络状况检查
    if (![self isNetworkAvailableToDownload]) {
        // 放过需要合并的任务
        if (downloadTask.runningState != DownloadTaskRunningStateMerging) {
            downloadTask.errorCode = SHDownloadTaskErrorNoNetwork;
            // 非WiFi网络
            if ([SHReachability currentReachabilityStatus] == ReachableViaWWAN)
                downloadTask.errorCode = SHDownloadTaskErrorDeniedNonWiFi;
            [self handleError:downloadTask];
            canTaskBeLaunched = NO;
        }
    }

    if (canTaskBeLaunched) {
        SHDownloadTaskState state = downloadTask.downloadState;

        // 下载列表
        NSMutableArray *runningList = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateRunning];
        // 非暂停状态，下载队列已满，则设置第一个当前正在下载任务为等待状态，允许开始新的任务
        // 非暂停状态，下载队列不满，则允许开始新的任务
        // 暂停状态，下载队列已满，则将目标任务置为等待状态，不允许开始新的任务
        // 暂停状态，下载队列不满，则允许开始新的任务
        switch (downloadTask.downloadState) {
            case SHDownloadTaskStateRunning: {
                canTaskBeLaunched = NO;
                break;
            }
            case SHDownloadTaskStatePaused: {
                // 暂停状态，下载队列已满，则将目标任务置为等待状态，不允许开始新的任务
                if (runningList.count >= self.maxMultiTasks) {
                    downloadTask.downloadState = SHDownloadTaskStateWaiting;
                    canTaskBeLaunched = NO;
                }
                break;
            }
            default: {
                // 非暂停状态，下载队列已满，则设置第一个当前正在下载任务为等待状态，允许开始新的任务
                if (runningList.count >= self.maxMultiTasks) {
                    SHDownloadTask *task = [runningList objectOrNilAtIndex:0];
                    [task pause];
                    task.downloadState = SHDownloadTaskStateWaiting;
                    
                    [self postDownloadTaskStatusDidUpdated:task];
                }
                break;
            }
        }
        
        if (!canTaskBeLaunched) { // 任务未开始
            if (downloadTask.downloadState != state) { // 任务状态发生变化
                [self postDownloadTaskStatusDidUpdated:downloadTask];
            }
        }
    }
    
    // 开始下载任务
    if (canTaskBeLaunched) {
        [self doStartTask:downloadTask];
    }
    
    return canTaskBeLaunched;
}

// 重试下载任务
- (void)retryTask:(SHDownloadTask *)downloadTask {
    Log(@"重试下载任务");
    if (downloadTask == nil || downloadTask.downloadState != SHDownloadTaskStateRunning) {
        return;
    }
    
    SEL operation = [SHDownloadManager downloadOperation:downloadTask];
    [downloadTask retry:operation onObject:self];
}

// 重试下载任务列表
- (void)retryTasks {
    Log(@"重试下载任务列表");
    BOOL flag = NO;
    for (SHDownloadTask *task in self.downloadTasks) {
        if (task.downloadState == SHDownloadTaskStateFailed && [task canBeRetried]) {
            task.downloadState = SHDownloadTaskStateWaiting;
            flag = YES;
        }
    }
    if (flag) {
        [self downloadNextTask];
    }
}

// 开始下载任务
- (void)doStartTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil) {
        return;
    }

    SEL operation = [SHDownloadManager downloadOperation:downloadTask];
    
    if (operation && [self respondsToSelector:operation]) {
        [downloadTask resetRetryState];
        
        // 开始任务前重置错误状态
        downloadTask.errorCode = SHDownloadTaskNoError;

        // 设置状态
        downloadTask.downloadState = SHDownloadTaskStateRunning;
        
        // 更新优先下载队列
        [self updatePriorTasks];

        [self postDownloadTaskStatusDidUpdated:downloadTask];

        [self performSelector:operation withObject:downloadTask];
        
        [downloadTask fireCalculatingSpeed];
    }
}

// 下载列表
- (void)downloadURLListForTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil || downloadTask.downloadState != SHDownloadTaskStateRunning) {
        [downloadTask cancel];
        return;
    }
    
    //设定状态
    downloadTask.runningState = DownloadTaskRunningStateRequestingTaskInfo;
    
    // 清除已有连接
    [downloadTask cancel];

    downloadTask.httpRequest = [ASIHTTPRequest requestWithURL:[downloadTask downloadURL]];
    Log(@"准备请求分段列表:%@", downloadTask.httpRequest.url);
    [downloadTask.httpRequest addRequestHeader:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112 Safari/534.30"];
    downloadTask.httpRequest.cachePolicy = ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy; //禁用缓存
    downloadTask.httpRequest.userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:downloadTask, HTTPRequestDownloadTaskKey, nil];
    downloadTask.httpRequest.delegate = self;
    downloadTask.httpRequest.didFinishSelector = @selector(downloadTaskURLListDidFinished:);
    downloadTask.httpRequest.didFailSelector =@selector(downloadTaskURLListDidFailed:);

    [self.downloadQueue addOperation:downloadTask.httpRequest];
}

// 下载文件
- (void)downloadFile:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil || downloadTask.downloadState != SHDownloadTaskStateRunning) {
        [downloadTask cancel];
        return;
    }
    
    //设定状态
    downloadTask.runningState = DownloadTaskRunningStateDownloading;
    
    //存盘
    [self saveDownloadTasks];

    // 清除已有连接
    [downloadTask cancel];
    
    NSString * oriUrl = [[downloadTask downloadURL] absoluteString];
    NSString * finalUrl = oriUrl;
 
    downloadTask.httpRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:finalUrl]];
    Log(@"准备下载:%@", downloadTask.httpRequest.url);
    [downloadTask.httpRequest addRequestHeader:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.112 Safari/534.30 AppleCoreMedia/1.0.0.9B176"];
    downloadTask.httpRequest.allowResumeForFileDownloads = YES; //断点续传
    downloadTask.httpRequest.cachePolicy = ASIDoNotReadFromCacheCachePolicy|ASIDoNotWriteToCacheCachePolicy; //禁用缓存
    downloadTask.httpRequest.shouldAttemptPersistentConnection = YES;//禁止连接复用
    downloadTask.httpRequest.shouldContinueWhenAppEntersBackground = NO;//禁止后台下载
    downloadTask.httpRequest.timeOutSeconds = NetWorkTimeoutSeconds; // 超时出错
//    downloadTask.httpRequest.shouldPlusRangeInRequestHeader = YES;
    downloadTask.httpRequest.userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:downloadTask, HTTPRequestDownloadTaskKey, nil];
    
    // 创建文件存放地址
    [SHDownloadManager makeDirectoryWithBase:downloadTask.downloadStoreBasePath andSub:[[downloadTask relativeDownloadPath] stringByDeletingLastPathComponent] createIfNotExist:YES];
    downloadTask.httpRequest.downloadDestinationPath = [downloadTask.downloadStoreBasePath stringByAppendingPathComponent:[downloadTask relativeDownloadPath]];//存放位置
    Log(@"下载[%@]最终文件名:%@", downloadTask.videoTitle,  downloadTask.httpRequest.downloadDestinationPath);
    
    // 创建缓存文件存放地址
    [SHDownloadManager makeDirectoryWithBase:downloadTask.downloadStoreBasePath andSub:[[downloadTask relativeSavePathVideoCache] stringByDeletingLastPathComponent] createIfNotExist:YES];
    downloadTask.httpRequest.temporaryFileDownloadPath = [downloadTask.downloadStoreBasePath stringByAppendingPathComponent:[downloadTask relativeSavePathVideoCache]]; //临时存放位置
    Log(@"下载[%@]缓存文件名:%@", downloadTask.videoTitle,  downloadTask.httpRequest.temporaryFileDownloadPath);
    downloadTask.httpRequest.downloadProgressDelegate = self;
    downloadTask.httpRequest.delegate = self;
    downloadTask.httpRequest.didFinishSelector = @selector(downloadFileDidFinished:);
    downloadTask.httpRequest.didFailSelector =@selector(downloadFileDidFailed:);

    [self.downloadQueue addOperation:downloadTask.httpRequest];
}

// 继续下一个下载任务
- (void)downloadNextTask {
    Log(@"开始下一个任务");
    // 下载队列已满则跳过
    NSArray *runningQueue = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateRunning];
    if (runningQueue && runningQueue.count >= self.maxMultiTasks) {
        return;
    }

    NSArray *waitingQueue = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateWaiting];
    if (waitingQueue && waitingQueue.count != 0) {
        SHDownloadTask *taskToStart = nil;
        // 更新优先下载队列
        [self updatePriorTasks];
        for (SHDownloadTask *task in self.priorTasks) {
            if (task.downloadState == SHDownloadTaskStateWaiting) {
                taskToStart = task;
                break;
            }
        }
        // 优先队列为空
        if (taskToStart == nil)
            taskToStart = [waitingQueue objectOrNilAtIndex:0];
        [self tryStartTask:taskToStart];
        
        // 尝试多任务下载
        [self downloadNextTask];
    } else {
        // 是否没有可以重试的任务
        if (![self isThereAnyBusiness]) {
            Log(@"下载队列为空，进入空闲状态");
            // 放弃锁屏干预
//            [[AppStateManager sharedInstance] pausePreventSuspending];
//            // 恢复锁屏干预
//            [[AppStateManager sharedInstance] resumeAutolock];
        } else {
            Log(@"下载队列为空，进入重试状态");
            // 保证下载任务不会因为网络不稳定而停止
            [self.taskListRetryTimer invalidate];
            self.taskListRetryTimer = nil;
            self.taskListRetryTimer = [NSTimer scheduledTimerWithTimeInterval:TaskListRetryIntervalSeconds target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
        }
    }
}

// 合并分段
- (void)mergeSegmentedTask:(SHDownloadTask *)downloadTask {
    if (downloadTask == nil || downloadTask.downloadState != SHDownloadTaskStateRunning) {
        [downloadTask cancel];
        return;
    }

    // 非分段视频不需要合并
    if (![downloadTask isMultiSegment]) {
        return;
    }
    
    Log(@"准备开始合并：%@", downloadTask.videoTitle);
    
    // 设定状态
    downloadTask.runningState = DownloadTaskRunningStateMerging;
    downloadTask.downloadState = SHDownloadTaskStateMerging;
    
    //存盘
    [self saveDownloadTasks];

    // 合并
    MP4Box *mp4Box = [[[MP4Box alloc] initWithVideoStatus:nil] autorelease];
    mp4Box.userInfo = downloadTask;
    
    NSString *downloadFolder = [SHDownloadManager makeDirectoryWithBase:downloadTask.downloadStoreBasePath andSub:[[downloadTask relativeDownloadPath] stringByDeletingLastPathComponent] createIfNotExist:NO];
    NSString *exportFilePath = [downloadTask.downloadStoreBasePath stringByAppendingPathComponent:[downloadTask relativeSavePathVideoFile]];
    NSAssert([exportFilePath length] > 0, @"The export file path is nil!");
    if (exportFilePath != nil && [exportFilePath length] != 0) {
        if (![mp4Box mergeVideoWithFilePathArray:downloadFolder andExportFilePath:exportFilePath isDeleteDownLoadFile:NO]) {
            Log(@"尝试合并《%@》出错", downloadTask.videoTitle);
            downloadTask.errorCode = SHDownloadTaskErrorFileBroken;
            [self addDownloadTastErrorLog:downloadTask errorString:@"SHDownloadTaskErrorFileBroken-33"];
            [self handleError:downloadTask];
        } else {
            [self postDownloadTaskStatusDidUpdated:downloadTask];
        }
    }
}

// 下载文件成功处理
- (void)downloadFileDidFinished:(ASIHTTPRequest *)request {
    // 返回数据检查
    BOOL isDataValid = YES;
    if (request == nil || request.userInfo == nil || ![request.userInfo isKindOfClass:[NSDictionary class]]) {
        isDataValid = NO;
    }
    
    SHDownloadTask *task = nil;
    if (isDataValid) {
        task = [request.userInfo objectForKey:HTTPRequestDownloadTaskKey];
        if (task == nil || ![task isKindOfClass:[SHDownloadTask class]]) {
            isDataValid = NO;
        }
    }
    // 无效数据无法处理
    NSAssert(isDataValid, @"%@:无效数据无法处理!", NSStringFromSelector(_cmd));
    
    // 校验当前下载任务完成状态
    UInt64 downloadedFileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:request.downloadDestinationPath error:nil].fileSize;
    if (downloadedFileSize < task.expectedTotalSize) {
        task.errorCode = SHDownloadTaskErrorNetworkUnstable;
        [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorNetworkUnstable-11"];
        [self handleError:task];
        return;
    }

    // 所有分段已下完
    if (task.currentSegmentIndex + 1 >= task.downloadURLs.count) {
        if (![task isMultiSegment]) {
            task.downloadState = SHDownloadTaskStateCompleted;
            //存盘
            [self saveDownloadTasks];
            
            [self postDownloadTaskStatusDidUpdated:task];
            
            [task stopCalculatingSpeed];
            [self finishOneDownloadTask:task];
        } else {
            // 检查已下载数据有效性
            if (![task isDownloadedDataIntact]) {
                task.errorCode = SHDownloadTaskErrorFileBroken;
                [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorFileBroken-44"];
                [self handleError:task];
            } else {
                [self mergeSegmentedTask:task];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DownloadTaskQueueUpdatedNotification object:nil];

        // 继续下一个任务
        [self downloadNextTask];
    } else {
        task.currentSegmentIndex++;
        // 重置重试次数
        [task resetRetryState];
        //存盘
        [self saveDownloadTasks];
        // 检查已下载数据有效性
        if (![task isDownloadedDataIntact]) {
            [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorFileBroken-55"];
            task.errorCode = SHDownloadTaskErrorFileBroken;
            [self handleError:task];
        } else {
            [self downloadFile:task];
        }
    }
}

// 下载文件失败处理
- (void)downloadFileDidFailed:(ASIHTTPRequest *)request {
    // 返回数据检查
    BOOL isDataValid = YES;
    if (request == nil || request.userInfo == nil || ![request.userInfo isKindOfClass:[NSDictionary class]]) {
        isDataValid = NO;
    }

    SHDownloadTask *task = nil;
    if (isDataValid) {
        task = [request.userInfo objectForKey:HTTPRequestDownloadTaskKey];
        if (task == nil || ![task isKindOfClass:[SHDownloadTask class]])
            isDataValid = NO;
    }
 
    // 无效数据无法处理
    NSAssert(isDataValid, @"%@:无效数据无法处理!", NSStringFromSelector(_cmd));
    
    Log(@"RequestFailed:%@|HTTPState:%d|Des:%@", request.url, request.responseStatusCode, [request.error description]); // request.error.debugDescription

    // 先统一设置为网络错误
    task.errorCode = SHDownloadTaskErrorNetworkUnstable;
    [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorNetworkUnstable-22"];
    [self handleError:task];
}

// 分段任务下载列表成功处理
- (void)downloadTaskURLListDidFinished:(ASIHTTPRequest*)request {
    // 返回数据检查
    BOOL isDataValid = YES;
    if (request == nil || request.userInfo == nil || ![request.userInfo isKindOfClass:[NSDictionary class]]) {
        isDataValid = NO;
    }
    
    SHDownloadTask *task = nil;
    if (isDataValid) {
        task = [request.userInfo objectForKey:HTTPRequestDownloadTaskKey];
        if (task == nil || ![task isKindOfClass:[SHDownloadTask class]]) {
            isDataValid = NO;
        }
    }
    
    // 无效数据无法处理
    NSAssert(isDataValid, @"%@:无效数据无法处理!", NSStringFromSelector(_cmd));

    // 具体信息检查
    NSString *jsonString = nil;
    if (request == nil || nil == (jsonString = [request responseString])) {
        isDataValid = NO;
    }
    
    // 无效数据无法处理
    if (!isDataValid) {
        task.errorCode = SHDownloadTaskErrorNetworkUnstable;
        [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorNetworkUnstable-33"];
        [self handleError:task];
        return;
    }
    
    BOOL isDataCorrect = YES;
    NSDictionary *resultDict = nil;
    resultDict = [jsonString objectFromJSONString];
    if (resultDict == nil || ![resultDict isKindOfClass:[NSDictionary class]]) {
        isDataCorrect = NO;
    }
    
    if (isDataCorrect) {
        NSInteger requestStatusCode = [[resultDict objectForKey:@"status"] intValue];
        if (requestStatusCode != 200) {
            isDataCorrect = NO;
        }
    }
    
    NSDictionary *dataDict = nil;
    if (isDataCorrect) {
        dataDict = [resultDict objectForKey:@"data"];
        if (dataDict == nil || ![dataDict isKindOfClass:[NSDictionary class]] || dataDict.count == 0) {
            isDataCorrect = NO;
        }
    }
    
    BOOL isVideoStillValid = YES;
    // 根据status来判断当前视频是否有效，1为有效，0为无效
    if (isDataCorrect) {
        NSInteger status = [dataDict integerForKey:@"status" defaultValue:1];
        if (status != 1) {
            isVideoStillValid = NO;
            isDataCorrect = NO;
        }
    }

    if (isDataCorrect) {
        // 补全视频信息
        [self updateDownloadTastInfo:task videoDetail:dataDict];

        UInt64 fileSizeLow = [dataDict unsignedLongLongForKey:@"file_size_nor"];
        NSString *downloadURLLow = [dataDict stringForKey:@"url_nor_mp4"];
        UInt64 fileSizeHigh = [dataDict unsignedLongLongForKey:@"file_size_high"];
        NSString *downloadURLHigh = [dataDict stringForKey:@"url_high_mp4"];
        UInt64 fileSizeUltra = [dataDict unsignedLongLongForKey:@"file_size_super"];
        NSString *downloadURLUltra = [dataDict stringForKey:@"url_super_mp4"];

        // 下载地址容错机制
        // 如果当前清晰度没有下载地址，就切换为高清，否则低清，否则超清
        BOOL isDownloadInfoLowValid = YES;
        if (downloadURLLow == nil || [downloadURLLow isWhitespaceAndNewlines]) {
            isDownloadInfoLowValid = NO;
        }
        BOOL isDownloadInfoHighValid = YES;
        if (downloadURLHigh == nil || [downloadURLHigh isWhitespaceAndNewlines]) {
            isDownloadInfoHighValid = NO;
        }
        BOOL isDownloadInfoUltraValid = YES;
        if (downloadURLUltra == nil || [downloadURLUltra isWhitespaceAndNewlines]) {
            isDownloadInfoUltraValid = NO;
        }
        
        BOOL isDownloadURLValid = YES;
        switch (task.videoDefinition) {
            case kVideoQualityLow:
                if (!isDownloadInfoLowValid) {
                    if (isDownloadInfoHighValid) {
                        task.videoDefinition = kVideoQualityHigh;
                    } else {
                        if (isDownloadInfoUltraValid) {
                            task.videoDefinition = kVideoQualityUltra;
                        } else {
                            isDownloadURLValid = NO;
                        }
                    }
                }
                break;
            default:
            case kVideoQualityHigh:
                if (!isDownloadInfoHighValid) {
                    if (isDownloadInfoLowValid) {
                        task.videoDefinition = kVideoQualityLow;
                    } else {
                        if (isDownloadInfoUltraValid) {
                            task.videoDefinition = kVideoQualityUltra;
                        } else {
                            isDownloadURLValid = NO;
                        }
                    }
                }
                break;
            case kVideoQuality720P: // 不支持720P下载，靠近到超清下载
                task.videoDefinition = kVideoQualityUltra;
            case kVideoQualityUltra:
                if (!isDownloadInfoUltraValid) {
                    if (isDownloadInfoHighValid) {
                        task.videoDefinition = kVideoQualityHigh;
                    } else {
                        if (isDownloadInfoLowValid) {
                            task.videoDefinition = kVideoQualityLow;
                        } else {
                            isDownloadURLValid = NO;
                        }
                    }
                }
                break;
        }
        
        // 无网络错误，但得到数据无效
        if (!isDownloadURLValid) {
            task.errorCode = SHDownloadTaskErrorNetworkUnstable;
            [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorNetworkUnstable-44"];
            [self handleError:task];
        } else {
            NSString *resultString = nil;
            UInt64 totalFileSize = 0;
            switch (task.videoDefinition) {
                case kVideoQualityLow:
                    resultString = downloadURLLow;
                    totalFileSize = fileSizeLow;
                    break;
                default:
                case kVideoQualityHigh:
                    resultString = downloadURLHigh;
                    totalFileSize = fileSizeHigh;
                    break;
                case kVideoQualityUltra:
                    resultString = downloadURLUltra;
                    totalFileSize = fileSizeUltra;
                    break;
            }
            
            task.downloadURLs = [resultString componentsSeparatedByString:@","];
            task.totalSize = totalFileSize;
            
            // 分段任务下载列表获取成功，开始下载任务
            [self downloadFile:task];
        }
    } else  {
        if (isVideoStillValid) {
            task.errorCode = SHDownloadTaskErrorNetworkUnstable;
            [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorNetworkUnstable-55"];
        } else {
            task.errorCode = SHDownloadTaskErrorURLInvalid;
        }
        
        [self handleError:task];
    }
}

- (void)updateDownloadTastInfo:(SHDownloadTask *)task videoDetail:(NSDictionary *)videoDetail {
    if (task.superM3u8UrlString == nil) {
        task.superM3u8UrlString = [videoDetail stringForKey:@"url_super"];
    }
    if (task.highM3u8UrlString == nil) {
        task.highM3u8UrlString = [videoDetail stringForKey:@"url_high"];
    }
    if (task.mediumM3u8UrlString == nil) {
        task.mediumM3u8UrlString = [videoDetail stringForKey:@"url_nor"];
    }
    if (task.originalM3u8UrlString  == nil) {
        task.originalM3u8UrlString = [videoDetail stringForKey:@"url_ori"];
    }
    task.lowMp4UrlString = [videoDetail stringForKey:@"download_url"];
    task.aid = [videoDetail stringForKey:@"aid"];
    task.videoTitle = [videoDetail stringForKey:@"video_name"];
    task.categoryTitle = [videoDetail stringForKey:@"album_name"];
    task.videoPlayOrder = [NSNumber numberWithInt:[[videoDetail stringForKey:@"video_order"] intValue]];
    task.videoHeadTimeLength = [NSNumber numberWithInt:[[videoDetail stringForKey:@"start_time"] intValue]];
    task.videoTailTimeLength = [NSNumber numberWithInt:[[videoDetail stringForKey:@"end_time"] intValue]];
}

// 分段任务下载列表失败处理
- (void)downloadTaskURLListDidFailed:(ASIHTTPRequest*)request {
    // 返回数据检查
    BOOL isDataValid = YES;
    if (request == nil || request.userInfo == nil || ![request.userInfo isKindOfClass:[NSDictionary class]]) {
        isDataValid = NO;
    }
    
    SHDownloadTask *task = nil;
    if (isDataValid) {
        task = [request.userInfo objectForKey:HTTPRequestDownloadTaskKey];
        if (task == nil || ![task isKindOfClass:[SHDownloadTask class]]) {
            isDataValid = NO;
        }
    }
    // 无效数据无法处理
    NSAssert(isDataValid, @"%@:无效数据无法处理!", NSStringFromSelector(_cmd));
    
    Log(@"RequestFailed:%@|HTTPState:%d|Des:%@", request.url, request.responseStatusCode, [request.error description]); // request.error.debugDescription
    
    // 先统一设置为网络错误
    task.errorCode = SHDownloadTaskErrorNetworkUnstable;
    [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorNetworkUnstable-66"];
    [self handleError:task];
}

// 定时器重试处理
- (void)timerFireMethod:(NSTimer*)theTimer {
    if (theTimer == nil || ![theTimer isValid]) {
        return;
    }
    
    if ([theTimer isEqual:self.failedRetryTimer]) {
        SHDownloadTask *task = [theTimer userInfo];
        [self retryTask:task];
    } else if ([theTimer isEqual:self.taskListRetryTimer]) {
        [self retryTasks];
    }
}

// 重新下载任务
- (void)reloadDownloadTask:(SHDownloadTask *)downloadTask {
    [downloadTask reset];
    [self tryStartTask:downloadTask];
}

#pragma mark - ASIRequestDelegate
//开始下载
- (void)request:(ASIHTTPRequest *)request incrementDownloadSizeBy:(long long)newLength {
    SHDownloadTask *task = [request.userInfo objectForKey:HTTPRequestDownloadTaskKey];
    
    // 当获得文件总大小异常时，视作网络不稳定造成之错误
    // 当服务不支持端点续传时, ASI 会回调2次incrementDownloadSize， 第一次的大小为 contentLenth + 本地文件大小, 第二次的大小为 负数的本地文件大小
    // 同时ASI会将本地文件覆盖
    // 当请求的content-length 为0 时 newLength会为1 此时走失败重试逻辑
    if (newLength == MaxInvalidTaskTotalBytes) {
        task.errorCode = SHDownloadTaskErrorNetworkUnstable;
        [self addDownloadTastErrorLog:task errorString:@"SHDownloadTaskErrorNetworkUnstable-77"];
        [self handleError:task];
        return;
    }
    
    // 开始任务重置接收字节数
    self.updateReceivingSize = 0;
    // 设置当前任务期望总大小，校验下载完成状态
    if (newLength < 0) {
        if (task.expectedTotalSize > 0) {
            [task setExpectedTotalSize:task.expectedTotalSize + newLength];
        }
    } else {
        task.expectedTotalSize = newLength;
    }
    
    // 非分段任务总大小获取和检查
    if (![task needRequestURLListForTask]) {
        if (task.totalSize > 0 && newLength < 0) {
            [task setTotalSize:task.totalSize + newLength];
        } else {
            [task setTotalSize:newLength];
        }
    } else {
        if (task.estimatedTotalSize == 0 || newLength < 0) {
            // 没有总大小则估计一个总大小
            if (task.totalSize == 0) {
                task.estimatedTotalSize = task.downloadURLs.count * task.expectedTotalSize;
            } 
            // 如果总大小距离实际可能大小差距过大，则估计一个总大小
            else if (task.totalSize < (task.downloadURLs.count - 1) * task.expectedTotalSize)
            {
                task.estimatedTotalSize = task.downloadURLs.count * task.expectedTotalSize;
            }
        }
    }
}

//正在下载
- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {    
    SHDownloadTask *task = [request.userInfo objectForKey:HTTPRequestDownloadTaskKey];
    // 检查任务状态，防止取消失败的任务继续运行
    if (task == nil || task.downloadState != SHDownloadTaskStateRunning) {
        [task cancel];
        return;
    }
    
    if (bytes > request.partialDownloadSize) {
        bytes -= request.partialDownloadSize;
    }
    // 设置下载速度字节数
    task.downloadedBytesForCalculateSpeed += bytes;
    
    SEL selector = @selector(downloadManager:didUpdateDownloadProgressOfDownloadTask:);
	if(self.delegate && [self.delegate respondsToSelector:selector])
        [self.delegate performSelector:selector withObject:self withObject:task];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DownloadTaskProgressDidUpdatedNotification object:nil userInfo:@{DownloadTaskNotificationKey: task}];
    
    // 设置任务接收字节数
    self.updateReceivingSize += bytes;
    
    // 当累计下载字节数超过预定值时激活磁盘空间检查
    if (self.updateReceivingSize > MaxUpdateReceivingBytes) {
        // 重置接收字节数
        self.updateReceivingSize = 0;

        // 磁盘空间检查
        SInt64 availableDiskSize = freeSpaceSize() - MinReservedDiskSpaceBytes; // 可用于下载的空间
        // 磁盘空间不足全部暂停
        if (availableDiskSize <= 0) {
            [self doPauseAllDownloadTasks];
        }
    }
    
    [task resetRetryState];
}

- (void)finishOneDownloadTask:(SHDownloadTask *)downloadTask {
    
}

#pragma 查询接口
// 获取全部任务的列表
- (NSArray*)getAllDownloadTasks {
    return self.downloadTasks;
}

// 获取全部完成任务的列表
- (NSArray*)getAllCompletedDownloadTasks {
    NSMutableArray *taskList = [self getAllDownloadTasksByDownloadState:SHDownloadTaskStateCompleted];
    return taskList;
}

// 获取全部未完成任务的列表
- (NSArray*)getAllIncompletedDownloadTasks {
    NSMutableArray *taskList = [self getAllDownloadTasksExceptDownloadState:SHDownloadTaskStateCompleted];
    
    return taskList;
}

// 获取按组织类型类的列表
- (NSArray *)getCompletedTasksOrganizedByAlbum {
    // 按照专辑ID进行分类
    NSMutableArray *wantedArray = [NSMutableArray array]; {
        NSMutableDictionary *wantedDict = [NSMutableDictionary dictionary];
        NSArray *allTasks = self.downloadTasks;
        for (SHDownloadTask *task in allTasks) {
            if (task.downloadState == SHDownloadTaskStateCompleted) {
                NSMutableArray *taskList = [wantedDict objectForKey:task.aid];
                if (!taskList) {
                    taskList = [NSMutableArray array];
                    [wantedDict setObject:taskList forKey:task.aid];
                    [wantedArray addObject:taskList];
                }
                [taskList addObject:task];
            }
        }
    }
    NSMutableArray *sortedArray = [NSMutableArray array];
    // 按照播放ID进行排序
    NSString *sortKey = @"videoPlayOrder"; // 保存视频播放顺序的变量名
    for (NSMutableArray *array in wantedArray) {
        [sortedArray addObject:[array sortArrayByKey:sortKey inAscending:YES]];
    }
    return sortedArray;
}

// 通过视频ID查找下载任务
- (SHDownloadTask *)getDownloadTaskByVideoID:(NSString *)vid {
    SHDownloadTask *wantedTask = nil;
    
    NSArray *allTasks = [self getAllDownloadTasks];
    for (SHDownloadTask *task in allTasks) {
        if ([task.vid isEqualToString:vid]) {
            wantedTask = task;
            break;
        }
    }
    
    return wantedTask;
}
- (SHDownloadTask *)getCompletedDownloadTaskByVideoID:(NSString *)vid {
    SHDownloadTask *wantedTask = nil;
    
    NSArray *allTasks = [self getAllCompletedDownloadTasks];
    for (SHDownloadTask *task in allTasks) {
        if ([task.vid isEqualToString:vid]) {
            wantedTask = task;
            break;
        }
    }
    
    return wantedTask;
}
- (SHDownloadTask *)getIncompletedDownloadTaskByVideoID:(NSString *)vid {
    SHDownloadTask *wantedTask = nil;
    
    NSArray *allTasks = [self getAllIncompletedDownloadTasks];
    for (SHDownloadTask *task in allTasks) {
        if ([task.vid isEqualToString:vid]) {
            wantedTask = task;
            break;
        }
    }
    
    return wantedTask;
}

// 根据视频ID获取离线文件下载地址，和清晰度
- (NSString *)downloadedFilePathByVideoID:(NSString *)vid videoQuality:(VideoQuality *)videoQuality {
    NSString *filePath = nil;
    NSArray *downloadedObjects = [self getAllCompletedDownloadTasks];
	for (SHDownloadTask *task in downloadedObjects) {
		if ([task.vid isEqualToString:vid]) {
            filePath = task.downloadFilePath;
            if (videoQuality) {
                *videoQuality = task.videoDefinition;
            }
		}
	}
    
	return filePath;
}

// 根据视频ID和清晰度获取离线文件下载地址
- (NSString*)downloadedFilePathByVideoID:(NSString *)vid andVideoQuality:(VideoQuality)videoQuality {
    NSString *filePath = nil;
    VideoQuality quality = kVideoQualityNone;
    filePath = [self downloadedFilePathByVideoID:vid videoQuality:&quality];
    if (quality != videoQuality)
        filePath = nil;
    
    return filePath;
}

// 下载任务是否已存在
- (BOOL)hasTask:(SHDownloadTask *)downloadTask {
    return ([self containTaskByVid:downloadTask.vid] != nil);
}

- (void)addDownloadTastErrorLog:(SHDownloadTask *)downloadTask errorString:(NSString *)errorString {
    NSString *logString = [NSString stringWithFormat:@"vid=%@, %@", downloadTask.vid, errorString];
    BDebugLog(@"Download Error : %@", logString);
    [self.logArray addObject:logString];
}
@end
