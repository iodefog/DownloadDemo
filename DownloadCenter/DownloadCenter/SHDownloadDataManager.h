//
//  DownloadDataManager.h
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

/*******************************
    数据模型升级兼容逻辑
    DownloadTask列表的存盘与读取
 ******************************/

//#import "ConfigurationCenter.h"

@interface SHDownloadDataManager : NSObject

// 是否是非兼容版本下载任务信息
+ (BOOL)isIncompatibleTaskInfo:(NSDictionary*)info;
@end


/****************************
 iPad旧下载模块数据模型
 ***************************/

typedef enum {
    kSegmentDownloadStatusUnknown = 0,
    kSegmentDownloadRequestingDownloadList = 1,
    kSegmentDownloadStatusDownloading = 2,
    kSegmentDownloadStatusMerging = 3,
    kSegmentDownloadStatusFinished = 4
} SegmentDownloadStatus;

typedef enum {
    
	LOADED_SUCCES = 0,
	LOADED_SPACE,
    LOADED_INVALID,
    LOADED_REPEAT,
	LOADED_FINISHED,	//added by ybc 11-9-13
    LOADED_OVER
    
} loadedStatus;

#define cache_extension_pad           @"downloading"
#define downloaded_folder_pad         @"download"
#define DOWNLOAD_PLIST_PAD            @"download.plist"
#define DOWNLOAD_START                @"100"
#define DOWNLOAD_WAIT                 @"300"
#define DOWNLOAD_STOP                 @"500"
#define DOWNLOAD_FINISH               @"700"

#define kVideoPlayOrder				  @"playOrder"
#define kVideoAid                     @"video aid"
#define kVideoID                      @"video playId"
#define kVideoType                    @"videoType"
#define kIsTVVideo                    @"isTVVideo" 
#define kVideoTitle                   @"videoTitle"
#define kVideoAlbumTitle              @"subjectTitle"
#define kTitle						  @"title"
#define kVideoName					  @"videoName" //backwar compatability
#define kDownloadUrl                  @"downloadUrl"
#define kVideoUrl                     @"videoUrl"
#define kVideoLowUrl                  @"videoLowUrl"   // 低清视频 
#define kVideoLocalUrl                @"videoLocalUrl" // 低清下载最终文件本地保存路径
#define kSegmentVideoLocalUrl         @"segmentVideoLocalUrl" //超清或高清下载最终文件本地保存路径
#define kVideoUltraUrl                @"videoUltraUrl"
#define kVideo720PUrl                 @"720PUrl" //{ added cxt 2012-4-17 720P url
#define kVideoQuality                 @"videoQuality"
#define kPictureUrl                   @"picUrl"
#define kVerPictureUrl                @"verPicUrl"
#define kHorPictureUrl                @"horPicUrl"
#define kPicturePath                  @"picPath"
#define kPictureVerPath               @"picVerPath"
#define kPictureSuggestionPath        @"suggestionPicPath"
#define kPictureFocusPath			  @"focusPicPath"
#define kVideoDescription             @"videoDescription" 
#define kVideoUrlList                 @"vurlList"
#define kIsOriginal_StarVideo         @"isOriginal_StarVideo"
#define kIsNewsreelVideo              @"isIsNewsreelVideo"
#define kVideo_start_time             @"start_time" 
#define kVideo_end_time               @"end_time"
#define kDownloadStatus               @"downloadStatus"
#define kPercentage                   @"percentage"
#define kIntSize                      @"intSize"
#define	kVideoSizeKey				  @"tvFileLen10"
#define kSegmentVideoTotalSizeKey     @"fileSize"
#define kProgress                     @"progress"
#define kDownloadInfo                 @"downloadInfo"
#define kSegmentDownloadUrls          @"downloadUrls"
#define kDownloadQuality              @"downloadQuality"
#define kSegmentDownloadStatus        @"segmentDownloadStatus"
#define kSegmentDownloadIndex         @"segmentDownloadIndex"


/****************************
 iPhone旧下载模块数据模型
 ***************************/
typedef enum{
	DownloadWaiting=0,
	Downloading,
	DownloadPause,
	DownloadFail,
	DownloadFinish
}DownloadState;

typedef enum{
	DownloadTaskAddSuccess=0,
	DownloadURLIsNull,
    DownloadIPLimited,
	DownloadTaskExist,
	DownloadTaskFileNameExist,
	DownloadTaskDiskSpaceError,
	DownloadTaskMaxCountLimited
}DownloadError;

typedef enum{
	RequestNoError=0,
	RequestErrorURLChange
}RequestErrorType;

#define downloaded_folder_phone @"Download"
#define cache_extension_phone @"tmp"
#define Download_Mp4_Extension @"mp4"
#define Format_Download_Task_Name @"%d.mp4"

#define __Download_task_file_path @"Download_Task.plist"
#define __Download_VideoInfo @"Downlod_VideoInfo"
#define __Download_Create_Date @"Downlod_Create_Date"
#define __Download_Finish_Date @"Downlod_Finish_Date"
#define __Download_State @"Downlod_State"
#define __Download_FileName @"Downlod_FileName"
#define __Download_Temp_FileName @"Downlod_Temp_FileName"
#define __Download_ImageURL @"Download_ImageURL"
#define __Download_Total_Size @"Download_Total_Size"
#define __Download_Size @"Download_Size"
#define __Download_URL @"DownloadURL"
#define __Download_PlayId @"Download_PlayId"
#define __Download_SubjectId @"Download_SubjectId"
#define __Download_Old_Version_Id @"Old_Version_Id"
#define __Download_Task_Display_Name @"Task_Display_Name"
#define __Download_Gaoqing_URL @"Download_Gaoqing_URL"
#define __Download_Chaoqing_URL @"Download_Chaoqing_URL"
#define __Download_Diqing_URL @"Download_Diqing_URL"
#define __Download_Video_Description @"Download_Video_Description"
#define __Download_Video_Start_Time @"Download_Video_Start_Time"
#define __Download_Video_End_Time @"Download_Video_End_Time"
#define __Download_Play_Order @"Download_Play_Order"
#define __Download_Video_Type_Id @"Download_Video_Type_Id"
