//
//  MP4Box.m
//  MP4Box
//
//  Created by ke xu on 12-2-6.
//  Copyright (c) 2012年 sohu. All rights reserved.
//

#import "MP4Box.h"

@interface  MP4Box(private) 
- (BOOL)exportComposition:(AVMutableComposition *)composition toFilePath:(NSString *)filePath 
     isDeleteDownLoadFile:(BOOL)isDeleteDownLoad;
- (void)getFilePathArray:(NSString *)filePath;
- (void)removeExportFile:(NSString*)filePath;
- (void)removeMergeMp4File;
@end

#define CutEndVideoDataForScale 2

@implementation MP4Box

@synthesize videoStatus = _videoStatus;
@synthesize exportSession = _exportSession;
@synthesize filePathArray = _filePathArray;
@synthesize isExportting;
@synthesize userInfo;

- (id)initWithVideoStatus:(NSString *)status
{
    self = [super init];
    if (self) {
        // Initialization code
        bgTask = UIBackgroundTaskInvalid;
        self.videoStatus = status;
    }
    return self;
}

- (BOOL)mergeVideoWithFilePathArray:(NSString *)downLoadFilePath andExportFilePath:(NSString *)exportPath
               isDeleteDownLoadFile:(BOOL)isDeleteDownLoad {

    [self getFilePathArray:downLoadFilePath];
    AVMutableComposition* composition = [AVMutableComposition composition];
//    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo 
//                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
//    
//    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio 
//                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
    if ([self.filePathArray count] == 0 || exportPath == nil || self.isExportting == YES) {
        return NO;
    }
    
    BOOL needsClipDuration = floorf([[[UIDevice currentDevice] systemVersion] floatValue]) >= 5.0f;
    CMTime duration = kCMTimeZero;
    for (int i = 0; i < [self.filePathArray count]; i++) 
     {
         NSString *filePath = [self.filePathArray objectAtIndex:i];
         AVURLAsset* videoAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];
         CMTime addDuration = kCMTimeZero;
         CMTimeValue testValue = videoAsset.duration.value;
         
         // 判断ios 5.0以上版本手动截掉（取整截取尾部数据）尾部无音频的value，以解决ios 5.0以上版本合并后的视频音视频不同步的Bug
         // ios 5.0以下维持原来视频value不变
         // add by xuke@2012-03-07 
         if (needsClipDuration) {
             if (videoAsset.duration.timescale > CutEndVideoDataForScale) {
                 CMTimeScale scale = videoAsset.duration.timescale / CutEndVideoDataForScale;
                 testValue = videoAsset.duration.value / scale * scale;
             }
         }
         
         addDuration = CMTimeMake(testValue, videoAsset.duration.timescale);
         [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, addDuration) 
                              ofAsset:videoAsset 
                               atTime:duration 
                                error:nil];
         
         //        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, addDuration)
         //                                       ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
         //                                        atTime:duration
         //                                         error:nil];
         //        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, addDuration)
         //                                       ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0]
         //                                        atTime:duration
         //                                          error:nil];
         duration = CMTimeAdd(duration, addDuration); 
         [videoAsset release];
//         NSLog(@"%lld  %lld·%lld  %d", duration.value, 
//               duration.value / duration.timescale / 60, duration.value / duration.timescale % 60, 
//               duration.timescale);
     }
    return [self exportComposition:composition toFilePath:exportPath isDeleteDownLoadFile:isDeleteDownLoad];
}

- (void)cancelExport {
    
    [self.exportSession cancelExport];
    isExportting = NO;
}

- (BOOL)exportComposition:(AVMutableComposition *)composition toFilePath:(NSString *)exportPath 
     isDeleteDownLoadFile:(BOOL)isDeleteDownLoad{
    
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:exportPath] && [[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
        [self removeExportFile:exportPath];
    }
    
    if (self.videoStatus == nil) {
        self.videoStatus = AVAssetExportPresetPassthrough;
    }
    AVAssetExportSession *export = [[AVAssetExportSession alloc]
                                    initWithAsset:composition presetName:self.videoStatus];
    self.exportSession = export;
    [export release];
    
    if (nil == self.exportSession) return NO;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // configure export session  output with all our parameters
        self.exportSession.outputURL = [NSURL fileURLWithPath:exportPath]; // output path
        self.exportSession.outputFileType = AVFileTypeMPEG4;; // output file type
        self.exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, [composition duration]); // trim time range
        //    exportSession.audioMix = exportAudioMix; // fade in audio mix
        
        bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            // Clean up any unfinished task business by marking where you.
            // stopped or ending the task outright.
            [self cancelExport];
            if (bgTask != UIBackgroundTaskInvalid)
            {
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }
        }];
        
        // Start the long-running task and return immediately.
        // perform the export
        //NSDate *date = [NSDate date];
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            [self performSelectorOnMainThread:@selector(postStatusDidChangeNotification) withObject:nil waitUntilDone:NO];
            isExportting = NO;
            if (AVAssetExportSessionStatusCompleted == self.exportSession.status) {
                
                //NSLog(@"AVAssetExportSessionStatusCompleted");
                //NSLog(@"%f", [[NSDate date] timeIntervalSinceDate:date]);
                if (isDeleteDownLoad) {
                    [self removeMergeMp4File];
                    //[NSThread detachNewThreadSelector:@selector(removeMergeMp4File) toTarget:self withObject:nil];
                }
            } else if (AVAssetExportSessionStatusFailed == self.exportSession.status) {
                
                // a failure may happen because of an event out of your control
                // for example, an interruption like a phone call comming in
                // make sure and handle this case appropriately
                //NSLog(@"AVAssetExportSessionStatusFailed");
                [self removeExportFile:exportPath];
            } else if (AVAssetExportSessionStatusCancelled == self.exportSession.status) {
                [self removeExportFile:exportPath];
            }
            
            // Clean up the initiated background task to prevent the app from being killed by the system after 600s
            if (bgTask != UIBackgroundTaskInvalid)
            {
                [[UIApplication sharedApplication] endBackgroundTask:bgTask];
                bgTask = UIBackgroundTaskInvalid;
            }
            
        }];
    });

    return YES;
}

- (void)postStatusDidChangeNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kExporteStatusNotification
                                                        object:self];
}

- (void)removeMergeMp4File {
    
    NSString *filePath = [[self.filePathArray objectAtIndex:0] stringByDeletingLastPathComponent];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
        //NSLog(@"removeMp4File Error");
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
}

- (void)removeExportFile:(NSString*)exportPath {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:exportPath error:&error];
    if (error) {
        //NSLog(@"removeMp4File Error");
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:&error];
    }
}

//分段文件名
+ (NSString*)segmentFileNameAtIndex:(NSInteger)index
{
    return [NSString stringWithFormat:@"%d.mp4", index];
}

- (void)getFilePathArray:(NSString *)downLoadFilePath {
    
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:downLoadFilePath error:nil];
    NSMutableArray *pathArray = [[NSMutableArray alloc] init];
    for (NSUInteger n = 0; n < contents.count; n++) {
        NSString *path = [downLoadFilePath stringByAppendingPathComponent:[MP4Box segmentFileNameAtIndex:n]];
        [pathArray addObject:path];
    }
    self.filePathArray = pathArray;
    [pathArray release];
}

- (void)dealloc {
    
    self.videoStatus = nil;
    self.exportSession = nil;
    self.filePathArray = nil;
    self.userInfo = nil;
    
    [super dealloc];
}

@end
