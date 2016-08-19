//
//  DownloadDataManager_Internal.h
//  DownloadCenter
//
//  Created by yufei yan on 12-5-4.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadDataManager.h"

@interface SHDownloadDataManager ()

// 下载任务信息保存文件名
UIKIT_EXTERN NSString *const DownloadTaskInfoSavingFilename;

// 检查并升级下载任务保存信息
+ (void)upgradeDownloadTasksSaveInfo;

// 保存下载任务信息
+ (void)saveDownloadTasksInfo:(NSArray*)downloadTasks;

// 保存下载log信息
+ (void)saveDownloadTasksLog:(NSArray*)logArray;

// 读取下载任务信息，返回一个DownloadTask的列表
+ (NSMutableArray*)loadDownloadTasksInfo;

// 删除无效文件
+ (void)deleteInvalidFilesAgainstTaskList:(NSArray*)tasks;

// 下载任务信息保存路径
+ (NSString*)downloadTaskInfoSavingPath;

@end
