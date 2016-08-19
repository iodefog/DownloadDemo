//
//  NSArray+sort.h
//  DownloadCenter
//
//  Created by MingLQ on 2013-09-03.
//  Copyright (c) 2013年 SOHU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (sort)

// 生成一个根据某个key来对保存在NSArray中的对象进行排序的数组
- (NSArray*)sortArrayByKey:(id)key inAscending:(BOOL)ascending;

@end
