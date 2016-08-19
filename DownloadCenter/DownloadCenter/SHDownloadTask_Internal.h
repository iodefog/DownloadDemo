//
//  DownloadTask_Internal.h
//  DownloadCenter
//
//  Created by yufei yan on 12-4-25.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

typedef enum _VideoQuality
{
    kVideoQualityNone  = (0),        //无效
    kVideoQualityUltra = (1 << 0),   //超清
    kVideoQualityHigh  = (1 << 1),   //高清
    kVideoQualityLow   = (1 << 2),   //低清
    kVideoQuality720P  = (1 << 3)    //720P
} VideoQuality;


#import "SHDownloadTask.h"

// 分段下载地址模板
UIKIT_EXTERN NSString *const DownloadUrlTemplate;

@interface SHDownloadTask ()

/***********
 元数据
 **********/
@property (nonatomic, retain) NSString *aid;        // 专辑id

@property (nonatomic, assign) SHVideoSiteType site; // 视频来源

@property(nonatomic, retain) NSString *defaultThumbnailURL;     // 默认缩略图下载地址 (iPad或iPhone只需存储需要的) (专辑)
@property(nonatomic, retain) NSString *thumbnailURL;            // 缩略图下载地址 (单个视频截图)
@property(nonatomic, retain) NSString *originalM3u8UrlString;   // 原画m3u8播放地址
@property(nonatomic, retain) NSString *superM3u8UrlString;      // 超清m3u8播放地址
@property(nonatomic, retain) NSString *highM3u8UrlString;       // 高清m3u8播放地址
@property(nonatomic, retain) NSString *mediumM3u8UrlString;     // 标清m3u8播放地址
@property(nonatomic, retain) NSString *lowMp4UrlString;         // 流畅整段mp4下载地址
@property(nonatomic, retain) NSString *categoryTitle;           // 下载任务专辑标题
@property(nonatomic, retain) NSString *videoTitle;              // 下载任务视频标题
@property(nonatomic, retain) NSMutableDictionary *reserved;     // 预留私有数据
@property(nonatomic, retain) NSString *cateCode;                // 视频一级分类ID
@property(nonatomic, assign) BOOL isTrailer;                    // 视频是否是片花
@property(nonatomic, assign) CGFloat score;                     // 评分

/***********
 播放属性
 **********/
@property (nonatomic, retain) NSString *videoDescription;     // 下载任务视频内容详情介绍
@property (nonatomic, retain) NSNumber *videoTimeLength;      // 下载任务视频时长信息
@property (nonatomic, retain) NSNumber *videoHeadTimeLength;  // 下载任务视频片头时长信息
@property (nonatomic, retain) NSNumber *videoTailTimeLength;  // 下载任务视频片尾时长信息
@property (nonatomic, retain) NSNumber *videoTypeID;          // 下载任务视频类型ID
@property (nonatomic, assign) BOOL isSerial;                  // 视频是否是连载的

/***********
   任务属性
 **********/
@property (nonatomic, assign) UInt64 totalSize;                      // 下载任务视频文件总大小
@property (nonatomic,assign) DownloadTaskRunningState runningState;  // 下载任务运行状态
@property (nonatomic,retain) NSArray *downloadURLs;                  // 下载任务下载地址列表
@property (nonatomic,assign) NSInteger currentSegmentIndex;          // 下载任务下载地址列表中当前正在下载项序号
@property (nonatomic,retain) NSNumber *createdTime;                  // 下载任务创建时间
@property (nonatomic,assign) SHDownloadTaskErrorCode errorCode;      // 下载任务错误代码
@property (nonatomic,assign) UInt64 downloadedSize;                  // 下载任务文件已下载大小
@property (nonatomic,assign) UInt64 expectedTotalSize;               // 下载任务当前分段文件期望总大小
@property (nonatomic, assign) UInt64 estimatedTotalSize;             // 下载任务的估算总大小

@property (nonatomic, readwrite, getter=downloadStoreBasePath)  NSString *downloadStoreBasePath; // 视频文件存储路径

@property (nonatomic, retain, getter=relativeSavePathVideoFile) NSString *relativeSavePathVideoFile;     // 视频文件存储相对路径
@property (nonatomic, retain, getter=relativeSavePathVideoCache) NSString *relativeSavePathVideoCache;   // 视频临时缓存存储相对路径

// 音乐相册使用的属性
@property (nonatomic, assign) BOOL isDownloadingPhotos;
@property (nonatomic, assign) BOOL didDownloadPhotos;
@property (nonatomic, retain) NSMutableArray * musicAlbumItemsArray;


// 剩余失败重试次数
@property(nonatomic,assign) NSInteger remainFailedRetryTimes;

// 合并失败重试次数
@property(nonatomic,assign) NSInteger remainMergeRetryTimes;

// 下载任务请求
@property(nonatomic,retain) ASIHTTPRequest *httpRequest;

/***********
 版本兼容
 **********/
@property(nonatomic, assign) BOOL upgradeIsIncompatible; // 下载任务升级数据结构不兼容标记

/**************
 下载任务比较方法
 *************/
- (BOOL)isEqualTo:(SHDownloadTask *)task;
- (BOOL)doesBelongToSameAlbum:(SHDownloadTask *)task;  // 属于统一专辑

/**************
 任务属性判定
 *************/
- (BOOL)canBeRetried;   // 错误是否可重试
- (BOOL)isValid;        // 下载任务必要信息是否完备

// 是否是分段任务
- (BOOL)isMultiSegment;
// 下载文件保存相对路径
- (NSString*)relativeDownloadPath;
// 文件下载地址
- (NSURL*)downloadURL;
// 错误是否可恢复
- (BOOL)canBeRecovered;
// 重置重试状态
- (void)resetRetryState;
// 重试下载任务
- (void)retry:(SEL)operation onObject:(id)object;
// 是否需要请求下载列表
- (BOOL)needRequestURLListForTask;
// 数据存储结构转换
- (NSDictionary*)toDictionary;
// 从存储字典中生成一个任务
+ (SHDownloadTask *)taskFromDictionary:(NSDictionary *)dictionary;
// 暂停
- (void)pause;
// 取消
- (void)cancel;
// 已下载数据是否完整
- (BOOL)isDownloadedDataIntact;
// 删除任务所有相关数据
- (void)eraseDownloadedData;
// 删除下载缓存数据
- (void)eraseCachedData;
// 删除下载任务目标文件
- (void)eraseTargetFile;


// 重置
- (void)reset;
// 获取视频特定清晰度的分段下载请求地址
- (NSString*)segmentRequestURL:(VideoQuality)videoQuality;

// 每秒钟下载的字节数
@property(nonatomic,assign) UInt64 downloadedBytesForCalculateSpeed;
@property(nonatomic,retain) NSTimer *timerForCalculateSpeed;
@property(nonatomic,retain) NSDate *lastDateForCalculateSpeed;

@end


@interface SHDownloadTask (Util)

- (void)fireCalculatingSpeed;
- (void)stopCalculatingSpeed;
- (void)triggerTimerForCalculateSpeed:(NSTimer *)timer;

@end
