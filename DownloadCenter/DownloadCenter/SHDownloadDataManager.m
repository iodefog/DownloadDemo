//
//  DownloadDataManager.m
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadDataManager_Internal.h"
#import "SHDownloadTask.h"
//#import "NSStringExtend.h"

/****************************
  初始化下载任务存储字典字段信息
 ***************************/

/*< DownloadTaskAddNewSaveItemTag 02 >*/

// 元数据
NSString *const DownloadTaskMetadataDefaultThumbnailURLKey = @"DefThumbURL";
NSString *const DownloadTaskMetadataThumbnailURLKey = @"ThumbURL";
NSString *const DownloadTaskMetadataCategoryIDKey = @"AID";
NSString *const DownloadTaskMetadataVideoIDKey = @"VID";
NSString *const DownloadTaskMetadataSiteKey = @"Site";
NSString *const DownloadTaskMetadataOriginalM3u8UrlStringKey = @"OM3u8Url";
NSString *const DownloadTaskMetadataSuperM3u8UrlStringKey = @"SM3u8Url";
NSString *const DownloadTaskMetadataHighM3u8UrlStringKey = @"HM3u8Url";
NSString *const DownloadTaskMetadataMediumM3u8UrlStringKey = @"MM3u8Url";
NSString *const DownloadTaskMetadataLowMp4UrlStringKey = @"LMp4Url";
NSString *const DownloadTaskMetadataCategoryTitleKey = @"CTitle";
NSString *const DownloadTaskMetadataVideoTitleKey = @"VTitle";
NSString *const DownloadTaskMetadataReservedKey = @"Reserved";
NSString *const DownloadTaskMetadataCateCodeKey = @"CateCode";
NSString *const DownloadTaskMetadataIsTrailerKey = @"IsTrailer";
NSString *const DownloadTaskMetadataScoreKey = @"Score";

// 保存路径
NSString *const DownloadTaskSavePathVideoFileKey = @"RSBasePath";
NSString *const DownloadTaskRelativeSavePathVideoFileKey = @"RSPathFile";
NSString *const DownloadTaskRelativeSavePathVideoCacheKey = @"RSPathCache";

// 播放属性
NSString *const DownloadTaskPlayInfoVideoDescriptionKey = @"Desc";
NSString *const DownloadTaskPlayInfoVideoPlayOrderKey = @"PlayOrder";
NSString *const DownloadTaskPlayInfoVideoHeadTimeLengthKey = @"HeadTime";
NSString *const DownloadTaskPlayInfoVideoTailTimeLengthKey = @"TailTime";
NSString *const DownloadTaskPlayInfoVideoTimeLengthKey = @"TimeLength";

NSString *const DownloadTaskPlayInfoVideoTypeIDKey = @"TypeID";
NSString *const DownloadTaskPlayInfoVideoIsSerialKey = @"IsSerial";
// 任务属性
NSString *const DownloadTaskPropertyVideoFileTotalSizeKey = @"TotalSize";
NSString *const DownloadTaskPropertyVideoDefinitionKey = @"Definition";
NSString *const DownloadTaskPropertyDownloadStateKey = @"DownloadSt";
NSString *const DownloadTaskPropertyRunningStateKey = @"RunningSt";
NSString *const DownloadTaskPropertyDownloadURLListKey = @"DownloadURLs";
NSString *const DownloadTaskPropertyCurrentSegmentIndexKey = @"CurSegIndex";
NSString *const DownloadTaskPropertyCreatedTimeKey = @"CreatedTime";
NSString *const DownloadTaskPropertyErrorCodeKey = @"ErrorCode";

// 版本兼容
NSString *const DownloadTaskUpgradeIncompatibleLabelKey = @"IncompLabel";

// 下载任务保存文件名
NSString *const DownloadTaskInfoSavingFilename = @"Download_Task.plist";

NSString *const DownloadTaskInfoSavingLogName  = @"Download_Task_Log.plist";

@implementation SHDownloadDataManager


