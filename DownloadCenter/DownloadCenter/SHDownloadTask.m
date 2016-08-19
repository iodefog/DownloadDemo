//
//  DownloadTask.m
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadTask_Internal.h"
//#import "ConfigurationCenter.h"
//#import "DataCenterHeaders.h"
//#import "UrlFormats.h"
#import "SHDownloadManager+Helper.h"
#import "SHDownloadManager_Internal.h"
#import "ASIHttpRequest.h"
//#import "PermanentDataCache.h"
//#import "MAAlbumItem.h"

// 高清，超请下载地址模板
NSString *const DownloadUrlTemplate = @"%@/client/tv/downloadUrl.action?subjectId=%@&playId=%@&type=%d";

@implementation SHDownloadTask

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone {
    /*< DownloadTaskAddNewSaveItemTag 05 >*/

    SHDownloadTask *copy = [[[self class] allocWithZone:zone] init];
    copy.vid = self.vid;
    copy.aid = self.aid;
    copy.site = self.site;
    copy.defaultThumbnailURL = self.defaultThumbnailURL;
    copy.thumbnailURL = self.thumbnailURL;
    copy.highM3u8UrlString = self.highM3u8UrlString;
    copy.lowMp4UrlString = self.lowMp4UrlString;
    copy.mediumM3u8UrlString = self.mediumM3u8UrlString;
    copy.originalM3u8UrlString = self.originalM3u8UrlString;
    copy.superM3u8UrlString = self.superM3u8UrlString;
    copy.categoryTitle = self.categoryTitle;
    copy.videoTitle = self.videoTitle;
    copy.reserved = self.reserved;
    copy.cateCode = self.cateCode;
    copy.isTrailer = self.isTrailer;
    copy.score = self.score;
    
    copy.videoTypeID = self.videoTypeID;
    copy.videoTailTimeLength = self.videoTailTimeLength;
    copy.videoHeadTimeLength = self.videoHeadTimeLength;
    copy.videoTimeLength = self.videoTimeLength;
    copy.videoPlayOrder = self.videoPlayOrder;
    copy.videoDescription = self.videoDescription;
    copy.isSerial = self.isSerial;
    
    copy.runningState = self.runningState;
    copy.downloadURLs = self.downloadURLs;
    copy.videoDefinition = self.videoDefinition;
    copy.currentSegmentIndex = self.currentSegmentIndex;
    copy.downloadState = self.downloadState;
    copy.createdTime = self.createdTime;
    copy.errorCode = self.errorCode;
    
    copy.downloadBasePath = self.downloadBasePath;
    copy.relativeSavePathVideoCache = self.relativeSavePathVideoCache;
    copy.relativeSavePathVideoFile = self.relativeSavePathVideoFile;
    
    copy.upgradeIsIncompatible = self.upgradeIsIncompatible;
    copy.didDownloadPhotos = self.didDownloadPhotos;
    copy.isDownloadingPhotos = self.isDownloadingPhotos;
    copy.musicAlbumItemsArray = self.musicAlbumItemsArray;

    return copy;
}

#pragma mark - NSObject
- (id)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

- (id)initWithVid:(NSString *)vid site:(SHVideoSiteType)site {
    self = [self init];
    if (self) {
        self.vid = vid;
        self.site = site;
    }
    return self;
}

- (void)dealloc {
    /*< DownloadTaskAddNewSaveItemTag 06 >*/
//    [[DataCenter sharedCenter] cancelDataRequest:self];

    self.vid = nil;
    self.aid = nil;
    self.defaultThumbnailURL = nil;
    self.thumbnailURL = nil;
    self.highM3u8UrlString = nil;
    self.lowMp4UrlString = nil;
    self.mediumM3u8UrlString = nil;
    self.originalM3u8UrlString = nil;
    self.superM3u8UrlString = nil;
    self.categoryTitle = nil;
    self.videoTitle = nil;
    self.reserved = nil;
    self.cateCode = nil;
    
    self.videoTypeID = nil;
    self.videoTailTimeLength = nil;
    self.videoHeadTimeLength = nil;
    self.videoTimeLength = nil;
    self.videoPlayOrder = nil;
    self.videoDescription = nil;
    
    self.downloadURLs = nil;
    self.createdTime = nil;
    
    self.downloadBasePath = nil;
    self.relativeSavePathVideoCache = nil;
    self.relativeSavePathVideoFile = nil;
    
    [self.timerForCalculateSpeed invalidate];
    self.timerForCalculateSpeed = nil;
    self.lastDateForCalculateSpeed = nil;

    self.httpRequest = nil;
    self.musicAlbumItemsArray = nil;
    [super dealloc];
}

