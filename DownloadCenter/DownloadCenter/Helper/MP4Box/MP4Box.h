//
//  MP4Box.h
//  MP4Box
//
//  Created by ke xu on 12-2-6.
//  Copyright (c) 2012年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//注册状态通知返回的object 为self
#define kExporteStatusNotification @"kExporteStatusNotification"  

typedef enum {
	EXPORT_Unknown = AVAssetExportSessionStatusUnknown,
	EXPORT_Waiting = AVAssetExportSessionStatusWaiting,
    EXPORT_Exporting = AVAssetExportSessionStatusExporting,
    EXPORT_Completed = AVAssetExportSessionStatusCompleted,
	EXPORT_Failed = AVAssetExportSessionStatusFailed,	
    EXPORT_Cancelled = AVAssetExportSessionStatusCancelled
    
} exportStatus; //added by xuke 12-2-20

@interface MP4Box : UIView {
    
    NSString *_videoStatus;       //default AVAssetExportPresetPassthrough;
    AVAssetExportSession *_exportSession;
    NSArray *_filePathArray;
    
    BOOL isExportting;
    
    UIBackgroundTaskIdentifier  bgTask;
    
    id userInfo;
}

@property (nonatomic, retain) NSString *videoStatus;
@property (nonatomic, retain) AVAssetExportSession *exportSession;
@property (nonatomic, copy) NSArray *filePathArray;
@property (nonatomic, readonly) BOOL isExportting;
@property (nonatomic, retain) id userInfo;

//array合并所需视频的目录   path倒出的目录
- (BOOL)mergeVideoWithFilePathArray:(NSString *)filePath andExportFilePath:(NSString *)path 
               isDeleteDownLoadFile:(BOOL)isDeleteDownLoad;
- (id)initWithVideoStatus:(NSString *)status;//default AVAssetExportPresetPassthrough;
- (void)cancelExport;
- (void)postStatusDidChangeNotification;

//分段文件名
+ (NSString*)segmentFileNameAtIndex:(NSInteger)index;


@end