// 删除无效文件
+ (void)deleteInvalidFilesAgainstTaskList:(NSArray*)tasks 
{
    // 保留文件列表
    NSMutableDictionary *reserveFileList = [NSMutableDictionary dictionary];
    NSNumber *placeHolder = [NSNumber numberWithBool:YES];
    [reserveFileList setObjectOrNil:placeHolder forKey:DownloadTaskInfoSavingFilename];
    for (SHDownloadTask *task in tasks) {
        if (task.downloadState == SHDownloadTaskStateCompleted) { // 任务状态为完成，只保留目标文件名
            [reserveFileList setObjectOrNil:placeHolder forKey:task.relativeSavePathVideoFile];
        } else { // 任务状态为非完成
            switch (task.runningState) {
                case DownloadTaskRunningStateMerging: // 合并状态
                    // 非完成状态，保留缓存文件夹
                    if (![[NSFileManager defaultManager] fileExistsAtPath:task.downloadFilePath] ||
                        task.downloadState != SHDownloadTaskStateCompleted)
                        [reserveFileList setObjectOrNil:placeHolder forKey:[[task relativeSavePathVideoCache] stringByDeletingLastPathComponent]];
                    break;
                case DownloadTaskRunningStateDownloading: // 下载状态
                    if (![task needRequestURLListForTask]) { // 无分段，保留缓存文件
                        [reserveFileList setObjectOrNil:placeHolder forKey:[task relativeSavePathVideoCache]];
                    } else { // 有分段，保留缓存文件夹
                        [reserveFileList setObjectOrNil:placeHolder forKey:[[task relativeSavePathVideoCache] stringByDeletingLastPathComponent]];
                    }
                default:
                    // 不做处理
                    break;
            }
        }
    }
    // 当前版本下载文件保存基本路径
//    NSString *strDownloadCachePath = [SHDownloadManager downloadStoreBasePath];
//    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:strDownloadCachePath error:nil];
//    // 遍历下载文件夹，删除不在保留列表中的文件
//    for (NSString *onePath in contents) {
//        if ([reserveFileList objectForKey:onePath] == nil) {
//            [[NSFileManager defaultManager] removeItemAtPath:[strDownloadCachePath stringByAppendingPathComponent:onePath] error:nil];
//        }
//    } 
}
#pragma mark - 主要逻辑
// 下载任务信息保存路径
+ (NSString*)downloadTaskInfoSavingPath
{
    return [[SHDownloadManager downloadStoreBasePath] stringByAppendingPathComponent:DownloadTaskInfoSavingFilename];
}
// 是否是非兼容版本下载任务信息
+ (BOOL)isIncompatibleTaskInfo:(NSDictionary*)info
{
    BOOL isInCompatible = NO;
    
    if ([info objectForKey:DownloadTaskMetadataCategoryIDKey] == nil ||
        [info objectForKey:DownloadTaskMetadataVideoIDKey] == nil)
        isInCompatible = YES;
    
    return isInCompatible;
}
// 移动文件夹
+ (void)moveDirectoryFrom:(NSString *)srcPath to:(NSString *)desPath
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *contents = [fileMgr contentsOfDirectoryAtPath:srcPath error:nil];
    [SHDownloadManager makeDirectoryWithBase:desPath andSub:nil createIfNotExist:YES];

    for (NSString *onePath in contents)
    {
        BOOL isFolder = YES;
        NSString *srcOnePath = [srcPath stringByAppendingPathComponent:onePath];
        NSString *desOnePath = [desPath stringByAppendingPathComponent:onePath];
        if ([fileMgr fileExistsAtPath:srcOnePath isDirectory:&isFolder]) {
            if (isFolder) {
                [self.class moveDirectoryFrom:srcOnePath to:desOnePath];
            } else {
                [fileMgr moveItemAtPath:srcOnePath toPath:desOnePath error:nil];
            }
        }
    }
}

// 检查并升级下载任务保存信息
+ (void)upgradeDownloadTasksSaveInfo
{
    Log(@"检查并升级下载任务保存信息");
}
// 保存下载任务信息
+ (void)saveDownloadTasksInfo:(NSArray*)downloadTasks
{
    Log(@"保存下载任务信息");
    @synchronized(self) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *dictArray = [NSMutableArray array];
            for (int i = 0; i < downloadTasks.count; ++i) {
                SHDownloadTask *task = [downloadTasks objectOrNilAtIndex:i];
                [dictArray addObjectOrNil:[task toDictionary]];
            }
            
            // 确保文件保存路径存在
            NSString *saveBasePath = [self downloadTaskInfoSavingPath];
            [SHDownloadManager makeDirectoryWithBase:[saveBasePath stringByDeletingLastPathComponent] andSub:nil createIfNotExist:YES];
            [dictArray writeToFile:[self downloadTaskInfoSavingPath] atomically:YES];
        });
    }
}

// 保存下载log
+ (void)saveDownloadTasksLog:(NSArray*)logArray
{
    Log(@"保存下载log信息");
    return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *savePath = [[SHDownloadManager downloadStoreBasePath] stringByAppendingPathComponent:DownloadTaskInfoSavingLogName];;
        [SHDownloadManager makeDirectoryWithBase:[savePath stringByDeletingLastPathComponent] andSub:nil createIfNotExist:YES];
        [logArray writeToFile:savePath atomically:YES];
    });
}

// 读取下载任务信息，返回一个DownloadTask的列表
+ (NSMutableArray*)loadDownloadTasksInfo
{
    Log(@"读取下载任务信息");
    NSMutableArray *tasks = [NSMutableArray new];
    
    NSArray *saveTasks = [NSArray arrayWithContentsOfFile:[self downloadTaskInfoSavingPath]];
    for (NSDictionary *taskInfo in saveTasks) {
        SHDownloadTask *task = [SHDownloadTask taskFromDictionary:taskInfo];
        if (task) {
            // 初始为合并状态的任务，置为暂停
            if (task.downloadState == SHDownloadTaskStateMerging)
                task.downloadState = SHDownloadTaskStatePaused;
            [tasks addObject:task];
        }
    }
    
    return [tasks autorelease];
}

@end
