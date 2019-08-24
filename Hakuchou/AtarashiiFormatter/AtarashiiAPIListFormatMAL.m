//
//  AtarashiiAPIListFormatMAL.m
//  Hakuchou
//
//  Created by 香風智乃 on 8/23/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "AtarashiiAPIListFormatMAL.h"
#import "AtarashiiDataObjects.h"
#import "HUtility.h"

@implementation AtarashiiAPIListFormatMAL
+ (id)MALtoAtarashiiAnimeList:(id)data {
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *entry in data) {
        @autoreleasepool{
            AtarashiiAnimeListObject *aentry = [AtarashiiAnimeListObject new];
            NSDictionary *attributes = entry[@"node"];
            // Main Entry
            aentry.titleid = ((NSNumber *)attributes[@"id"]).intValue;
            aentry.title = attributes[@"title"];
            aentry.image_url = attributes[@"main_picture"][@"large"] && attributes[@"main_picture"][@"large"] != [NSNull null] ? attributes[@"main_picture"][@"large"] : @"";
            aentry.status = [(NSString *)attributes[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            NSString *strType = attributes[@"type"];
            if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
                strType = [strType capitalizedString];
            }
            else {
                strType = [strType uppercaseString];
            }
            aentry.type = strType;
            aentry.episodes = ((NSNumber *)attributes[@"num_episodes"]).intValue;
            
            // User Entry
            NSDictionary *listStatus = attributes[@"my_list_status"];
            aentry.status = [(NSString *)listStatus[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            aentry.score = ((NSNumber *)listStatus[@"score"]).intValue;
            aentry.watched_episodes = ((NSNumber *)listStatus[@"num_episodes_watched"]).intValue;
            aentry.rewatching = ((NSNumber *)listStatus[@"is_rewatching"]).boolValue;
            aentry.watching_start = listStatus[@"start_date"] ? listStatus[@"start_date"] : @"";
            aentry.watching_end = listStatus[@"finish_date"] ? listStatus[@"finish_date"] : @"";
            aentry.personal_comments = listStatus[@"comments"];
            aentry.lastupdated = [HUtility dateStringToDate:listStatus[@"updated_at"]];
            [tmparray addObject:aentry.NSDictionaryRepresentation];
        }
    }
    return @{@"anime" : tmparray, @"statistics" : @{@"days" : @([HUtility calculatedays:tmparray])}};
}

+ (id)MALtoAtarashiiMangaList:(id)data {
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *entry in data) {
        @autoreleasepool{
            AtarashiiMangaListObject *mentry = [AtarashiiMangaListObject new];
            NSDictionary *attributes = entry[@"node"];
            // Main Entry
            mentry.titleid = ((NSNumber *)attributes[@"id"]).intValue;
            mentry.title = attributes[@"title"];
            mentry.image_url = attributes[@"main_picture"][@"large"] && attributes[@"main_picture"][@"large"] != [NSNull null] ? attributes[@"main_picture"][@"large"] : @"";
            mentry.status = [(NSString *)attributes[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            NSString *strType = attributes[@"type"];
            strType = [strType uppercaseString];
            mentry.type = strType;
            mentry.chapters = ((NSNumber *)attributes[@"num_chapters"]).intValue;
            mentry.volumes = ((NSNumber *)attributes[@"num_volumes"]).intValue;
            
            // User Entry
            NSDictionary *listStatus = attributes[@"my_list_status"];
            mentry.status = [(NSString *)listStatus[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            if ([mentry.status isEqualToString:@"currently publishing"]) {
                mentry.status = @"publishing";
            }
            mentry.score = ((NSNumber *)listStatus[@"score"]).intValue;
            mentry.chapters = ((NSNumber *)listStatus[@"num_chapters_read"]).intValue;
            mentry.volumes_read = ((NSNumber *)listStatus[@"num_volumes_read"]).intValue;
            mentry.rereading = ((NSNumber *)listStatus[@"is_rereading"]).boolValue;
            mentry.reading_start = listStatus[@"start_date"] ? listStatus[@"start_date"] : @"";
            mentry.reading_end = listStatus[@"finish_date"] ? listStatus[@"finish_date"] : @"";
            mentry.personal_comments = listStatus[@"comments"];
            mentry.lastupdated = [HUtility dateStringToDate:listStatus[@"updated_at"]];
            [tmparray addObject:mentry.NSDictionaryRepresentation];
        }
    }
    return @{@"manga" : tmpmangalist, @"statistics" : @{@"days" : @(0)}};
}

@end