- (NSString*)relativeSavePathVideoFile {
    // 下载文件最终保存为 <aid>_<vid>.<file_extension>
    NSString *filePath;
    if (self.upgradeIsIncompatible) {
        filePath = self->_relativeSavePathVideoFile;
    } else {
        filePath = [NSString stringWithFormat:@"%@_%@.%@", self.aid, self.vid, DownloadFileExtension];
    }
    return filePath;
}

- (NSString*)relativeSavePathVideoCache {
    // 下载缓存文件保存为 relativeDownloadPath.<cachefile_extension>
    NSString *filePath;
    if (self.upgradeIsIncompatible) {
        filePath = self->_relativeSavePathVideoCache;
    } else {
        filePath = [NSString stringWithFormat:@"%@.%@", self.relativeDownloadPath, DownloadCacheFileExtension];
    }
    return filePath;
}

- (UInt64)downloadedSize {
    UInt64 downloadedSize = 0;
    if (self.downloadState == SHDownloadTaskStateCompleted) {
        downloadedSize = self.totalSize;
    } else {
        // 分段文件夹大小
        if ([self isMultiSegment]) {
            downloadedSize += [SHDownloadManager caculateSizeOfPath:[self.downloadStoreBasePath stringByAppendingPathComponent:[[self relativeDownloadPath] stringByDeletingLastPathComponent]]];
        } else {
            downloadedSize += [SHDownloadManager caculateSizeOfPath:[self downloadFilePath]];
        }
    }
    return downloadedSize;
}

// 是否需要请求下载列表
- (BOOL)needRequestURLListForTask {
    BOOL needRequestTaskURLList = YES;
    if (self.videoDefinition == kVideoQualityLow) { // 兼容下载低清视频时使用单段的mp4
        if (self.runningState != DownloadTaskRunningStateRequestingTaskInfo && self.downloadURLs == nil) {
            // 已经开始下载的，且没有使用分段下载的
            // 还未开始下载的使用新的规则，采用分段下载
            needRequestTaskURLList = NO;
        }
    }
    return needRequestTaskURLList;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"《%@》videoId:%@|downloadState:%d|runningState:%d|errorCode:%d|definition:%d|downloadURLs:%@|segmentCur:%d|totalSize:%llu|downloadSize:%llu", self.videoTitle, self.vid, self.downloadState, self.runningState, self.errorCode, self.videoDefinition, self.downloadURLs, self.currentSegmentIndex, self.totalSize, self.downloadedSize];
}

