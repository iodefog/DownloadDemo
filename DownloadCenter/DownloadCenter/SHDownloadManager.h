//
//  DownloadManager.h
//  DownloadCenter
//
//  Created by wangzy on 14-4-16.
//  Copyright (c) 2013年 Sohu Inc. All rights reserved.
//

#import "SHDownloadConstances.h"
#import "ASIProgressDelegate.h"
#import "ASIHTTPRequestDelegate.h"

@class SHDownloadTask;
@class SHDownloadManager;
@class ASIHTTPRequest;

@protocol DownloadManagerDelegate <NSObject>

@optional

/**
 *  任务下载状态变化回调
 *
 *  @param downloadManager
 *  @param downloadTask
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didUpdateStatusOfDownloadTask:(SHDownloadTask *)downloadTask;

/**
 *  任务下载进度变化回调
 *
 *  @param downloadManager
 *  @param downloadTask
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didUpdateDownloadProgressOfDownloadTask:(SHDownloadTask *)downloadTask;

/**
 *  添加了新任务回调
 *
 *  @param downloadManager
 *  @param downloadTask
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didAddOneNewDownloadTask:(SHDownloadTask *)downloadTask;

/**
 *  有任务被删除回调
 */
- (void)downloadManagerDidRemoveDownloadTasks;

/**
 *  任务列表状态发生变化
 *
 *  @param downloadManager
 *  @param downloadTasks
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didUpdateStatusOfDownloadTasks:(NSArray*)downloadTasks;
@end


@interface SHDownloadManager : NSObject <ASIHTTPRequestDelegate, ASIProgressDelegate>

@property (nonatomic, assign) id<DownloadManagerDelegate> delegate;

/**
 *  任务列表组织形式，默认为DownloadTaskOrganizedFormCreatedTime
 */
@property (nonatomic, assign) SHDownloadTaskOrganizedForm organizedForm;

/**
 *  多任务下载控制，最大并发下载个数不能超过3个。
 */
@property (nonatomic, assign) BOOL allowMultiTask;
@property (nonatomic, assign) NSInteger maxTaskNumber;

/**
 *  单例函数
 *
 *  @return
 */
+ (id)sharedInstance;

/**
 *  设置下载文件夹基础路径
 *
 *  @param targetForder the base path of download
 *  @return the full path of download
 */
+ (NSString *)setupDownloadStoreBasePath:(NSString *)targetForder;

/**
 *  添加一个新的任务
 *
 *  @param downloadTask 下载任务对象
 *
 *  @return 添加状态
 */
- (SHDownloadTaskCreationErrorCode)addDownloadTask:(SHDownloadTask *)downloadTask;

/**
 *  添加多个下载任务到下载队列，添加的下载任务会进行检查，是否已经在下载队列中
 *
 *  @param tasks 多个任务数组
 */
- (SHDownloadTaskCreationErrorCode)addNewDownloadTasks:(NSArray *)tasks;

/**
 *  删除指定vid下载任务
 *
 *  @param vid 删除任务的vid
 *  @param removeFile 是否删除下载视频文件, 为避免与上层App重复删除引起的问题
 */
- (void)removeDownloadTaskByVid:(NSString *)vid removeVideoFile:(BOOL)removeFile;

/**
 *  删除数组下载对象
 *
 *  @param downloadTaskList 删除数组对象
 */
- (void)removeDownloadTasks:(NSArray *)downloadTaskList removeVideoFile:(BOOL)removeFile;

/**
 *  保存当前下载任务文件到本地
 */
- (void)saveDownloadTasks;

/**
 *  启动指定下载任务
 *
 *  @param downloadTask 下载任务对象
 */
- (void)startDownloadTask:(SHDownloadTask *)downloadTask;

/**
 *  启动当前所有下载任务
 */
- (void)startAllDownloadTasks;

/**
 *  暂停指定下载任务
 *
 *  @param downloadTask 暂停任务对象
 */
- (void)pauseDownloadTask:(SHDownloadTask *)downloadTask;

/**
 *  暂停当前全部下载任务
 */
- (void)pauseAllDownloadTasks;


#pragma mark - 查询相关接口

/**
 *  获取全部任务的列表
 *
 *  @return 全部任务列表
 */
- (NSArray *)getAllDownloadTasks;

/**
 *  获取全部完成任务的列表
 *
 *  @return 全部已完成列表
 */
- (NSArray *)getAllCompletedDownloadTasks;

/**
 *  获取全部未完成任务的列表
 *
 *  @return 全部未完成任务的列表
 */
- (NSArray *)getAllIncompletedDownloadTasks;

/**
 *  获取全部完成的任务按照专辑组织列表
 *
 *  @return 全部完成的任务按照专辑组织列表
 */
- (NSArray *)getCompletedTasksOrganizedByAlbum;

/**
 *  以下几个函数为根据vid查询下载任务
 *
 *  @param vid
 *
 *  @return vid对应下载任务
 */
- (SHDownloadTask *)getDownloadTaskByVideoID:(NSString *)vid;
- (SHDownloadTask *)getCompletedDownloadTaskByVideoID:(NSString *)vid;
- (SHDownloadTask *)getIncompletedDownloadTaskByVideoID:(NSString *)vid;

// 下载任务是否已存在
- (BOOL)hasTask:(SHDownloadTask *)downloadTask;
@end