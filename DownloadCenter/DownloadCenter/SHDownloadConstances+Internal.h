//
//  DownloadConstances+Internal.h
//  DownloadCenter
//
//  Created by yufei yan on 12-4-24.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

/*******************************
        提供内部公共常量声明
 ******************************/

// 下载任务运行状态
typedef enum _DownloadTaskRunningState {
    DownloadTaskRunningStateRequestingTaskInfo = 0, // 正在获取下载任务信息
    DownloadTaskRunningStateDownloading, // 正在下载数据
    DownloadTaskRunningStateMerging // 正在合并已下载数据
} DownloadTaskRunningState;
// 分段下载清晰度类型
typedef enum _DownloadVideoQualityType {
    DownloadVideoQualityTypeHigh = 1, // 高清(对应播放地址url)，
    DownloadVideoQualityTypeMedium = 2, // 普清(对应播放地址lowUrl)，
    DownloadVideoQualityTypeLow = 10, // 流畅(对应播放地址mobileUrl)，
    DownloadVideoQualityTypeSuper = 21, // 超清(对应播放地址highUrl)
    DownloadVideoQualityTypeOriginal = 31, // 原画(对应播放地址url31)
} DownloadVideoQualityType;
// 最大下载失败重试次数
static const NSInteger MaxFailedRetryTimes = 3;
// 最大合并失败重试次数
static const NSInteger MaxMergeRetryTimes = 1;

// 默认下载任务数
static const NSInteger DefaultCocurrentTaskNum = 1;
// 最大同时下载任务数
static const NSInteger MaxCocurrentTaskNum = 3;
// 最大离线缓存任务数
static const NSInteger MaxDownloadTaskNum = 10000;
// 网络超时时长
static const NSInteger NetWorkTimeoutSeconds = 15;
// 失败自动重试间隔时长
#ifdef DEBUG
static const NSInteger FailedRetryIntervalSeconds = 3;
#else // DEBUG
static const NSInteger FailedRetryIntervalSeconds = 15;
#endif // DEBUG
// 任务列表自动重试间隔时长
#ifdef DEBUG
static const NSInteger TaskListRetryIntervalSeconds = 3;
#else // DEBUG
static const NSInteger TaskListRetryIntervalSeconds = 10 * 60; // 10 分钟
#endif // DEBUG
// 最小预留硬盘空间
static const NSInteger MinReservedDiskSpaceBytes = 500 * 1024 * 1024; // 500M
// 下载硬盘空间检查增量大小
static const NSInteger MaxUpdateReceivingBytes = 3 * 1024 * 1024; // 3M
// 最大无效下载任务总大小
static const NSInteger MaxInvalidTaskTotalBytes = 1; // 1K
// 下载任务请求中用户数据字段
UIKIT_EXTERN NSString *const HTTPRequestDownloadTaskKey; // 保存当前下载任务对象
// 下载文件保存子路径
UIKIT_EXTERN NSString *const DownloadStoreSubPath;
// 下载缓存文件后缀
UIKIT_EXTERN NSString *const DownloadCacheFileExtension;
// 下载文件后缀
UIKIT_EXTERN NSString *const DownloadFileExtension;

/**********************************************
            下载任务存储字典字段信息
 
 注：添加一个新的字段需要 7 个步骤，
    请搜索关键字<DownloadTaskAddNewSaveItemTag>
 **********************************************/

