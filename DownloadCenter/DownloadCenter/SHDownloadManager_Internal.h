// 
//  DownloadManager_Internal.h
//  DownloadCenter
//
//  Created by yufei yan on 12-4-24.
//  Copyright (c) 2012年 SOHU. All rights reserved.
// 

#import "SHDownloadManager.h"

@interface SHDownloadManager ()

@property (nonatomic,retain) NSMutableArray *downloadTasks; // 下载任务列表，列表项的顺序为添加顺序
// 组织过的下载任务列表，列表项的顺序为DownloadTaskOragnizedForm
@property (nonatomic,retain) NSMutableArray *organizedDownloadTasks;
@property (nonatomic,retain) NSMutableArray *priorTasks; // 优先下载队列
@property (nonatomic,retain) NSMutableDictionary *restoreTasks; // 状态变化恢复任务列表
@property (nonatomic,retain) ASINetworkQueue *downloadQueue; // 下载任务处理队列
@property (nonatomic,retain) NSTimer *failedRetryTimer; // 失败重试定时器
@property (nonatomic,retain) NSTimer *taskListRetryTimer; // 下载列表重试定时器
@property (nonatomic,assign) long long updateReceivingSize; // 当前累计已下载字节数
@property (nonatomic,assign) BOOL needUpdateRestoreTasks; // 是否需要更新恢复列表
@property (nonatomic,readonly) NSInteger maxMultiTasks;// 支持的并行下载文件个数

/****************************
           辅助方法
 ***************************/
// 根据任务状态获取的任务列表
- (NSMutableArray*)getAllDownloadTasksByDownloadState:(SHDownloadTaskState)downloadState;
// 获取除某个状态之外的任务列表
- (NSMutableArray*)getAllDownloadTasksExceptDownloadState:(SHDownloadTaskState)downloadState;
// 初始化下载队列
- (void)initDownloadQueue;
// 释放下载队列
- (void)deallocDownloadQueue;
// 检查下载目标任务还差多少可用空间
// 返回值: 0 表示有足够的可用空间
- (UInt64)moreNecessaryFreeSpaceForTask:(SHDownloadTask *)downloadTask;
// 下载文件夹基础路径
+ (NSString*)downloadStoreBasePath;
// 创建文件夹
+ (NSString*)makeDirectoryWithBase:(NSString*)basePath andSub:(NSString*)subPath createIfNotExist:(BOOL)isCreate;
// 计算文件/文件夹大小
+ (UInt64)caculateSizeOfPath:(NSString*)filePath;
// 获取当前下载任务的处理方法
+ (SEL)downloadOperation:(SHDownloadTask *)downloadTask;
// 下载任务已存在
- (SHDownloadTask *)containTask:(SHDownloadTask *)downloadTask;
// 网络状况允许开始下载
- (BOOL)isNetworkAvailableToDownload;
// 暂停并保存当前处于开始和等待状态的列表
- (void)saveAndPauseTasksWithCurrentStateOfRuningAndWaiting;
// 恢复记录中处于开始和等待状态的列表
- (void)restoreTasksWithRecordedStateOfRuningAndWaiting;
// 清空恢复列表
- (void)cleanupRestoreLists;
// 当前所有下载任务占用磁盘空间大小
- (UInt64)totalSizeOfAllTasks;
// 更新优先下载队列
- (NSMutableArray*)updatePriorTasks;
// 是否还有下载任务
- (BOOL)isThereAnyBusiness;
// 合并所有需要合并的任务
- (void)mergeAllAvailableTasks;
// 插入可恢复队列
- (void)addRestoreTask:(SHDownloadTask *)downloadTask;
// 发送状态变化回调
- (void)postDownloadTaskStatusDidUpdated:(SHDownloadTask *)task;

/****************************
          下载主逻辑
 ***************************/
// 错误处理
- (void)handleError:(SHDownloadTask *)downloadTask;
// 启动所有下载任务-内部使用
- (void)doStartAllDownloadTasks;
// 暂停下载任务-内部使用
- (void)doPauseDownloadTask:(SHDownloadTask *)downloadTask;
// 暂停所有下载任务-内部使用
- (void)doPauseAllDownloadTasks;
// 尝试开始下载任务
- (BOOL)tryStartTask:(SHDownloadTask *)downloadTask;
// 重试下载任务
- (void)retryTask:(SHDownloadTask *)downloadTask;
// 重试下载任务列表
- (void)retryTasks;
// 开始下载任务
- (void)doStartTask:(SHDownloadTask *)downloadTask;
// 下载列表
- (void)downloadURLListForTask:(SHDownloadTask *)downloadTask;
// 下载文件
- (void)downloadFile:(SHDownloadTask *)downloadTask;
// 继续下一个下载任务
- (void)downloadNextTask;
// 合并分段
- (void)mergeSegmentedTask:(SHDownloadTask *)downloadTask;
// 下载文件成功处理
- (void)downloadFileDidFinished:(ASIHTTPRequest*)request;
// 下载文件失败处理
- (void)downloadFileDidFailed:(ASIHTTPRequest*)request;
// 分段任务下载列表成功处理
- (void)downloadTaskURLListDidFinished:(ASIHTTPRequest*)request;
// 分段任务下载列表失败处理
- (void)downloadTaskURLListDidFailed:(ASIHTTPRequest*)request;
// 定时器重试处理
- (void)timerFireMethod:(NSTimer*)theTimer;
// 重新下载任务
- (void)reloadDownloadTask:(SHDownloadTask *)downloadTask;

- (void)finishOneDownloadTask:(SHDownloadTask *)downloadTask;
@end
