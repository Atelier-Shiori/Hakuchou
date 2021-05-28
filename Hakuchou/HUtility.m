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

+ (NSDate *)isodateStringToDate:(NSString *)datestring {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    return [formatter dateFromString:datestring];
}

+ (NSDictionary *)dateStringToAiringSeasonAndYear:(NSString *)datestring {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSDate *date = [formatter dateFromString:datestring];
    NSDateComponents *components = [NSCalendar.currentCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    long year = components.year;
    NSString *season = @"";
    switch (components.month) {
        case 1:
        case 2:
        case 3:
            season = @"winter";
            break;
        case 4:
        case 5:
        case 6:
            season = @"spring";
            break;
        case 7:
        case 8:
        case 9:
            season = @"summer";
            break;
        case 10:
        case 11:
        case 12:
            season = @"fall";
            break;
        default:
            season = @"unkown";
            break;
    }
    return @{@"aired_year" : @(year), @"aired_season" : season};
}


+ (NSDictionary *)aniListdateStringToAiringSeasonAndYear:(NSDictionary *)dateDict {
    long year = ((NSNumber *)dateDict[@"year"]).longValue;
    NSString *season = @"";
    if (dateDict[@"month"] && dateDict[@"month"] != [NSNull null]) {
        switch (((NSNumber *)dateDict[@"month"]).longValue) {
            case 1:
            case 2:
            case 3:
                season = @"winter";
                break;
            case 4:
            case 5:
            case 6:
                season = @"spring";
                break;
            case 7:
            case 8:
            case 9:
                season = @"summer";
                break;
            case 10:
            case 11:
            case 12:
                season = @"fall";
                break;
            default:
                season = @"unknown";
                break;
        }
    }
    else {
        season = @"unknown";
    }
    return @{@"aired_year" : @(year), @"aired_season" : season};
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

+ (bool)grayAreaCheckByClassification:(NSString *)classification {
    if ([classification isEqualToString:@"Rx"]) {
        return true;
    }
    if ([classification containsString:@"Hentai"]) {
        return true;
    }
    return false;
}

+ (bool)grayAreaCheckByTags:(NSArray *)tags {
    int tagcount = 0;
    for (NSDictionary *tag in tags) {
        tagcount++;
        if ([(NSString *)tag[@"name"] isEqualToString:@"Nudity"] && (((NSNumber *)tag[@"rank"]).intValue >= 80 || tagcount <= 5)) {
            return true;
        }
        if ([(NSString *)tag[@"name"] isEqualToString:@"Masturbating"] && ((NSNumber *)tag[@"rank"]).intValue >= 50) {
            return true;
        }
    }
    return false;
}

+ (bool)grayAreaCheck:(NSArray *)genres withTitle:(NSString *)title withAltTitles:(NSDictionary *)alttitles {
    // Checks for Gray Area Titles that might cause the app to get rejected for Objectionable content. Needed for Kitsu and AniList
    bool isNSFW = false;
    NSArray *objectionableStrs = @[@"hentai", @"futanari", @"変態", @"へんたい", @"ヘンタイ"];
    for (NSString *objkeywords in objectionableStrs) {
        if ([title localizedCaseInsensitiveContainsString:objkeywords]) {
            isNSFW = true;
            break;
        }
    }
    if (isNSFW) {
        return isNSFW;
    }
    // Alt Title Check
    for (NSString *titlekey in alttitles.allKeys) {
        for (NSString *objtitle in alttitles[titlekey]) {
            for (NSString *objkeywords in objectionableStrs) {
                if ([objkeywords isKindOfClass:[NSNull class]]) {
                    continue;
                }
                if ([objtitle localizedCaseInsensitiveContainsString:objkeywords]) {
                    isNSFW = true;
                    break;
                }
            }
            if (isNSFW) {
                break;
            }
        }
        if (isNSFW) {
            break;
        }
    }
    if (isNSFW) {
        return isNSFW;
    }
    //Genre Check
    NSArray *objectionableGenres = @[@"Hentai"];
    for (NSString *genre in genres) {
        for (NSString *objgenre in objectionableGenres) {
            if ([genre localizedCaseInsensitiveContainsString:objgenre]) {
                isNSFW = true;
                break;
            }
        }
        if (isNSFW) {
            break;
        }
    }
    return isNSFW;
}
@end
