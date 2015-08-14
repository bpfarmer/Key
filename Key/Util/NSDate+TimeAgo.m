//
//  NSDate+TimeAgo.m
//  Key
//
//  Created by Brendan Farmer on 8/13/15.
//  Copyright (c) 2015 Brendan Farmer. All rights reserved.
//

#import "NSDate+TimeAgo.h"

@implementation NSDate (TimeAgo)

#define SECOND  1
#define MINUTE  (SECOND * 60)
#define HOUR    (MINUTE * 60)
#define DAY     (HOUR   * 24)
#define WEEK    (DAY    * 7)
#define MONTH   (DAY    * 31)
#define YEAR    (DAY    * 365.24)

- (NSString *)formattedAsTimeAgo {
    NSDate *now = [NSDate date];
    NSTimeInterval secondsSince = -(int)[self timeIntervalSinceDate:now];

    if(secondsSince < 0)
        return @"In The Future";
    
    if(secondsSince < MINUTE)
        return @"Just now";
    
    if(secondsSince < HOUR)
        return [self formatMinutesAgo:secondsSince];

    if([self isSameDayAs:now])
        return [self formatAsToday:secondsSince];

    if([self isYesterday:now])
        return [self formatAsYesterday];

    if([self isLastWeek:secondsSince])
        return [self formatAsLastWeek];
    
    if([self isLastMonth:secondsSince])
        return [self formatAsLastMonth];
    
    if([self isLastYear:secondsSince])
        return [self formatAsLastYear];
    
    return [self formatAsOther];
    
}

- (BOOL)isSameDayAs:(NSDate *)comparisonDate {
    NSDateFormatter *dateComparisonFormatter = [[NSDateFormatter alloc] init];
    [dateComparisonFormatter setDateFormat:@"yyyy-MM-dd"];
    return [[dateComparisonFormatter stringFromDate:self] isEqualToString:[dateComparisonFormatter stringFromDate:comparisonDate]];
}

- (BOOL)isYesterday:(NSDate *)now {
    return [self isSameDayAs:[now dateBySubtractingDays:1]];
}

- (NSDate *) dateBySubtractingDays:(NSInteger)numDays {
    NSTimeInterval aTimeInterval = [self timeIntervalSinceReferenceDate] + DAY * -numDays;
    NSDate *newDate = [NSDate dateWithTimeIntervalSinceReferenceDate:aTimeInterval];
    return newDate;
}


- (BOOL)isLastWeek:(NSTimeInterval)secondsSince {
    return secondsSince < WEEK;
}


- (BOOL)isLastMonth:(NSTimeInterval)secondsSince {
    return secondsSince < MONTH;
}

- (BOOL)isLastYear:(NSTimeInterval)secondsSince {
    return secondsSince < YEAR;
}

- (NSString *)formatMinutesAgo:(NSTimeInterval)secondsSince {
    int minutesSince = (int)secondsSince / MINUTE;
    if(minutesSince == 1) return @"1 minute ago";
    else return [NSString stringWithFormat:@"%d minutes ago", minutesSince];
}

- (NSString *)formatAsToday:(NSTimeInterval)secondsSince {
    int hoursSince = (int)secondsSince / HOUR;
    if(hoursSince == 1) return @"1 hour ago";
    else return [NSString stringWithFormat:@"%d hours ago", hoursSince];
}

- (NSString *)formatAsYesterday {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm a"];
    return [NSString stringWithFormat:@"Yesterday at %@", [dateFormatter stringFromDate:self]];
}

- (NSString *)formatAsLastWeek {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE 'at' h:mm a"];
    return [dateFormatter stringFromDate:self];
}


- (NSString *)formatAsLastMonth {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d 'at' h:mm a"];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)formatAsLastYear {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d"];
    return [dateFormatter stringFromDate:self];
}


- (NSString *)formatAsOther {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    [dateFormatter setDateFormat:@"LLLL d, yyyy"];
    return [dateFormatter stringFromDate:self];
}

@end