/*< DownloadTaskAddNewSaveItemTag 01 >*/
// 元数据
UIKIT_EXTERN NSString *const DownloadTaskMetadataDefaultThumbnailURLKey;    // 默认缩略图下载地址 (iPad或iPhone只需存储需要的)
UIKIT_EXTERN NSString *const DownloadTaskMetadataThumbnailURLKey;           // 缩略图下载地址
UIKIT_EXTERN NSString *const DownloadTaskMetadataCategoryIDKey;             // 视频专辑ID
UIKIT_EXTERN NSString *const DownloadTaskMetadataVideoIDKey;                // 视频ID
UIKIT_EXTERN NSString *const DownloadTaskMetadataSiteKey;                   //视频来源
UIKIT_EXTERN NSString *const DownloadTaskMetadataOriginalM3u8UrlStringKey;  // 原画m3u8播放地址
UIKIT_EXTERN NSString *const DownloadTaskMetadataSuperM3u8UrlStringKey;     // 超清m3u8播放地址
UIKIT_EXTERN NSString *const DownloadTaskMetadataHighM3u8UrlStringKey;      // 高清m3u8播放地址
UIKIT_EXTERN NSString *const DownloadTaskMetadataMediumM3u8UrlStringKey;    // 标清m3u8播放地址
UIKIT_EXTERN NSString *const DownloadTaskMetadataLowMp4UrlStringKey;        // 流畅整段mp4下载地址
UIKIT_EXTERN NSString *const DownloadTaskMetadataCategoryTitleKey;  // 下载任务专辑标题
UIKIT_EXTERN NSString *const DownloadTaskMetadataVideoTitleKey;     // 下载任务视频标题
UIKIT_EXTERN NSString *const DownloadTaskMetadataReservedKey;       // 预留私有数据
UIKIT_EXTERN NSString *const DownloadTaskMetadataCateCodeKey;       // 视频一级分类ID
UIKIT_EXTERN NSString *const DownloadTaskMetadataIsTrailerKey;      // 是否是片花
UIKIT_EXTERN NSString *const DownloadTaskMetadataScoreKey;          // 评分
UIKIT_EXTERN NSString *const DownloadTaskMetadataHasAlbumInfoKey;   // 是否已经填充过剧集信息
UIKIT_EXTERN NSString *const DownloadTaskMetadataPhotoAlbumKey;     // 保存相册视频图片地址

// 保存路径
UIKIT_EXTERN NSString *const DownloadTaskSavePathVideoFileKey;          // 下载文件保存路径
UIKIT_EXTERN NSString *const DownloadTaskRelativeSavePathVideoFileKey;  // 下载任务视频文件存储相对路径
UIKIT_EXTERN NSString *const DownloadTaskRelativeSavePathVideoCacheKey; // 下载任务视频临时缓存文件存储相对路径

// 播放属性
UIKIT_EXTERN NSString *const DownloadTaskPlayInfoVideoDescriptionKey;       // 下载任务视频内容详情介绍
UIKIT_EXTERN NSString *const DownloadTaskPlayInfoVideoPlayOrderKey;         // 下载任务视频播放循序信息
UIKIT_EXTERN NSString *const DownloadTaskPlayInfoVideoHeadTimeLengthKey;    // 下载任务视频片头时长信息
UIKIT_EXTERN NSString *const DownloadTaskPlayInfoVideoTailTimeLengthKey;    // 下载任务视频片尾时长信息
UIKIT_EXTERN NSString *const DownloadTaskPlayInfoVideoTimeLengthKey;        // 下载任务视频时长信息
UIKIT_EXTERN NSString *const DownloadTaskPlayInfoVideoTypeIDKey;            // 下载任务视频类型ID
UIKIT_EXTERN NSString *const DownloadTaskPlayInfoVideoIsSerialKey;          // 视频是否是连载的
// 任务属性
UIKIT_EXTERN NSString *const DownloadTaskPropertyVideoFileTotalSizeKey;     // 下载任务视频文件总大小
UIKIT_EXTERN NSString *const DownloadTaskPropertyVideoDefinitionKey;        // 下载任务视频清晰度
UIKIT_EXTERN NSString *const DownloadTaskPropertyDownloadStateKey;          // 下载任务下载状态
UIKIT_EXTERN NSString *const DownloadTaskPropertyRunningStateKey;           // 下载任务运行状态
UIKIT_EXTERN NSString *const DownloadTaskPropertyDownloadURLListKey;        // 下载任务下载地址列表
UIKIT_EXTERN NSString *const DownloadTaskPropertyCurrentSegmentIndexKey;    // 下载任务下载地址列表中当前正在下载项序号
UIKIT_EXTERN NSString *const DownloadTaskPropertyCreatedTimeKey;            // 下载任务创建时间
UIKIT_EXTERN NSString *const DownloadTaskPropertyErrorCodeKey;              // 下载任务错误代码

// 版本兼容
UIKIT_EXTERN NSString *const DownloadTaskUpgradeIncompatibleLabelKey;       // 下载任务升级数据结构不兼容标记

/****************************
          调试日志输出
 ***************************/
#ifdef __DOWNLOAD_CENTER_DEBUG__
#define Log(fmt, args...); \
{ \
NSLog(@"%s@line:%d\n======>["fmt@"]", __FUNCTION__,__LINE__,##args); \
}
#else // __DOWNLOAD_CENTER_DEBUG__
#define Log(fmt, args...);
#endif // __DOWNLOAD_CENTER_DEBUG__

/****************************
        设备相关
 ***************************/

#define ISIPAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define PAD_OR_PHONE(a,b) (ISIPAD?(a):(b))
