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
            NSString *strType = attributes[@"media_type"];
            if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
                strType = [strType uppercaseString];
            }
            else {
                strType = [strType capitalizedString];
            }
            aentry.type = strType;
            aentry.episodes = ((NSNumber *)attributes[@"num_episodes"]).intValue;
            
            // User Entry
            NSDictionary *listStatus = attributes[@"my_list_status"];
            aentry.watched_status = [(NSString *)listStatus[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            if ([aentry.watched_status isEqualToString:@"on hold"]) {
                aentry.watched_status = @"on-hold";
            }
            aentry.score = ((NSNumber *)listStatus[@"score"]).intValue;
            aentry.watched_episodes = ((NSNumber *)listStatus[@"num_episodes_watched"]).intValue;
            aentry.rewatching = ((NSNumber *)listStatus[@"is_rewatching"]).boolValue;
            aentry.rewatch_count = ((NSNumber *)listStatus[@"num_times_rewatched"]).intValue;
            aentry.watching_start = listStatus[@"start_date"] ? listStatus[@"start_date"] : @"";
            aentry.watching_end = listStatus[@"finish_date"] ? listStatus[@"finish_date"] : @"";
            aentry.personal_comments = listStatus[@"comments"];
            aentry.lastupdated = [[HUtility isodateStringToDate:listStatus[@"updated_at"]] timeIntervalSince1970];
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
            if ([mentry.status isEqualToString:@"currently publishing"]) {
                mentry.status = @"publishing";
            }
            NSString *strType = attributes[@"media_type"] != [NSNull null] ? [self convertMangaType:attributes[@"media_type"]] : @"";
            strType = [strType uppercaseString];
            mentry.type = strType;
            mentry.chapters = ((NSNumber *)attributes[@"num_chapters"]).intValue;
            mentry.volumes = ((NSNumber *)attributes[@"num_volumes"]).intValue;
            
            // User Entry
            NSDictionary *listStatus = attributes[@"my_list_status"];
            mentry.read_status = [(NSString *)listStatus[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            if ([mentry.read_status isEqualToString:@"on hold"]) {
                mentry.read_status = @"on-hold";
            }
            mentry.score = ((NSNumber *)listStatus[@"score"]).intValue;
            mentry.chapters_read = ((NSNumber *)listStatus[@"num_chapters_read"]).intValue;
            mentry.volumes_read = ((NSNumber *)listStatus[@"num_volumes_read"]).intValue;
            mentry.rereading = ((NSNumber *)listStatus[@"is_rereading"]).boolValue;
            mentry.reread_count = ((NSNumber *)listStatus[@"num_times_reread"]).intValue;
            mentry.reading_start = listStatus[@"start_date"] ? listStatus[@"start_date"] : @"";
            mentry.reading_end = listStatus[@"finish_date"] ? listStatus[@"finish_date"] : @"";
            mentry.personal_comments = listStatus[@"comments"];
            mentry.lastupdated = [[HUtility isodateStringToDate:listStatus[@"updated_at"]] timeIntervalSince1970];
            [tmparray addObject:mentry.NSDictionaryRepresentation];
        }
    }
    return @{@"manga" : tmparray, @"statistics" : @{@"days" : @(0)}};
}

+ (NSDictionary *)MALAnimeInfotoAtarashii:(NSDictionary *)data {
    AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
    aobject.titleid = ((NSNumber *)data[@"id"]).intValue;
    aobject.title = data[@"title"];
    // Create other titles
    aobject.other_titles = @{@"synonyms" : data[@"alternative_titles"][@"synonyms"] && data[@"alternative_titles"][@"synonyms"] != [NSNull null] ? data[@"alternative_titles"][@"synonyms"] : @[]  , @"english" : data[@"alternative_titles"][@"en"] != [NSNull null] && data[@"alternative_titles"][@"en"] && ((NSString *)data[@"alternative_titles"][@"en"]).length > 0 ? @[data[@"alternative_titles"][@"en"]] : @[], @"japanese" : data[@"alternative_titles"][@"ja"] != [NSNull null] && data[@"alternative_titles"][@"ja"] && ((NSString *)data[@"alternative_titles"][@"ja"]).length > 0 ? @[data[@"alternative_titles"][@"ja"]] : @[] };
    aobject.popularity_rank = data[@"popularity"] != [NSNull null] ? ((NSNumber *)data[@"popularity"]).intValue : 0;
    #if defined(AppStore)
    if (data[@"main_picture"] != [NSNull null] && data[@"main_picture"]) {
        aobject.image_url = data[@"main_picture"][@"large"] && data[@"main_picture"] != [NSNull null] && ![(NSString *)data[@"nsfw"] isEqualToString:@"black"] ? data[@"main_picture"][@"large"] : @"";
    }
    aobject.synposis = [(NSString *)data[@"nsfw"] isEqualToString:@"black"] ? data[@"synopsis"] != [NSNull null] ? data[@"synopsis"] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #else
    bool allowed = ([NSUserDefaults.standardUserDefaults boolForKey:@"showadult"] || ![(NSString *)data[@"nsfw"] isEqualToString:@"black"]);
    if (data[@"main_picture"] != [NSNull null]&& data[@"main_picture"]) {
        aobject.image_url = data[@"main_picture"][@"large"] && data[@"main_picture"] != [NSNull null] && data[@"main_picture"][@"large"] && allowed ?  data[@"main_picture"][@"large"] : @"";
    }
    aobject.synposis = allowed ? data[@"synopsis"] != [NSNull null] ? data[@"synopsis"] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #endif
    NSString *strType = data[@"media_type"];
    if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
        strType = [strType uppercaseString];
    }
    else {
        strType = [strType capitalizedString];
    }
    aobject.type = strType;
    aobject.episodes = data[@"num_episodes"] && data[@"num_episodes"] != [NSNull null] ? ((NSNumber *)data[@"num_episodes"]).intValue : 0;
    aobject.start_date = data[@"start_date"] != [NSNull null] && data[@"start_date"] ? data[@"start_date"] : @"";
    aobject.end_date = data[@"end_date"] != [NSNull null] && data[@"end_date"] ? data[@"end_date"] : @"";
    aobject.duration = data[@"average_episode_duration"] && data[@"average_episode_duration"] != [NSNull null] ? (((NSNumber *)data[@"average_episode_duration"]).intValue/60) : 0;
    aobject.classification = data[@"rating"] && data[@"rating"] != [NSNull null] ? [[(NSString *)data[@"rating"] stringByReplacingOccurrencesOfString:@"_" withString:@" "] capitalizedString] : @"";
    //aobject.hashtag = data[@"hashtag"] != [NSNull null] ? data[@"hashtag"] : @"";
    aobject.season = data[@"start_season"] != [NSNull null] && data[@"start_season"] ? ((NSString *)data[@"start_season"][@"season"]).capitalizedString : @"Unknown";
    aobject.source = data[@"source"] != [NSNull null] && data[@"source"] ? [(NSString *)data[@"source"] stringByReplacingOccurrencesOfString:@"_" withString:@" "].capitalizedString : @"";
    aobject.members_score = data[@"mean"] != [NSNull null] && data[@"mean"]? ((NSNumber *)data[@"mean"]).floatValue : 0;
    aobject.status = [(NSString *)data[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    NSMutableArray *genres = [NSMutableArray new];
    for (NSDictionary *genre in data[@"genres"]) {
        [genres addObject:genre[@"name"]];
    }
    aobject.genres = genres;
    NSMutableArray *studiosarray = [NSMutableArray new];
    if (data[@"studios"] != [NSNull null]) {
        for (NSDictionary *studio in data[@"studios"]) {
            [studiosarray addObject:studio[@"name"]];
        }
    }
    aobject.producers = studiosarray;
    /*
    NSMutableArray *mangaadaptations = [NSMutableArray new];
    for (NSDictionary *adpt in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"ADAPTATION"]]) {
        if ([(NSString *)adpt[@"node"][@"type"] isEqualToString:@"MANGA"]) {
            [mangaadaptations addObject: @{@"manga_id": adpt[@"node"][@"id"], @"title" : adpt[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *sidestories = [NSMutableArray new];
    for (NSDictionary *side in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"SIDE_STORY"]]) {
        if ([(NSString *)side[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [sidestories addObject: @{@"anime_id": side[@"node"][@"id"], @"title" : side[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *sequels = [NSMutableArray new];
    for (NSDictionary *sequel in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"SEQUEL"]]) {
        if ([(NSString *)sequel[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [sequels addObject: @{@"anime_id": sequel[@"node"][@"id"], @"title" : sequel[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *prequels = [NSMutableArray new];
    for (NSDictionary *prequel in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"PREQUEL"]]) {
        if ([(NSString *)prequel[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [prequels addObject: @{@"anime_id": prequel[@"node"][@"id"], @"title" : prequel[@"node"][@"title"][@"romaji"]}];
        }
    }
    aobject.manga_adaptations = mangaadaptations;
    aobject.side_stories = sidestories;
    aobject.sequels = sequels;
    aobject.prequels = prequels;
    */
    return aobject.NSDictionaryRepresentation;
}

+ (NSDictionary *)MALMangaInfotoAtarashii:(NSDictionary *)data {
    AtarashiiMangaObject *mobject = [AtarashiiMangaObject new];
    mobject.titleid = ((NSNumber *)data[@"id"]).intValue;
    mobject.title = data[@"title"];
    // Create other titles
    mobject.other_titles = @{@"synonyms" : data[@"alternative_titles"][@"synonyms"] && data[@"alternative_titles"][@"synonyms"] != [NSNull null] ? data[@"alternative_titles"][@"synonyms"] : @[]  , @"english" : data[@"alternative_titles"][@"en"] != [NSNull null] && data[@"alternative_titles"][@"en"] && ((NSString *)data[@"alternative_titles"][@"en"]).length > 0 ? @[data[@"alternative_titles"][@"en"]] : @[], @"japanese" : data[@"alternative_titles"][@"ja"] != [NSNull null] && data[@"alternative_titles"][@"ja"] && ((NSString *)data[@"alternative_titles"][@"ja"]).length > 0 ? @[data[@"alternative_titles"][@"ja"]] : @[] };
    mobject.popularity_rank = data[@"popularity"] != [NSNull null] ? ((NSNumber *)data[@"popularity"]).intValue : 0;
    #if defined(AppStore)
    if (data[@"main_picture"] != [NSNull null] && data[@"main_picture"]]) {
        mobject.image_url = data[@"main_picture"][@"large"] && data[@"main_picture"] != [NSNull null] && ![(NSString *)data[@"nsfw"] isEqualToString:@"black"] ? data[@"main_picture"][@"large"] : @"";
     }
     mobject.synposis = ![(NSString *)data[@"nsfw"] isEqualToString:@"black"] ? data[@"synopsis"] != [NSNull null] ? data[@"synopsis"] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #else
    bool allowed = ([NSUserDefaults.standardUserDefaults boolForKey:@"showadult"] || ![(NSString *)data[@"nsfw"] isEqualToString:@"black"]);
    if (data[@"main_picture"] != [NSNull null]) {
         mobject.image_url = data[@"main_picture"][@"large"] && data[@"main_picture"] != [NSNull null] && data[@"main_picture"][@"large"] && allowed ?  data[@"main_picture"][@"large"] : @"";
    }
    mobject.synposis = allowed ? data[@"synopsis"] != [NSNull null] ? data[@"synopsis"] : @"No synopsis available" : @"Synopsis not available for adult titles";
    #endif
    mobject.type = data[@"media_type"] != [NSNull null] ? [self convertMangaType:data[@"media_type"]] : @"";
    mobject.chapters = data[@"num_chapters"] != [NSNull null] ? ((NSNumber *)data[@"num_chapters"]).intValue : 0;
    mobject.volumes = data[@"num_volumes"] != [NSNull null] ? ((NSNumber *)data[@"num_volumes"]).intValue : 0;
    mobject.members_score = data[@"mean"] != [NSNull null] ? ((NSNumber *)data[@"mean"]).floatValue : 0;
    mobject.status =  [(NSString *)data[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    if ([mobject.status isEqualToString:@"currently publishing"]) {
        mobject.status = @"publishing";
    }
    mobject.start_date = data[@"start_date"] != [NSNull null] && data[@"start_date"] ? data[@"start_date"] : @"";
    mobject.end_date = data[@"end_date"] != [NSNull null] && data[@"end_date"] ? data[@"end_date"] : @"";
    NSMutableArray *genres = [NSMutableArray new];
    for (NSDictionary *genre in data[@"genres"]) {
        [genres addObject:genre[@"name"]];
    }
    mobject.genres = genres;
    /*
    NSMutableArray *animeadaptations = [NSMutableArray new];
    for (NSDictionary *adpt in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"ADAPTATION"]]) {
        if ([(NSString *)adpt[@"node"][@"type"] isEqualToString:@"ANIME"]) {
            [animeadaptations addObject: @{@"anime_id": adpt[@"node"][@"id"], @"title" : adpt[@"node"][@"title"][@"romaji"]}];
        }
    }
    NSMutableArray *alternativestories = [NSMutableArray new];
    for (NSDictionary *alt in [(NSArray *)data[@"relations"][@"edges"] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"relationType == %@", @"ALTERNATIVE"]]) {
        if ([(NSString *)alt[@"node"][@"type"] isEqualToString:@"MANGA"]) {
            [alternativestories addObject: @{@"manga_id": alt[@"node"][@"id"], @"title" : alt[@"node"][@"title"][@"romaji"]}];
        }
    }
    mobject.anime_adaptations = animeadaptations;
    mobject.alternative_versions = alternativestories;*/
    
    return mobject.NSDictionaryRepresentation;
}

+ (NSArray *)MALAnimeSearchtoAtarashii:(NSDictionary *)data {
    NSArray *dataarray = data[@"data"];
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *d in dataarray) {
        @autoreleasepool {
            NSDictionary *titleData = d[@"node"];
#if defined(AppStore)
            if ([(NSString *)titleData[@"nsfw"] isEqualToString:@"black"]) {
                continue;
            }
#else
            if ([(NSString *)titleData[@"nsfw"] isEqualToString:@"black"] && ![NSUserDefaults.standardUserDefaults boolForKey:@"showadult"]) {
                continue;
            }
#endif
            AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
            aobject.titleid = ((NSNumber *)titleData[@"id"]).intValue;
            aobject.title = titleData[@"title"];
            // Create other titles
            aobject.other_titles = @{@"synonyms" : titleData[@"alternative_titles"][@"synonyms"] && titleData[@"alternative_titles"][@"synonyms"] != [NSNull null] ? titleData[@"alternative_titles"][@"synonyms"] : @[]  , @"english" : titleData[@"alternative_titles"][@"en"] != [NSNull null] && titleData[@"alternative_titles"][@"en"] && ((NSString *)titleData[@"alternative_titles"][@"en"]).length > 0 ? @[titleData[@"alternative_titles"][@"en"]] : @[], @"japanese" : titleData[@"alternative_titles"][@"ja"] != [NSNull null] && titleData[@"alternative_titles"][@"ja"] && ((NSString *)titleData[@"alternative_titles"][@"ja"]).length > 0 ? @[titleData[@"alternative_titles"][@"ja"]] : @[] };
            if (titleData[@"main_picture"] != [NSNull null]) {
                 aobject.image_url = titleData[@"main_picture"][@"large"] && titleData[@"main_picture"] != [NSNull null] && titleData[@"main_picture"][@"large"] ?  titleData[@"main_picture"][@"large"] : @"";
            }
            aobject.status = [(NSString *)titleData[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            aobject.episodes = titleData[@"num_episodes"] != [NSNull null] ? ((NSNumber *)titleData[@"num_episodes"]).intValue : 0;
            NSString *strType = titleData[@"media_type"];
            if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
                strType = [strType uppercaseString];
            }
            else {
                strType = [strType capitalizedString];
            }
            aobject.type = strType;
            [aobject parseSeason];
            [tmparray addObject:aobject.NSDictionaryRepresentation];
        }
    }
    return tmparray;
}

+ (NSArray *)MALMangaSearchtoAtarashii:(NSDictionary *)data {
    NSArray *dataarray = data[@"data"];
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *d in dataarray) {
        @autoreleasepool {
            NSDictionary *titleData = d[@"node"];
#if defined(AppStore)
            if ([(NSString *)titleData[@"nsfw"] isEqualToString:@"black"]) {
                continue;
            }
#else
            if ([(NSString *)titleData[@"nsfw"] isEqualToString:@"black"] && ![NSUserDefaults.standardUserDefaults boolForKey:@"showadult"]) {
                continue;
            }
#endif
            AtarashiiMangaObject *mobject = [AtarashiiMangaObject new];
            mobject.titleid = ((NSNumber *)titleData[@"id"]).intValue;
            mobject.title = titleData[@"title"];
            // Create other titles
            mobject.other_titles = @{@"synonyms" : titleData[@"alternative_titles"][@"synonyms"] && titleData[@"alternative_titles"][@"synonyms"] != [NSNull null] ? titleData[@"alternative_titles"][@"synonyms"] : @[]  , @"english" : titleData[@"alternative_titles"][@"en"] != [NSNull null] && titleData[@"alternative_titles"][@"en"]  && ((NSString *)titleData[@"alternative_titles"][@"en"]).length > 0 ? @[titleData[@"alternative_titles"][@"en"]] : @[], @"japanese" : titleData[@"alternative_titles"][@"ja"] != [NSNull null] && titleData[@"alternative_titles"][@"ja"] && ((NSString *)titleData[@"alternative_titles"][@"ja"]).length > 0 ? @[titleData[@"alternative_titles"][@"ja"]] : @[] };
            if (titleData[@"main_picture"] != [NSNull null]) {
                 mobject.image_url = titleData[@"main_picture"][@"large"] && titleData[@"main_picture"] != [NSNull null] && titleData[@"main_picture"][@"large"] ?  titleData[@"main_picture"][@"large"] : @"";
            }
            mobject.status = [(NSString *)titleData[@"status"] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            if ([mobject.status isEqualToString:@"currently publishing"]) {
                mobject.status = @"publishing";
            }
            mobject.chapters = titleData[@"num_chapters"] != [NSNull null] ? ((NSNumber *)titleData[@"num_chapters"]).intValue : 0;
            mobject.volumes = titleData[@"num_volumes"] != [NSNull null] ? ((NSNumber *)titleData[@"num_volumes"]).intValue : 0;
            mobject.type = titleData[@"media_type"] != [NSNull null] ? [self convertMangaType:titleData[@"media_type"]] : @"";
            [tmparray addObject:mobject.NSDictionaryRepresentation];
        }
    }
    return tmparray;
}

+ (NSArray *)normalizeSeasonData:(NSArray *)seasonData withSeason:(NSString *)season withYear:(int)year {
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *d in seasonData) {
        @autoreleasepool {
            NSDictionary *titleData = d[@"node"];
            if ([(NSString *)titleData[@"nsfw"] isEqualToString:@"black"]) {
                continue;
            }
            AtarashiiAnimeObject *aobject = [AtarashiiAnimeObject new];
            aobject.titleid = ((NSNumber *)titleData[@"id"]).intValue;
            aobject.title = titleData[@"title"];
            aobject.other_titles =  @{@"synonyms" : titleData[@"alternative_titles"][@"synonyms"] && titleData[@"alternative_titles"][@"synonyms"] != [NSNull null] ? titleData[@"alternative_titles"][@"synonyms"] : @[]  , @"english" : titleData[@"alternative_titles"][@"en"] != [NSNull null] && titleData[@"alternative_titles"][@"en"]  && ((NSString *)titleData[@"alternative_titles"][@"en"]).length > 0 ? @[titleData[@"alternative_titles"][@"en"]] : @[], @"japanese" : titleData[@"alternative_titles"][@"ja"] != [NSNull null] && titleData[@"alternative_titles"][@"ja"] && ((NSString *)titleData[@"alternative_titles"][@"ja"]).length > 0 ? @[titleData[@"alternative_titles"][@"ja"]] : @[] };
            if (titleData[@"main_picture"] != [NSNull null]) {
                 aobject.image_url = titleData[@"main_picture"][@"large"] && titleData[@"main_picture"] != [NSNull null] && titleData[@"main_picture"][@"large"] ?  titleData[@"main_picture"][@"large"] : @"";
            }
            NSString *strType = titleData[@"media_type"];
            if ([strType isEqualToString:@"tv"]||[strType isEqualToString:@"ova"]||[strType isEqualToString:@"ona"]) {
                strType = [strType uppercaseString];
            }
            else {
                strType = [strType capitalizedString];
            }
            aobject.type = strType;
            NSMutableDictionary *finaldict = [[NSMutableDictionary alloc] initWithDictionary:aobject.NSDictionaryRepresentation];
            finaldict[@"year"] = @(year);
            finaldict[@"season"] = season;
            finaldict[@"service"] = @(1);
            [tmparray addObject:finaldict.copy];
        }
    }
    return tmparray.copy;
}

+ (NSDictionary *)MalUsertoAtarashii:(NSDictionary *)userdata {
    AtarashiiUserObject *user = [AtarashiiUserObject new];
    user.avatar_url = userdata[@"image_url"] != [NSNull null] ? userdata[@"image_url"] : [NSNull null];
    user.gender = userdata[@"gender"] != [NSNull null] ? userdata[@"gender"] : @"Unknown";
    user.birthday =  userdata[@"birthday"] != [NSNull null] ?  userdata[@"birthday"] : [NSNull null];
    user.location =  userdata[@"location"] != [NSNull null] ?  userdata[@"location"] : [NSNull null];
    user.join_date =  userdata[@"joined"];
    return [user.NSDictionaryRepresentation copy];
}

+ (NSArray *)MALReviewstoAtarashii:(NSArray *)data withType:(int)type {
    NSMutableArray *tmparray = [NSMutableArray new];
    for (NSDictionary *review in data) {
        @autoreleasepool {
            AtarashiiReviewObject *reviewobj = [AtarashiiReviewObject new];
            reviewobj.mediatype = type;
            reviewobj.date = review[@"data"];
            reviewobj.helpful = ((NSNumber *)review[@"helpful_count"]).intValue;
            reviewobj.helpful_total = ((NSNumber *)review[@"helpful_count"]).intValue;
            reviewobj.review = review[@"content"];
            reviewobj.actual_username = review[@"reviewer"][@"username"];
            reviewobj.avatar_url = review[@"reviewer"][@"image_url"] && review[@"reviewer"][@"image_url"] != [NSNull null] ? review[@"reviewer"][@"image_url"] : @"";
            reviewobj.rating = ((NSNumber *)review[@"reviewer"][@"scores"][@"overall"]).intValue;
            if (type == 0) {
                reviewobj.watched_episodes = ((NSNumber *)review[@"reviewer"][@"episodes_seen"]).intValue;
            }
            else {
                reviewobj.read_chapters = ((NSNumber *)review[@"reviewer"][@"chapters_read"]).intValue;
            }
            [tmparray addObject:reviewobj.NSDictionaryRepresentation];
        }
    }
    return tmparray.copy;
}

+ (NSString *)convertMangaType:(NSString *)type {
    NSString *tmpstr = type.lowercaseString;
    tmpstr = [tmpstr stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    tmpstr = tmpstr.capitalizedString;
    return tmpstr;
}
@end