#pragma mark - 数据存储结构转换
- (NSDictionary*)toDictionary {
    /*< DownloadTaskAddNewSaveItemTag 07 >*/

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObjectOrNil:self.vid forKey:DownloadTaskMetadataVideoIDKey];
    [dict setObjectOrNil:self.aid forKey:DownloadTaskMetadataCategoryIDKey];
    [dict setInteger:self.site forKey:DownloadTaskMetadataSiteKey];
    
    [dict setObjectOrNil:self.superM3u8UrlString forKey:DownloadTaskMetadataSuperM3u8UrlStringKey];
    [dict setObjectOrNil:self.highM3u8UrlString forKey:DownloadTaskMetadataHighM3u8UrlStringKey];
    [dict setObjectOrNil:self.mediumM3u8UrlString forKey:DownloadTaskMetadataMediumM3u8UrlStringKey];
    [dict setObjectOrNil:self.lowMp4UrlString forKey:DownloadTaskMetadataLowMp4UrlStringKey];
    [dict setObjectOrNil:self.defaultThumbnailURL forKey:DownloadTaskMetadataDefaultThumbnailURLKey];
    [dict setObjectOrNil:self.thumbnailURL forKey:DownloadTaskMetadataThumbnailURLKey];
    [dict setObjectOrNil:self.originalM3u8UrlString forKey:DownloadTaskMetadataOriginalM3u8UrlStringKey];
    [dict setObjectOrNil:self.categoryTitle forKey:DownloadTaskMetadataCategoryTitleKey];
    [dict setObjectOrNil:self.videoTitle forKey:DownloadTaskMetadataVideoTitleKey];
    [dict setObjectOrNil:self.reserved forKey:DownloadTaskMetadataReservedKey];
    [dict setObjectOrNil:self.cateCode forKey:DownloadTaskMetadataCateCodeKey];
    [dict setObjectOrNil:[NSNumber numberWithBool:self.isTrailer] forKey:DownloadTaskMetadataIsTrailerKey];
    [dict setObjectOrNil:[NSNumber numberWithFloat:self.score] forKey:DownloadTaskMetadataScoreKey];
    
    [dict setObjectOrNil:self.videoDescription forKey:DownloadTaskPlayInfoVideoDescriptionKey];
    [dict setObjectOrNil:self.videoHeadTimeLength forKey:DownloadTaskPlayInfoVideoHeadTimeLengthKey];
    [dict setObjectOrNil:self.videoTailTimeLength forKey:DownloadTaskPlayInfoVideoTailTimeLengthKey];
    [dict setObjectOrNil:self.videoTimeLength forKey:DownloadTaskPlayInfoVideoTimeLengthKey];
    [dict setObjectOrNil:self.videoPlayOrder forKey:DownloadTaskPlayInfoVideoPlayOrderKey];
    [dict setObjectOrNil:self.videoTypeID forKey:DownloadTaskPlayInfoVideoTypeIDKey];
    [dict setObjectOrNil:[NSNumber numberWithBool:self.isSerial] forKey:DownloadTaskPlayInfoVideoIsSerialKey];

    [dict setObjectOrNil:[NSNumber numberWithInt:self.downloadState] forKey:DownloadTaskPropertyDownloadStateKey];
    [dict setObjectOrNil:[NSNumber numberWithInt:self.runningState] forKey:DownloadTaskPropertyRunningStateKey];
    [dict setObjectOrNil:[NSNumber numberWithInt:self.currentSegmentIndex] forKey:DownloadTaskPropertyCurrentSegmentIndexKey];
    [dict setObjectOrNil:[NSNumber numberWithUnsignedLongLong:self.totalSize] forKey:DownloadTaskPropertyVideoFileTotalSizeKey];
    [dict setObjectOrNil:[NSNumber numberWithInt:self.videoDefinition] forKey:DownloadTaskPropertyVideoDefinitionKey];
    [dict setObjectOrNil:self.downloadURLs forKey:DownloadTaskPropertyDownloadURLListKey];
    [dict setObjectOrNil:self.createdTime forKey:DownloadTaskPropertyCreatedTimeKey];
    [dict setObjectOrNil:[NSNumber numberWithInt:self.errorCode] forKey:DownloadTaskPropertyErrorCodeKey];
    
    [dict setObjectOrNil:self.downloadStoreBasePath forKey:DownloadTaskSavePathVideoFileKey];
    [dict setObjectOrNil:self.relativeSavePathVideoFile forKey:DownloadTaskRelativeSavePathVideoFileKey];
    [dict setObjectOrNil:self.relativeSavePathVideoCache forKey:DownloadTaskRelativeSavePathVideoCacheKey];

    [dict setObjectOrNil:[NSNumber numberWithBool:self.upgradeIsIncompatible] forKey:DownloadTaskUpgradeIncompatibleLabelKey];
    
    return dict;
}

- (id)abstractObjectWithClass:(Class)targetClass fromDictionary:(NSDictionary*)dictionary byKey:(id)key {
    id target = nil;
    id source = [dictionary objectForKey:key];
    if (nil != source && [source isKindOfClass:targetClass]) {
        target = source;
    }
    return target;
}

- (void)abstractIntegerNumber:(NSInteger*)target fromDictionary:(NSDictionary*)dictionary byKey:(id)key {
    id source = [dictionary objectForKey:key];
    if (nil != source && [source isKindOfClass:[NSNumber class]]) {
        *target = [(NSNumber*)source intValue];
    }
}

