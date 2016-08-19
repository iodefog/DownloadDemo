//
//  DownloadTask.h
//  DownloadCenter
//
//  Created by wangzy on 14-4-16.
//  Copyright (c) 2013年 Sohu Inc. All rights reserved.
//

//#import "SHPlayerConstances.h"

enum  {
    VideoSiteTypeSOHU = 1,
    VideoSiteTypeUGC  = 2
};
typedef NSInteger SHVideoSiteType;

enum {
    SHMovieQualityUnknown  = 0,
    SHMovieQualityUlitra   = (1 << 0), // 超清
    SHMovieQualityHigh     = (1 << 1), // 高清
    SHMovieQualityNormal   = (1 << 2), // 流畅
};
typedef NSUInteger SHMovieQualityType;

#import "SHDownloadConstances.h"

@interface SHDownloadTask : NSObject <NSCopying>

/**
 *  初始化函数
 *
 *  @param vid
 *  @param site
 *
 *  @return self
 */
- (id)initWithVid:(NSString *)vid site:(SHVideoSiteType)site;

// 下载设置属性
@property (nonatomic, retain) NSString *downloadBasePath;           // 下载文件夹路径
@property (nonatomic, assign) SHMovieQualityType videoDefinition;   // 下载任务视频清晰度

// 元数据属性
@property (nonatomic, retain) NSString *vid;            // 视频id
@property (nonatomic, retain) NSNumber *videoPlayOrder; // 下载任务视频播放循序信息

// 任务属性
@property (nonatomic, readonly, assign, getter=downloadedSize) UInt64 downloadedSize;    // 下载任务文件已下载大小
@property (nonatomic, readonly, assign) UInt64 totalSize;                   // 视频文件总大小
@property (nonatomic, assign) UInt64 downloadedBytesPerSecond;              // 每秒钟下载的字节数
@property (nonatomic, assign) SHDownloadTaskState downloadState;            // 下载任务下载状态
@property (nonatomic, readonly, assign) SHDownloadTaskErrorCode errorCode;  // 下载任务错误代码

// 下载文件的路径
@property (nonatomic, readonly, getter = downloadFilePath)  NSString *downloadFilePath; // 视频文件存储路径
@end
