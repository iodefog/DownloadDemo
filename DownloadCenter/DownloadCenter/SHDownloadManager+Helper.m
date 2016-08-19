//
//  DownloadManager+Helper.m
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadManager+Helper.h"
#import "AppStateManager.h"
#import "NSArray+sort.h"

@implementation SHDownloadManager (Helper)

#pragma mark -  查找任务

// 通过视频专辑ID查找下载任务
- (NSArray*)getAllDownloadTasksByCategoryID:(NSString *)aid
{
    NSMutableDictionary *category = [NSMutableDictionary dictionary];
    
    NSArray *allTasks = [self getAllDownloadTasks];
    for (SHDownloadTask *task in allTasks) {
        NSMutableArray *taskList = [category objectForKey:task.aid];
        if (!taskList) {
            taskList = [NSMutableArray array];
            [category setObject:taskList forKey:task.aid];
        }
        [taskList addObject:task];
    }
    
    // 按照播放ID进行排序
    NSString *sortKey = @"videoPlayOrder"; // 保存视频播放顺序的变量名    
    return [[category objectForKey:aid] sortArrayByKey:sortKey inAscending:YES];
}

- (NSArray*)getCompletedDownloadTasksByCategoryID:(NSString *)aid
{
    return [self getCompletedDownloadTasksByCategoryID:aid ascending:YES];
}

- (NSArray*)getCompletedDownloadTasksByCategoryID:(NSString *)aid ascending:(BOOL)ascending
{
    NSMutableArray * categoryVideoArray = [NSMutableArray array];
    
    NSArray *allTasks = [self getAllDownloadTasks];
    for (int i =0 ; i < [allTasks count]; i++)
    {
        SHDownloadTask * task = [allTasks objectAtIndex:i];
        if ([task.aid intValue] == [aid intValue] && task.downloadState == SHDownloadTaskStateCompleted)
        {
            [categoryVideoArray addObject:task];
        }
    }
    // 按照播放ID进行排序
    NSString *sortKey = @"videoPlayOrder"; // 保存视频播放顺序的变量名
    NSArray * sortedArray = [categoryVideoArray sortArrayByKey:sortKey inAscending:ascending];
    return sortedArray;
}

#pragma mark - 删除任务
// 通过视频ID删除下载任务
- (void)removeDownloadTaskByVideoID:(NSArray*)videoIDs
{    
    NSMutableArray *tobeRemove = [NSMutableArray array];
    
    NSArray *allTasks = [self getAllDownloadTasks];
    for (SHDownloadTask *task in allTasks) {
        for (NSString *tempVid in videoIDs) {
            Log(@"compare videoIDs|%@:%@", task.videoID, ID);
            if ([task.vid isEqualToString:tempVid]) {
                [tobeRemove addObject:task];
            }
        }
    }
    
    [self removeDownloadTasks:tobeRemove removeVideoFile:YES];
}

#pragma mark - 恢复任务
// 重新下载任务
- (void)reloadDownloadTaskByVideoID:(NSString *)vid
{
    SHDownloadTask *task = [self getDownloadTaskByVideoID:vid];
    if (task) {
        [self reloadDownloadTask:task];
    }
}
// 恢复所有需要合并的任务
- (void)restoreMergingTasks
{
    [self mergeAllAvailableTasks];
}
#pragma mark - 其他
// 检查下载目标任务还差多少可用空间
// 返回值: 0 表示有足够的可用空间
- (UInt64)moreExtraFreeSpaceForTask:(SHDownloadTask *)downloadTask
{
    return [self moreNecessaryFreeSpaceForTask:downloadTask];
}
// 当前所有下载任务占用磁盘空间大小
- (UInt64)downloadSizeOfAllTasks
{
    return [self totalSizeOfAllTasks];
}
// 控制是否在有下载任务时禁止自动锁屏
- (void)disableAutolockWhenDownloading:(BOOL)disable
{
    if (disable) {
        // 当前有任务正在运行
        if ([[SHDownloadManager sharedInstance] isThereAnyBusiness]) {
//            [[AppStateManager sharedInstance] disableAutolock];
        }
    } else {
//        [[AppStateManager sharedInstance] resumeAutolock];
    }
}



@end