- (void)abstractUInt64:(UInt64*)target fromDictionary:(NSDictionary*)dictionary byKey:(id)key {
    id source = [dictionary objectForKey:key];
    if (nil != source && [source isKindOfClass:[NSNumber class]]) {
        *target = [(NSNumber*)source unsignedLongLongValue];
    }
}

- (void)abstractBoolNumber:(BOOL *)target fromDictionary:(NSDictionary *)dictionary byKey:(id)key {
    id source = [dictionary objectForKey:key];
    if (nil != source && [source isKindOfClass:[NSNumber class]]) {
        *target = [(NSNumber*)source boolValue];
    }
}

- (void)abstractFloatNumber:(CGFloat *)target fromDictionary:(NSDictionary *)dictionary byKey:(id)key {
    id source = [dictionary objectForKey:key];
    if (nil != source && [source isKindOfClass:[NSNumber class]]) {
        *target = [(NSNumber*)source floatValue];
    }
}

// 从存储字典中生成一个任务
+ (SHDownloadTask *)taskFromDictionary:(NSDictionary *)dictionary {
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    /*< DownloadTaskAddNewSaveItemTag 08 >*/
    SHDownloadTask *task = [SHDownloadTask new];
    if (task == nil) {
        return nil;
    }
    task.vid = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataVideoIDKey];
    task.aid = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataCategoryIDKey];
    [task abstractIntegerNumber:(NSInteger*)&task->_site fromDictionary:dictionary byKey:DownloadTaskMetadataSiteKey];

    task.superM3u8UrlString = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataSuperM3u8UrlStringKey];
    task.highM3u8UrlString = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataHighM3u8UrlStringKey];
    task.mediumM3u8UrlString = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataMediumM3u8UrlStringKey];
    task.lowMp4UrlString = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataLowMp4UrlStringKey];
    task.originalM3u8UrlString = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataOriginalM3u8UrlStringKey];
    task.defaultThumbnailURL = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataDefaultThumbnailURLKey];
    task.thumbnailURL = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataThumbnailURLKey];
    task.categoryTitle = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataCategoryTitleKey];
    task.videoTitle = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataVideoTitleKey];
    task.reserved = [task abstractObjectWithClass:[NSMutableDictionary class] fromDictionary:dictionary byKey:DownloadTaskMetadataReservedKey];
    task.cateCode = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskMetadataCateCodeKey];
    [task abstractBoolNumber:(BOOL*)&task->_isTrailer fromDictionary:dictionary byKey:DownloadTaskMetadataIsTrailerKey];
    [task abstractFloatNumber:(CGFloat*)&task->_score fromDictionary:dictionary byKey:DownloadTaskMetadataScoreKey];
    
    task.videoTypeID = [task abstractObjectWithClass:[NSNumber class] fromDictionary:dictionary byKey:DownloadTaskPlayInfoVideoTypeIDKey];
    task.videoPlayOrder = [task abstractObjectWithClass:[NSNumber class] fromDictionary:dictionary byKey:DownloadTaskPlayInfoVideoPlayOrderKey];
    task.videoDescription = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskPlayInfoVideoDescriptionKey];
    task.videoTimeLength = [task abstractObjectWithClass:[NSNumber class] fromDictionary:dictionary byKey:DownloadTaskPlayInfoVideoTimeLengthKey];
    task.videoHeadTimeLength = [task abstractObjectWithClass:[NSNumber class] fromDictionary:dictionary byKey:DownloadTaskPlayInfoVideoHeadTimeLengthKey];
    task.videoTailTimeLength = [task abstractObjectWithClass:[NSNumber class] fromDictionary:dictionary byKey:DownloadTaskPlayInfoVideoTailTimeLengthKey];
    [task abstractBoolNumber:(BOOL*)&task->_isSerial fromDictionary:dictionary byKey:DownloadTaskPlayInfoVideoIsSerialKey];

    [task abstractIntegerNumber:(NSInteger*)&task->_runningState fromDictionary:dictionary byKey:DownloadTaskPropertyRunningStateKey];
    [task abstractIntegerNumber:(NSInteger*)&task->_downloadState fromDictionary:dictionary byKey:DownloadTaskPropertyDownloadStateKey];
    task.downloadURLs = [task abstractObjectWithClass:[NSArray class] fromDictionary:dictionary byKey:DownloadTaskPropertyDownloadURLListKey];
    [task abstractIntegerNumber:(NSInteger*)&task->_currentSegmentIndex fromDictionary:dictionary byKey:DownloadTaskPropertyCurrentSegmentIndexKey];
    [task abstractIntegerNumber:(NSInteger*)&task->_videoDefinition fromDictionary:dictionary byKey:DownloadTaskPropertyVideoDefinitionKey];
    [task abstractUInt64:(UInt64*)&task->_totalSize fromDictionary:dictionary byKey:DownloadTaskPropertyVideoFileTotalSizeKey];
    task.createdTime = [task abstractObjectWithClass:[NSNumber class] fromDictionary:dictionary byKey:DownloadTaskPropertyCreatedTimeKey];
    [task abstractIntegerNumber:(NSInteger*)&task->_errorCode fromDictionary:dictionary byKey:DownloadTaskPropertyErrorCodeKey];

    task.downloadBasePath = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskSavePathVideoFileKey];
    task.relativeSavePathVideoCache = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskRelativeSavePathVideoCacheKey];
    task.relativeSavePathVideoFile = [task abstractObjectWithClass:[NSString class] fromDictionary:dictionary byKey:DownloadTaskRelativeSavePathVideoFileKey];

    [task abstractBoolNumber:(BOOL*)&task->_upgradeIsIncompatible fromDictionary:dictionary byKey:DownloadTaskUpgradeIncompatibleLabelKey];
    
    return [task autorelease];
}

