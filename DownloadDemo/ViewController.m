//
//  ViewController.m
//  DownloadDemo
//
//  Created by LHL on 16/8/19.
//  Copyright © 2016年 lihongli. All rights reserved.
//

#import "ViewController.h"
#import "SHDownloadTask.h"
#import "SHDownloadConstances.h"
#import "SHDownloadManager.h"


@interface ViewController ()<DownloadManagerDelegate>{
    SHDownloadTask *_cDownloadTask;
    NSTimer *_timer;
}

@property (nonatomic, retain) NSMutableArray *taskArray;

@end

@implementation ViewController

- (void)dealloc {
    [[SHDownloadManager sharedInstance] setDelegate:nil];
}

- (void)setupTestDownloadTask {
    // 屌丝男士
    NSArray *vids = @[@"827799",
                      @"835658",
                      @"842888",
                      @"849719",
                      @"858368",
                      @"865938",
                      @"940087",
                      
                      @"1169394",
                      @"1178581",
                      @"1185234",
                      @"1205783",
                      @"1224845",
                      @"1233590"];
    //, @"745234", @"745237", @"745241", @"745246", @"745249", @"745255", @"745260", @"745265",  @"745270", @"745275", @"745278"
    // @"1324191", @"1701130", @"1701133", @"1701136", @"1701139", @"1701142",
    int i = 1;
    for (NSString *vid in vids) {
        SHDownloadTask *downloadTask = [[SHDownloadTask alloc] initWithVid:vid site:1];
        if (![[SHDownloadManager sharedInstance] hasTask:downloadTask]) {
            NSArray *libPathList = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString *downloadPath = [libPathList objectAtIndex:0];
            downloadTask.downloadBasePath = [downloadPath stringByAppendingString:[NSString stringWithFormat:@"/%d", i]];
            [self.taskArray addObject:downloadTask];
        }
        i++;
    }
    
    //    _cDownloadTask = [[SHDownloadTask alloc] initWithVid:@"745234" site:1];
    //    [[SHDownloadManager sharedInstance] addDownloadTask:_cDownloadTask];
}
- (IBAction)pauseDownloadHandle:(id)sender {
    [[SHDownloadManager sharedInstance] pauseAllDownloadTasks];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [libraryPaths firstObject];
    [SHDownloadManager setupDownloadStoreBasePath:libraryPath];
    
    self.taskArray = (NSMutableArray *)[[SHDownloadManager sharedInstance] getAllDownloadTasks];
    if (!self.taskArray) {
        self.taskArray = [NSMutableArray array];
    }
    for (SHDownloadTask *task in self.taskArray) {
        NSLog(@"base path : %@, file path : %@", task.downloadBasePath, task.downloadFilePath);
    }
    [self setupTestDownloadTask];

}

- (IBAction)startDownload:(id)sender {
    [[SHDownloadManager sharedInstance] setDelegate:self];
    [[SHDownloadManager sharedInstance] setAllowMultiTask:YES];
    [[SHDownloadManager sharedInstance] setMaxTaskNumber:3];
    [[SHDownloadManager sharedInstance] addNewDownloadTasks:self.taskArray];
    [[SHDownloadManager sharedInstance] startAllDownloadTasks];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 下载回调

/**
 *  任务下载状态变化回调
 *
 *  @param downloadManager
 *  @param downloadTask
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didUpdateStatusOfDownloadTask:(SHDownloadTask *)downloadTask {
    NSLog(@"didUpdateStatusOfDownloadTask");
}

/**
 *  任务下载进度变化回调
 *
 *  @param downloadManager
 *  @param downloadTask
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didUpdateDownloadProgressOfDownloadTask:(SHDownloadTask *)downloadTask {
    NSLog(@"速度 : %lld, 已下载 : %lld, 总大小 : %lld, 路径 : %@ ", downloadTask.downloadedBytesPerSecond, downloadTask.downloadedSize, downloadTask.totalSize , downloadTask.downloadFilePath);
    
}

/**
 *  添加了新任务回调
 *
 *  @param downloadManager
 *  @param downloadTask
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didAddOneNewDownloadTask:(SHDownloadTask *)downloadTask {
    NSLog(@"didAddOneNewDownloadTask :: ");
}

/**
 *  有任务被删除回调
 */
- (void)downloadManagerDidRemoveDownloadTasks {
    NSLog(@"downloadManagerDidRemoveDownloadTasks :: ");
}

/**
 *  任务列表状态发生变化
 *
 *  @param downloadManager
 *  @param downloadTasks
 */
- (void)downloadManager:(SHDownloadManager *)downloadManager didUpdateStatusOfDownloadTasks:(NSArray *)downloadTasks {
    NSLog(@"didUpdateStatusOfDownloadTasks :: ");
}

@end
