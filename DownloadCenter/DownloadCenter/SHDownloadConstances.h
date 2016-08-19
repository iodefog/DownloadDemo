//
//  DownloadConstances.h
//  DownloadCenter
//
//  Created by wangzy on 14-4-16.
//  Copyright (c) 2013年 Sohu Inc. All rights reserved.
//

// 任务添加返回出错代码
typedef enum {
    SHDownloadTaskCreationErrorUnknown = -1,       // 未知错误
    SHDownloadTaskCreationNoError = 0,             // 添加成功
    SHDownloadTaskCreationErrorAlreadyExist,       // 任务已存在
    SHDownloadTaskCreationErrorTaskCountLimited,   // 下载任务达到最大数
    SHDownloadTaskCreationErrorURLInvalid,         // 下载地址无效
    SHDownloadTaskCreationErrorIPLimited,          // 下载地址受限
    SHDownloadTaskCreationErrorNetworkUnavailable, // 当前网络不允许下载
} SHDownloadTaskCreationErrorCode;

// 下载任务状态
typedef enum {
    SHDownloadTaskStateInvalid = -1,  // 未知状态
    SHDownloadTaskStateWaiting = 0,   // 等待开始
    SHDownloadTaskStateRunning,       // 下载进行中
    SHDownloadTaskStatePaused,        // 任务被暂停
    SHDownloadTaskStateMerging,       // 正在合并分段
    SHDownloadTaskStateFailed,        // 任务下载失败
    SHDownloadTaskStateCompleted      // 任务下载完毕
} SHDownloadTaskState;

// 下载任务出错代码
typedef enum {
    SHDownloadTaskErrorUnknown = -1,      // 未知错误
    SHDownloadTaskNoError = 0,            // 无错误
    SHDownloadTaskErrorDeniedNonWiFi,     // 非WiFi拒绝下载
    SHDownloadTaskErrorNoNetwork,         // 当前无网络连接
    SHDownloadTaskErrorNetworkUnstable,   // 网络不稳定
    SHDownloadTaskErrorMergeInterrupted,  // 分段合并中断
    SHDownloadTaskErrorFileBroken,        // 下载文件损坏
    SHDownloadTaskErrorURLInvalid         // 下载地址无效
} SHDownloadTaskErrorCode;

// 下载任务列表组织形式
typedef enum {
    SHDownloadTaskOrganizedFormInvalid = -1,      // 无效排列顺序
    SHDownloadTaskOrganizedFormCreatedTime = 0,   // 按照创建时间排序，单节点为DownloadTask
    SHDownloadTaskOrganizedFormAlbum              // 按照专辑分类，专辑间按照时间排序，专辑内按照播放顺序排序，
} SHDownloadTaskOrganizedForm;