#pragma mark - internal
// 是否是分段任务
- (BOOL)isMultiSegment {
    BOOL isSegmented = NO;
    
    if (self.downloadURLs && self.downloadURLs.count > 1) {
        isSegmented = YES;
    }
    return isSegmented;
}

// 下载文件保存相对路径
- (NSString*)relativeDownloadPath {
    NSString *urlString;
    
    if ([self isMultiSegment]) {
        if ([self upgradeIsIncompatible]) {
            urlString = [self.relativeSavePathVideoCache stringByDeletingLastPathComponent];
        } else {
            // 下载分段文件保存名 <aid>_<vid>/<segment_file_name>
            urlString = [NSString stringWithFormat:@"%@_%@", self.aid, self.vid];
        }
        // 创建临时目录
        [SHDownloadManager makeDirectoryWithBase:self.downloadStoreBasePath andSub:urlString createIfNotExist:NO];
        
        NSInteger segmentIndex = self.currentSegmentIndex;
        NSInteger maxSegmentIndex = self.downloadURLs.count - 1;
        segmentIndex = segmentIndex > maxSegmentIndex ? maxSegmentIndex : segmentIndex;
        
        urlString = [urlString stringByAppendingPathComponent:[MP4Box segmentFileNameAtIndex:segmentIndex]];
    } else {
        urlString = self.relativeSavePathVideoFile;
    }
    
    return urlString;
}

// 文件下载地址
- (NSURL*)downloadURL {
    NSString *urlString;
    if (self.runningState == DownloadTaskRunningStateRequestingTaskInfo) { // 获取下载任务列表
        urlString = [NSString stringWithFormat:URL_Format_VideoInfo_Iphone, OpenAPIUrlBase, self.vid, self.site,@"api_key=695fe827ffeb7d74260a813025970bd5&plat=3&partner=130017&sver=1.0&poid=16"];
//                     [ConfigurationCenter sharedCenter].getOpenAPIParamsString];
    } else { // 获取下载文件地址
        if ([self needRequestURLListForTask]) {
            urlString = [self.downloadURLs objectOrNilAtIndex:self.currentSegmentIndex];
        } else {
            urlString = self.lowMp4UrlString;
        }
    }
    return [NSURL URLWithString:urlString];
}

// 错误是否可恢复
- (BOOL)canBeRecovered {
    BOOL canTaskBeRecovered = YES;
    if (self.errorCode == SHDownloadTaskErrorFileBroken ||
        self.errorCode == SHDownloadTaskErrorURLInvalid) {
        canTaskBeRecovered = NO;
    }
    return canTaskBeRecovered;
}

