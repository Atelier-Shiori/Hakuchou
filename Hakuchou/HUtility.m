//
//  Utility.m
//  Hakuchou
//
//  Created by 香風智乃 on 3/4/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "HUtility.h"

@implementation HUtility
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
            return @([HUtility dateStringToDate:responseObject[@"data"][@"attributes"][@"updatedAt"]].timeIntervalSince1970);
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

+ (int)parseSeason:(NSString *)string {
    // Season Parsing
    NSArray *matches = [HUtility findMatches:string pattern:@"((S|s|Season )\\d+|\\d+(st|nd|rd|th) Season|\\d+)"];
    NSString *tmpseason;
    if (matches.count > 0) {
        tmpseason = matches[0];
        tmpseason = [HUtility searchreplace:tmpseason pattern:@"((st|nd|rd|th) Season)|Season |S|s|"];
        return tmpseason.intValue;
    }
    return -1;
}

+ (NSArray *)findMatches:(NSString *)string pattern:(NSString *)pattern {
    if (string == nil) {
        return [NSArray new]; // Can't check a match of a nil string.
    }
    NSError *errRegex = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:pattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&errRegex];
    NSRange  searchrange = NSMakeRange(0, [string length]);
    NSArray * a = [regex matchesInString:string options:0 range:searchrange];
    NSMutableArray * results = [[NSMutableArray alloc] init];
    for (NSTextCheckingResult * result in a ) {
        [results addObject:[string substringWithRange:[result rangeAtIndex:0]]];
    }
    return results;
}
+ (NSString *)searchreplace:(NSString *)string pattern:(NSString *)pattern{
    if (string == nil)
        return @""; // Can't check a match of a nil string.
    NSError *errRegex = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&errRegex];
    NSString * newString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    return newString;
}
@end
