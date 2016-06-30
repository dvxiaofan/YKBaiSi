//
//  XFTopic.m
//  XFBaisi
//
//  Created by xiaofans on 16/6/29.
//  Copyright © 2016年 xiaofan. All rights reserved.
//

#import "XFTopic.h"
#import "XFComment.h"



static NSDateFormatter *fmt_;
static NSCalendar *calendar_;
 
@implementation XFTopic

/**
 *  第一次使用XFTopic时调用一次
 */
+ (void)initialize {
    fmt_ = [[NSDateFormatter alloc] init];
    calendar_ = [NSCalendar xf_calendar];
}

/**
 *  重写 created_at get 方法
 *
 *  @return  计算好的时间间隔字符串
 */
- (NSString *)created_at {
    
    // 时间格式
    fmt_.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    // 发帖时间
    NSDate *createdAtDate = [fmt_ dateFromString:_created_at];
    
    if (createdAtDate.isThisYear) {     // 今年
        if (createdAtDate.isToday) {               // 今天
            // 手机当前时间
            NSDate *nowDate = [NSDate date];
            NSCalendarUnit unit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
            NSDateComponents *cmps = [calendar_ components:unit fromDate:createdAtDate toDate:nowDate options:0];
            
            if (cmps.hour >= 1) {           // 时间间隔 > 1小时
                return [NSString stringWithFormat:@"%zd小时前", cmps.hour];
            } else if (cmps.minute >= 1) {  // 小时 > 时间间隔 > 分钟
                return [NSString stringWithFormat:@"%zd分钟前", cmps.minute];
            } else {                        // 1 分钟 > 时间间隔
                return @"刚刚";
            }
        } else if (createdAtDate.isYesterday) {    // 昨天
             fmt_.dateFormat = @"昨天 HH:mm:ss";
            return [fmt_ stringFromDate:createdAtDate];
        } else {
            fmt_.dateFormat = @"MM-dd HH:mm:ss";
            return [fmt_ stringFromDate:createdAtDate];
        }
        
    } else {                            // 非今年
        return _created_at;
    }
}

@end
