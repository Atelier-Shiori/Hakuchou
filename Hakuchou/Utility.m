//
//  Utility.m
//  Hakuchou
//
//  Created by 香風智乃 on 3/4/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "Utility.h"

@implementation Utility
+ (NSString *)urlEncodeString:(NSString *)string {
    return [string stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
}
    
+ (double)calculatedays:(NSArray *)list {
    double duration = 0;
    for (NSDictionary *entry in list) {
        duration += ((NSNumber *)entry[@"watched_episodes"]).integerValue * ((NSNumber *)entry[@"duration"]).intValue;
    }
    duration = (duration/60)/24;
    return duration;
}

+ (NSString *)dateIntervalToDateString:(double)timeinterval {
    NSDate *aDate = [NSDate dateWithTimeIntervalSince1970:timeinterval];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    return [dateFormatter stringFromDate:aDate];
}

+ (NSString *)convertAnimeType:(NSString *)type {
    NSString *tmpstr = type.lowercaseString;
    if ([tmpstr isEqualToString: @"tv"]||[tmpstr isEqualToString: @"ova"]||[tmpstr isEqualToString: @"ona"]) {
        tmpstr = tmpstr.uppercaseString;
    }
    else {
        tmpstr = tmpstr.capitalizedString;
        tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"Tv" withString:@"TV"];
    }
    return tmpstr;
}


+ (NSNumber *)getLastUpdatedDateWithResponseObject:(id)responseObject withService:(int)service {
    switch (service) {
        case 2:
            return @([Utility dateStringToDate:responseObject[@"data"][@"attributes"][@"updatedAt"]].timeIntervalSince1970);
        case 3:
            return responseObject[@"data"][@"SaveMediaListEntry"][@"updatedAt"];
        default:
            return @(0);
    }
}

+ (NSDate *)dateStringToDate:(NSString *)datestring {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    return [formatter dateFromString:datestring];
}
@end
