//
//  DownloadManager+Helper.h
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadManager.h"


/*******************************
      辅助功能及界面显示相关功能
 ******************************/
@interface SHDownloadManager (Helper)

/****************************
           查找任务
 ***************************/

// 通过视频专辑ID查找下载任务
- (NSArray *)getAllDownloadTasksByCategoryID:(NSString *)aid;
// 通过视频ID查找下载任务
- (NSArray *)getCompletedDownloadTasksByCategoryID:(NSString *)aid;
- (NSArray *)getCompletedDownloadTasksByCategoryID:(NSString *)aid ascending:(BOOL)ascending;


/****************************
           删除任务
 ***************************/
// 通过视频ID删除下载任务
- (void)removeDownloadTaskByVideoID:(NSArray*)videoIDs;

/****************************
           恢复任务
 ***************************/
// 重新下载任务
- (void)reloadDownloadTaskByVideoID:(NSString *)vid;
// 恢复所有需要合并的任务
- (void)restoreMergingTasks;

/****************************
            其他
 ***************************/
// 检查下载目标任务还差多少可用空间
// 返回值: 0 表示有足够的可用空间
- (UInt64)moreExtraFreeSpaceForTask:(SHDownloadTask *)downloadTask;
// 当前所有下载任务占用磁盘空间大小
- (UInt64)downloadSizeOfAllTasks;
// 控制是否在有下载任务时禁止自动锁屏
- (void)disableAutolockWhenDownloading:(BOOL)disable;

@end
