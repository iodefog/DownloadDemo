//
//  DownloadManager+Observer.h
//  DownloadCenter
//
//  Created by yufei yan on 12-4-23.
//  Copyright (c) 2012年 SOHU. All rights reserved.
//

#import "SHDownloadManager.h"

/***********************************
       监听事件， 作出相应处理
 
 现已支持以下通知事件的监听和处理：
    网络变化
    程序进入后台
    程序进入前台
    程序启动
    分段任务合并状态变化
 
 原则：用户手动改变任意一个下载任务的状态
      并生效，则清空已保存的暂停任务列表
 ***********************************/
@interface SHDownloadManager (Observer)

// 注册监听通知，需要在UIApplication的application:didFinishLaunchingWithOptions:中调用
- (void)registerNotifications;
// 取消监听通知
- (void)unregisterNotifications;

@end