// 错误是否可重试
- (BOOL)canBeRetried {
    BOOL canTaskBeRetried = NO;
    if ([self canBeRecovered]) {
        if (self.remainFailedRetryTimes > 0) {
            canTaskBeRetried = YES;
        }
    }
    return canTaskBeRetried;
}

// 重置重试状态
- (void)resetRetryState {
    self.remainFailedRetryTimes = MaxFailedRetryTimes;
}

// 重试下载任务
- (void)retry:(SEL)operation onObject:(id)object {
    Log(@"重试下载任务");
    if (operation && [object respondsToSelector:operation]) {
        self.remainFailedRetryTimes--;
        [object performSelector:operation withObject:self];
    }
}

//暂停
- (void)pause {
    [self cancel];
    
    // 重置重试次数
    [self resetRetryState];
    
    self.downloadState = SHDownloadTaskStatePaused;
    
    [self stopCalculatingSpeed];
}

// 取消
- (void)cancel {
    if (self.httpRequest != nil) {
        [self.httpRequest clearDelegatesAndCancel];
        self.httpRequest = nil;
    }
}

// 已下载数据是否完整
- (BOOL)isDownloadedDataIntact {
    BOOL isDownloadedDataIntact = YES;
    
    // 已完成的任务
    if (self.downloadState == SHDownloadTaskStateCompleted) { // 检查最终文件
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.downloadFilePath])
            isDownloadedDataIntact = NO;
    } else {
        // 检查分段下载文件
        NSInteger downloadedSegmentNum = 0;
        if ([self isMultiSegment]) {
            if (self.runningState == DownloadTaskRunningStateDownloading) { // 下载过程中
                downloadedSegmentNum = self.currentSegmentIndex;
            } else if (self.runningState == DownloadTaskRunningStateMerging) { // 合并分段时
                downloadedSegmentNum = self.downloadURLs.count;
            }
        }
        
        // 已有下载完成的分段
        if (downloadedSegmentNum > 0) {
            for (int i = 0; i < downloadedSegmentNum; ++i) {
                NSString *cacheFilePath = [self.downloadStoreBasePath stringByAppendingPathComponent:[[[self relativeDownloadPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[MP4Box segmentFileNameAtIndex:i]]];
                if (![[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath]) {
                    isDownloadedDataIntact = NO;
                }
            }
        }
    }
    
    return isDownloadedDataIntact;
}

// 删除下载数据
- (void)eraseDownloadedData {
    // 暂停任务
    if (self.downloadState == SHDownloadTaskStateRunning) {
        [self pause];
    }
    // 移除缓存文件
    [self eraseCachedData];
    // 移除已完成文件
    [self eraseTargetFile];
 }

// 删除下载缓存数据
- (void)eraseCachedData {
    // 缓存文件保存路径
    NSString *cacheFileSaveDoc = [self.downloadStoreBasePath stringByAppendingPathComponent:[self.relativeDownloadPath stringByDeletingLastPathComponent]];
    // 缓存文件路径不是下载根目录，判断为有分段文件，需要删除缓存文件夹
    if (![cacheFileSaveDoc isEqualToString:self.downloadStoreBasePath])
        [[NSFileManager defaultManager] removeItemAtPath:cacheFileSaveDoc error:nil];
//    // 移除缓存文件
//    [[NSFileManager defaultManager] removeItemAtPath:self.downloadFilePath error:nil];
}

// 删除下载任务目标文件
- (void)eraseTargetFile {
    // 移除已完成文件
    [[NSFileManager defaultManager] removeItemAtPath:self.downloadFilePath error:nil];
}

// 重置
- (void)reset {
    self.remainFailedRetryTimes = MaxFailedRetryTimes;
    self.remainMergeRetryTimes = MaxMergeRetryTimes;
    self.runningState = DownloadTaskRunningStateRequestingTaskInfo;
    self.downloadState = SHDownloadTaskStatePaused;
    self.errorCode = SHDownloadTaskNoError;
    self.currentSegmentIndex = 0;
    self.totalSize = 0;
    self.expectedTotalSize = 0;
    self.estimatedTotalSize = 0;
}

// 获取视频特定清晰度的分段下载请求地址
- (NSString*)segmentRequestURL:(VideoQuality)videoQuality {
    NSString *urlString = nil;
    
    NSInteger downloadTypeID = DownloadVideoQualityTypeHigh;
    switch (videoQuality) {
        case kVideoQuality720P:
            downloadTypeID = DownloadVideoQualityTypeOriginal;
            break;
        case kVideoQualityUltra:
            downloadTypeID = DownloadVideoQualityTypeSuper;
            break;
        case kVideoQualityLow:
            downloadTypeID = DownloadVideoQualityTypeMedium;
            break;
        case kVideoQualityHigh:
        default:
            downloadTypeID = DownloadVideoQualityTypeHigh;
            break;
    }
    
    urlString = [NSString stringWithFormat:DownloadUrlTemplate,UrlBase_yule, self.aid, self.vid, downloadTypeID];
    
    return urlString;
}

#pragma mark - 下载任务保存路径
- (NSString *)downloadStoreBasePath {
    if (self.downloadBasePath) {
        return self.downloadBasePath;
    }
    return [SHDownloadManager downloadStoreBasePath];
}

// 下载任务视频文件存储路径
- (NSString*)downloadFilePath {
    return [self.downloadBasePath stringByAppendingPathComponent:self.relativeSavePathVideoFile];
}

#pragma mark - 下载任务比较方法
- (BOOL)isEqualTo:(SHDownloadTask *)task {
    BOOL isEqual = NO;
    if (task == nil || task.vid == nil) {
        return NO;
    }
    if ([self.vid isEqualToString:task.vid]) {
        isEqual = YES;
    }
    return isEqual;
}

// 属于统一专辑
- (BOOL)doesBelongToSameAlbum:(SHDownloadTask *)task {
    BOOL isEqual = NO;
    if (task == nil || task.aid == nil) {
        return NO;
    }
    if ([self.aid isEqualToString:task.aid]) {
        isEqual = YES;
    }
    return isEqual;
}

#pragma mark - 任务属性判定
// 下载任务必要信息是否完备
- (BOOL)isValid {
    BOOL isValid = NO;
    if (self.vid != nil && [self.vid intValue] != 0 &&
        self.videoTitle != nil && ![self.videoTitle isWhitespaceAndNewlines] &&
        self.aid != nil && [self.aid intValue] != 0) {
        isValid = YES;
    }
    return isValid;
}

- (BOOL)shouldShowAsSingalVideo {
    if ([self.aid intValue] == -1 
        || [self.videoTypeID intValue]== 1300 //kVideoType_NewsTV
        || [self.videoTypeID intValue]== 9//kVideoType_NewsCenter
        || [self.videoTypeID intValue]== 9001 //kVideoType_Blog
        || [self.videoTypeID intValue]== 25 //kVideoType_News
        || [self.videoTypeID intValue]== 13 //kVideoType_EntertainNews
        || [self.videoTypeID intValue]== 5 //KVideoType_Match
        || self.isTrailer) {
        return YES;
    }
    return NO;
}

@end


@implementation SHDownloadTask (Util)

- (void)fireCalculatingSpeed {
    if (self.timerForCalculateSpeed) {
        [self.timerForCalculateSpeed invalidate];
        self.timerForCalculateSpeed = nil;
    }
    
    self.lastDateForCalculateSpeed = [NSDate date];
    self.timerForCalculateSpeed = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(triggerTimerForCalculateSpeed:) userInfo:nil repeats:YES];
}

- (void)stopCalculatingSpeed {
    if (self.timerForCalculateSpeed) {
        [self.timerForCalculateSpeed invalidate];
        self.timerForCalculateSpeed = nil;
    }
    
    self.downloadedBytesForCalculateSpeed = 0;
    self.downloadedBytesPerSecond = 0;
    self.lastDateForCalculateSpeed = nil;
}

- (void)triggerTimerForCalculateSpeed:(NSTimer *)timer {
	if (timer == self.timerForCalculateSpeed) {
        NSDate *nowDate = [NSDate date];

        self.downloadedBytesPerSecond = self.downloadedBytesForCalculateSpeed / [nowDate timeIntervalSinceDate:self.lastDateForCalculateSpeed];
        self.downloadedBytesForCalculateSpeed = 0;
        self.lastDateForCalculateSpeed = nowDate;
	}
}

@end
