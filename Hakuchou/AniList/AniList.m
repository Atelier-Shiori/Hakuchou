//
//  AniList.m
//  Shukofukurou
//
//  Created by 小鳥遊六花 on 3/31/18.
//  Copyright © 2018 MAL Updater OS X Group. All rights reserved.
//

#import "AniList.h"
#import "AniListConstants.h"
#import "AtarashiiAPIListFormatAniList.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager+Synchronous.h>
#import "OAuthCredManager.h"
#import "SharedHTTPManager.h"
#import "HUtility.h"

@interface AniList ()
    @property (strong) NSString *clientid;
    @property (strong) NSString *clientsecret;
    @property (strong) AFHTTPSessionManager *manager;
@end

@implementation AniList
@synthesize manager;
    
- (instancetype)initWithClientId:(NSString *)clientid withClientSecret:(NSString *)clientsecret {
    if (self = [self init]) {
        self.clientid = clientid;
        self.clientsecret = clientsecret;
    }
    return self;
}
    
- (instancetype)init {
    if (self = [super init]) {
        manager = [SharedHTTPManager jsonmanager];
    }
    return self;
}

#pragma mark List
- (void)retrieveList:(NSString *)username listType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    // Retrieves list
    [self getAniListUserid:username completion:^(int userid) {
        NSMutableArray *tmparray = [NSMutableArray new];
        [self retrievelist:userid withArray:tmparray withType:type page:1 completion:completionHandler error:errorHandler];
    } error:^(NSError *error) {
        errorHandler(error);
    }];
}

- (void)retrieveOwnListWithType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    // Retrieves list
    [self getOwnAnilistid:^(int userid, NSString *username, NSString *scoreformat, NSString *avatar) {
        NSMutableArray *tmparray = [NSMutableArray new];
        [self retrievelist:userid withArray:tmparray withType:type page:1 completion:completionHandler error:errorHandler];
    } error:^(NSError *error) {
        errorHandler(error);
    }];
}

- (void)retrievelist:(int)userid withArray:(NSMutableArray *)tmparray withType:(int)type page:(int)page completion:(void (^)(id))completionHandler error:(void (^)(NSError *))errorHandler  {
    // Retrieve List
    [manager.requestSerializer clearAuthorizationHeader];
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self retrievelist:userid withArray:tmparray withType:type page:page completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    NSDictionary *parameters;
    switch (type) {
        case AniListAnime:
            parameters = @{@"query" : kAnilistanimeList, @"variables" : @{@"id":@(userid), @"page" : @(page)}};
            break;
        case AniListManga:
            parameters = @{@"query" : kAnilistmangaList, @"variables" : @{@"id":@(userid), @"page" : @(page)}};
            break;
        default:
            errorHandler(nil);
            return;
    }
    
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        bool nextpage = false;
        switch (type) {
            case AniListAnime:
                [tmparray addObjectsFromArray:responseObject[@"data"][@"AnimeList"][@"mediaList"]];
                nextpage = ((NSNumber *)responseObject[@"data"][@"AnimeList"][@"pageInfo"][@"hasNextPage"]).boolValue;
                break;
            case AniListManga:
                [tmparray addObjectsFromArray:responseObject[@"data"][@"MangaList"][@"mediaList"]];
                nextpage = ((NSNumber *)responseObject[@"data"][@"MangaList"][@"pageInfo"][@"hasNextPage"]).boolValue;
                break;
            default:
                errorHandler(nil);
                return;
        }
        if (nextpage) {
            int newpagenum = page+1;
            [self retrievelist:userid withArray:tmparray withType:type page:newpagenum completion:completionHandler error:errorHandler];
            return;
        }
        switch (type) {
            case AniListAnime:
                completionHandler([AtarashiiAPIListFormatAniList AniListtoAtarashiiAnimeList:tmparray]);
                break;
            case AniListManga:
                completionHandler([AtarashiiAPIListFormatAniList AniListtoAtarashiiMangaList:tmparray]);
                break;
            default:
                errorHandler(nil);
                return;
        }
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}

#pragma mark Search
- (void)searchTitle:(NSString *)searchterm withType:(int)type withCurrentPage:(int)currentpage withSearchOptions:(NSDictionary *)options completion:(void (^)(id responseObject, int nextoffset, bool hasnextpage)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    NSString *searchquery = kAnilisttitlesearch;
    if (options) {
        searchquery = [searchquery stringByReplacingOccurrencesOfString:@"media(search: $query, type: $type)" withString:[self generateSearchOptions:options]];
    }
    NSDictionary *parameters = @{@"query" : searchquery, @"variables" : @{@"query" : searchterm, @"type" : type == AniListAnime ? @"ANIME" : @"MANGA", @"page" : @(currentpage)}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        int nextpage = ((NSNumber *)responseObject[@"data"][@"Page"][@"pageInfo"][@"currentPage"]).intValue + 1;
        switch (type) {
            case AniListAnime:
                completionHandler([AtarashiiAPIListFormatAniList AniListAnimeSearchtoAtarashii:responseObject], nextpage, ((NSNumber *)responseObject[@"data"][@"Page"][@"pageInfo"][@"hasNextPage"]).boolValue);
                break;
            case AniListManga:
                completionHandler([AtarashiiAPIListFormatAniList AniListMangaSearchtoAtarashii:responseObject], nextpage, ((NSNumber *)responseObject[@"data"][@"Page"][@"pageInfo"][@"hasNextPage"]).boolValue);
                break;
            default:
                break;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)searchPeople:(NSString *)searchterm withType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    NSDictionary *parameters = @{@"query" : type == AniListCharacter ? kAnilistCharacterSearch : kAniListStaffSearch, @"variables" : @{@"query" : searchterm}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler([AtarashiiAPIListFormatAniList normalizePersonSearchData:responseObject]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

#pragma mark Title Information
- (void)retrieveTitleInfo:(int)titleid withType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    NSDictionary *parameters = @{@"query" : kAnilistTitleIdInformation, @"variables" : @{@"id" : @(titleid), @"type" : type == AniListAnime ? @"ANIME" : @"MANGA"}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        switch (type) {
            case AniListAnime:
                completionHandler([AtarashiiAPIListFormatAniList AniListAnimeInfotoAtarashii:responseObject]);
                break;
            case AniListManga:
                completionHandler([AtarashiiAPIListFormatAniList AniListMangaInfotoAtarashii:responseObject]);
                break;
            default:
                break;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

#pragma mark Reviews
- (void)retrieveReviewsForTitle:(int)titleid withType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    NSMutableArray *dataarray = [NSMutableArray new];
    [self retrieveReviewsForTitle:titleid withType:type withDataArray:dataarray withPageOffset:0 completion:completionHandler error:errorHandler];
}

- (void)retrieveReviewsForTitle:(int)titleid withType:(int)type withDataArray:(NSMutableArray *)dataarray withPageOffset:(int)offset completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    NSDictionary *parameters;
    parameters = @{@"query" : kAnilistreviewbytitleid,@"variables" : @{@"id" : @(titleid), @"page" : @(offset)}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"data"] && responseObject[@"data"] != [NSNull null]) {
            [dataarray addObjectsFromArray:responseObject[@"data"][@"Page"][@"reviews"]];
        }
        if (((NSNumber *)responseObject[@"Page"][@"pageInfo"][@"hasNextPage"]).boolValue) {
            int newoffset = offset + 1;
            [self retrieveReviewsForTitle:titleid withType:type withDataArray:dataarray withPageOffset:newoffset completion:completionHandler error:errorHandler];
        }
        else {
            completionHandler([AtarashiiAPIListFormatAniList AniListReviewstoAtarashii:dataarray withType:type]);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

#pragma mark OAuth Tokens
- (bool)tokenexpired {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred) {
        return cred.expired;
    }
    return false;
}

- (void)refreshToken:(void (^)(bool success))completion {
    OAuthCredManager *credmanager = [OAuthCredManager sharedInstance];
    AFOAuthCredential *cred = [credmanager getFirstAccountForService:3];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:@"https://anilist.co/"]
                                                                     clientID:_clientid
                                                                       secret:_clientsecret];
    NSString *redirecturi;
#if TARGET_OS_IOS
    redirecturi = @"hiyokoauth://anilistauth/";
#else
    redirecturi = @"shukofukurouauth://anilistauth/";
#endif
    [OAuth2Manager setUseHTTPBasicAuthentication:NO];
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"api/v2/oauth/token"
                                            parameters:@{@"grant_type":@"refresh_token", @"refresh_token":cred.refreshToken, @"redirect_uri": redirecturi} success:^(AFOAuthCredential *credential) {
                                                NSLog(@"Token refreshed");
                                                [credmanager saveCredentialForService:3 withCredential:credential];
                                                completion(true);
                                            }
                                               failure:^(NSError *error) {
                                                   completion(false);
                                               }];
}

- (void)verifyAccountWithPin:(NSString *)pin completion:(void (^)(id responseObject))completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuth2Manager *OAuth2Manager =
    [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:@"https://anilist.co/"]
                                    clientID:_clientid
                                      secret:_clientsecret];
    NSString *redirecturi;
#if TARGET_OS_IOS
    redirecturi = @"hiyokoauth://anilistauth/";
#else
    redirecturi = @"shukofukurouauth://anilistauth/";
#endif
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"api/v2/oauth/token" parameters:@{@"grant_type":@"authorization_code", @"code" : pin, @"redirect_uri": redirecturi} success:^(AFOAuthCredential *credential) {
        [[OAuthCredManager sharedInstance] saveCredentialForService:3 withCredential:credential];
        [self getOwnAnilistid:^(int userid, NSString *username, NSString *scoreformat, NSString *avatar) {
            [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"anilist-username"];
            [[NSUserDefaults standardUserDefaults] setInteger:userid forKey:@"anilist-userid"];
            [[NSUserDefaults standardUserDefaults] setValue:scoreformat forKey:@"anilist-scoreformat"];
            [[NSUserDefaults standardUserDefaults] setValue:avatar forKey:@"anilist-avatar"];
            completionHandler(@{@"success":@(true)});
        } error:^(NSError *error) {
            
        }];
    }
                                               failure:^(NSError *error) {
                                                   errorHandler(error);
                                               }];
}

#pragma mark Profiles
- (void)retrieveProfile:(NSString *)username completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self retrieveProfile:username completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    [manager POST:@"https://graphql.anilist.co" parameters:@{@"query":kAnilistUserProfileByUsername, @"variables" : @{@"name" : username}} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"data"][@"User"] != [NSNull null]) {
            completionHandler([AtarashiiAPIListFormatAniList AniListUserProfiletoAtarashii:responseObject[@"data"][@"User"]]);
        }
        else {
            errorHandler(nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
    
}

#pragma mark List Operations
- (void)addAnimeTitleToList:(int)titleid withEpisode:(int)episode withStatus:(NSString *)status withScore:(int)score completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self addAnimeTitleToList:titleid withEpisode:episode withStatus:status withScore:score completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    NSMutableDictionary *variables =  [self generateAnimeAttributes:episode withStatus:[self convertWatchStatus:status isReconsuming:false withType:AniListAnime] withScore:score withExtraFields:nil];
    variables[@"mediaid"] = @(titleid);
    NSDictionary *parameters = @{@"query"
                                 : kAnilistAddAnimeListEntry, @"variables" : variables};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)addMangaTitleToList:(int)titleid withChapter:(int)chapter withVolume:(int)volume withStatus:(NSString *)status withScore:(int)score completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self addMangaTitleToList:titleid withChapter:chapter withVolume:volume withStatus:status withScore:score completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    NSMutableDictionary *variables = [self generateMangaAttributes:chapter withVolumes:volume withStatus:status withScore:score withExtraFields:nil];
    variables[@"mediaid"] = @(titleid);
    NSDictionary *parameters = @{@"query"
                                 : kAnilistAddMangaListEntry, @"variables" : variables};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)updateAnimeTitleOnList:(int)titleid withEpisode:(int)episode withStatus:(NSString *)status withScore:(int)score withExtraFields:(NSDictionary *)efields completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    // Note: Title id is entry id
    // Note: Tags field is ignored.
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self updateAnimeTitleOnList:titleid withEpisode:episode withStatus:status withScore:score withExtraFields:efields completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    NSDictionary *parameters;
    NSMutableDictionary *variables = [self generateAnimeAttributes:episode withStatus:status withScore:score withExtraFields:efields];
    variables[@"id"] = @(titleid);
    if (efields.count == 1) {
        parameters = @{@"query" : kAnilistUpdateAnimeListEntrySimple, @"variables" : variables};
    }
    else {
        parameters = @{@"query" : kAnilistUpdateAnimeListEntryAdvanced , @"variables" : variables};
    }
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)updateMangaTitleOnList:(int)titleid withChapter:(int)chapter withVolume:(int)volume withStatus:(NSString *)status withScore:(int)score withExtraFields:(NSDictionary *)efields completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    // Note: Title id is entry id
    // Note: Tags field is ignored.
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self updateMangaTitleOnList:titleid withChapter:chapter withVolume:volume withStatus:status withScore:score withExtraFields:efields completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    NSDictionary *parameters;
    NSMutableDictionary *variables = [self generateMangaAttributes:chapter withVolumes:volume withStatus:status withScore:score withExtraFields:efields];
    variables[@"id"] = @(titleid);
    if (efields.count == 1) {
        parameters = @{@"query" : kAnilistUpdateMangaListEntrySimple, @"variables" : variables};
    }
    else {
        parameters = @{@"query" : kAnilistUpdateMangaListEntryAdvanced, @"variables" : variables};
    }
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)removeTitleFromList:(int)titleid withType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    // Note: Title id is entry id
    // Note; Type field is ignored
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self removeTitleFromList:titleid withType:type completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    NSDictionary *parameters = @{@"query" : kAnilistDeleteListEntry, @"variables" : @{@"id" : @(titleid) }};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"data"][@"DeleteMediaListEntry"] != [NSNull null]) {
            completionHandler(responseObject);
        }
        else {
            errorHandler(nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(nil);
    }];
}

- (void)modifyCustomLists:(int)titleid withCustomLists:(NSArray *)customlists completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    // Note: Title id is entry id
    // Note; Type field is ignored
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self modifyCustomLists:titleid withCustomLists:customlists completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    NSDictionary *parameters = @{@"query" : kAnilistModifyCustomLists, @"variables" : @{@"id" : @(titleid), @"custom_lists" : customlists }};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(nil);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
    }];
}

#pragma mark Characters
- (void)retrieveStaff:(int)titleid withType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    NSMutableArray *characterarray = [NSMutableArray new];
    NSString *typestr = type == 0 ? @"ANIME" : @"MANGA";
    [self retrievecharacters:titleid withCharacterArray:characterarray withType:typestr withPageOffset:1 completion:completionHandler error:errorHandler];
}

- (void)retrievecharacters:(int)titleid withCharacterArray:(NSMutableArray *)characters withType:(NSString *)type withPageOffset:(int)pageoffset completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    NSDictionary *parameters = @{@"query" : kAnilistcharacterslist , @"variables" : @{@"id" : @(titleid), @"page" : @(pageoffset), @"type" : type}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"data"][@"Media"] != [NSNull null]) {
            [characters addObjectsFromArray:responseObject[@"data"][@"Media"][@"characters"][@"edges"]];
            if (((NSNumber *)responseObject[@"data"][@"Media"][@"characters"][@"pageInfo"][@"hasNextPage"]).boolValue) {
                int newpageoffset = pageoffset+1;
                [self retrievecharacters:titleid withCharacterArray:characters withType:type withPageOffset:newpageoffset completion:completionHandler error:errorHandler];
            }
            else {
                NSMutableArray *staffmembers = [NSMutableArray new];
                [self retrievestaffmembers:titleid withCharacterArray:characters withStaffArray:staffmembers withType:type withPageOffset:1 completion:completionHandler error:errorHandler];
            }
        }
        else {
            errorHandler(nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)retrievestaffmembers:(int)titleid withCharacterArray:(NSMutableArray *)characters withStaffArray:(NSMutableArray *)staffarray withType:(NSString *)type withPageOffset:(int)pageoffset completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    NSDictionary *parameters = @{@"query" : kAniliststafflist , @"variables" : @{@"id" : @(titleid), @"page" : @(pageoffset), @"type" : type}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"data"][@"Media"] != [NSNull null]) {
            [staffarray addObjectsFromArray:responseObject[@"data"][@"Media"][@"staff"][@"staff"]];
            if (((NSNumber *)responseObject[@"data"][@"Media"][@"staff"][@"pageInfo"][@"hasNextPage"]).boolValue) {
                int newpageoffset = pageoffset+1;
                [self retrievestaffmembers:titleid withCharacterArray:characters withStaffArray:staffarray withType:type withPageOffset:newpageoffset completion:completionHandler error:errorHandler];
            }
            else {
                completionHandler([AtarashiiAPIListFormatAniList generateStaffList:staffarray withCharacterArray:characters withType:type]);
            }
        }
        else {
            errorHandler(nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)retrievePersonDetails:(int)personid completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    NSDictionary *parameters = @{@"query" : kAniListstaffpage , @"variables" : @{@"id" : @(personid)}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler([AtarashiiAPIListFormatAniList AniListPersontoAtarashii:responseObject[@"data"][@"Staff"]]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)retrieveCharacterDetails:(int)characterid completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    manager.requestSerializer = [SharedHTTPManager jsonrequestserializer];
    NSDictionary *parameters = @{@"query" : kAniListcharacterpage , @"variables" : @{@"id" : @(characterid)}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler([AtarashiiAPIListFormatAniList AniListCharactertoAtarashii:responseObject[@"data"][@"Character"]]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

#pragma mark Title ID Retrieval
- (void)retrieveTitleIdsWithlistType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    NSMutableArray *tmparray = [NSMutableArray new];
    // Retrieves list
    [self retrieveTitleIds:(int)[NSUserDefaults.standardUserDefaults integerForKey:@"anilist-userid"] withArray:tmparray withType:type page:1 completion:completionHandler error:errorHandler];
}

- (void)retrieveTitleIds:(int)userid withArray:(NSMutableArray *)tmparray withType:(int)type page:(int)page completion:(void (^)(id responseobject))completionHandler error:(void (^)(NSError *))errorHandler  {
    // Retrieve List of AniList and MAL Ids
    [manager.requestSerializer clearAuthorizationHeader];
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self retrieveTitleIds:userid withArray:tmparray withType:type page:page completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    NSDictionary *parameters = @{@"query" : kAnilistRetrieveListTitleIdsOnly, @"variables" : @{@"id":@(userid), @"page" : @(page), @"type" : type == AniListAnime ? @"ANIME" : @"MANGA"}};
    
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        bool nextpage = false;
        [tmparray addObjectsFromArray:responseObject[@"data"][@"List"][@"mediaList"]];
        nextpage = ((NSNumber *)responseObject[@"data"][@"List"][@"pageInfo"][@"hasNextPage"]).boolValue;
        if (nextpage) {
            int newpagenum = page+1;
            [self retrieveTitleIds:userid withArray:tmparray withType:type page:newpagenum completion:completionHandler error:errorHandler];
            return;
        }
        completionHandler([AtarashiiAPIListFormatAniList generateIDArrayWithType:type withIdArray:tmparray]);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}


#pragma mark helpers
- (AFOAuthCredential *)getFirstAccount {
    return [[OAuthCredManager sharedInstance] getFirstAccountForService:3];
}

- (bool)removeAccount {
    return [[OAuthCredManager sharedInstance] removeCredentialForService:3];;
}

- (long)getCurrentUserID {
    return [NSUserDefaults.standardUserDefaults integerForKey:@"anilist-userid"];
}

- (NSDictionary *)generaterelationshipdictionary:(int)titleid withType:(int)mediatype {
    //Create relationship JSON for a new library entry
    NSDictionary * userd =  @{@"data" : @{@"id" : @([self getCurrentUserID]), @"type" : @"users"}};
    NSDictionary * mediad = @{@"data" : @{@"id" : @(titleid), @"type" : mediatype == AniListAnime ? @"anime" : @"manga"}};
    return @{@"user" : userd, @"media" : mediad};
}

- (void)getOwnAnilistid:(void (^)(int userid, NSString *username, NSString *scoreformat, NSString *avatar)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self getOwnAnilistid:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    [manager POST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistCurrentUsernametoUserId, @"variables" : @{}} progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        if (responseObject[@"data"][@"Viewer"] != [NSNull null]) {
            NSDictionary *d = responseObject[@"data"][@"Viewer"];
            completionHandler(((NSNumber *)d[@"id"]).intValue,d[@"name"], d[@"mediaListOptions"][@"scoreFormat"], d[@"avatar"] != [NSNull null] && d[@"avatar"][@"large"] ? d[@"avatar"][@"large"] : @"");
        }
        else {
            completionHandler(-1,@"",@"",@"");
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}

- (void)getAniListUserid:(NSString *)username completion:(void (^)(int userid)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    if (!username) {
        completionHandler(-1);
    }
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self getAniListUserid:username completion:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    NSDictionary *parameters = @{@"query" : kAnilistUsernametoUserId, @"variables" : @{@"name" : username ? username : @""}};
    [manager POST:@"https://graphql.anilist.co" parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        if (responseObject[@"data"][@"User"] != [NSNull null]) {
            completionHandler(((NSNumber *)responseObject[@"data"][@"User"][@"id"]).intValue);
        }
        else {
            completionHandler(-1);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}

- (NSMutableDictionary *)generateAnimeAttributes:(int)episode withStatus:(NSString *)status withScore:(int)score withExtraFields:(NSDictionary *)efields {
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    bool reconsuming = false;
    if (efields) {
        if (efields[@"reconsuming"]) {
            reconsuming = ((NSNumber *)efields[@"reconsuming"]).boolValue;
        }
    }
    attributes[@"status"] = [self convertWatchStatus:status isReconsuming:reconsuming withType:AniListAnime];
    attributes[@"progress"] = @(episode);
    attributes[@"score"] = @(score);
    if (efields) {
        [attributes addEntriesFromDictionary:efields];
        if (efields[@"reconsuming"]) {
            [attributes removeObjectForKey:@"reconsuming"];
        }
    }
    return attributes;
}

- (NSMutableDictionary *)generateMangaAttributes:(int)chapter withVolumes:(int)volume withStatus:(NSString *)status withScore:(int)score withExtraFields:(NSDictionary *)efields {
    NSMutableDictionary * attributes = [NSMutableDictionary new];
    bool reconsuming = false;
    if (efields) {
        if (efields[@"reconsuming"]) {
            reconsuming = ((NSNumber *)efields[@"reconsuming"]).boolValue;
        }
    }
    attributes[@"status"] = [self convertWatchStatus:status isReconsuming:reconsuming withType:AniListManga];
    attributes[@"progress"] = @(chapter);
    attributes[@"progressVolumes"] = @(volume);
    attributes[@"score"] = @(score);
    if (efields) {
        [attributes addEntriesFromDictionary:efields];
        if (efields[@"reconsuming"]) {
            [attributes removeObjectForKey:@"reconsuming"];
        }
    }
    return attributes;
}

- (void)getUserRatingType:(void (^)(NSString *scoretype)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self getUserRatingType:completionHandler error:errorHandler];
            }
            else {
                errorHandler(nil);
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    [manager POST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistCurrentUsernametoUserId, @"variables" : @{}} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (responseObject[@"data"][@"Viewer"] != [NSNull null]) {
            NSDictionary *d = responseObject[@"data"][@"Viewer"];
            completionHandler(d[@"mediaListOptions"][@"scoreFormat"]);
        }
        else {
            errorHandler(nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (NSString *)convertWatchStatus:(NSString *)status isReconsuming:(bool)reconsuming withType:(int)type{
    if (type == AniListAnime) {
        if ([status isEqualToString:@"watching"] && !reconsuming) {
            return @"CURRENT";
        }
        else if ([status isEqualToString:@"watching"] && reconsuming) {
            return @"REPEATING";
        }
        else if ([status isEqualToString:@"on-hold"]) {
            return @"PAUSED";
        }
        else if ([status isEqualToString:@"plan to watch"]) {
            return @"PLANNING";
        }
        return status.uppercaseString;
    }
    else {
        if ([status isEqualToString:@"reading"] && !reconsuming) {
            return @"CURRENT";
        }
        else if ([status isEqualToString:@"reading"] && !reconsuming) {
            return @"REPEATING";
        }
        else if ([status isEqualToString:@"on-hold"]) {
            return @"PAUSED";
        }
        else if ([status isEqualToString:@"plan to read"]) {
            return @"PLANNING";
        }
        return status.uppercaseString;
    }
}

- (void)saveuserinfoforcurrenttoken {
    // Retrieves missing user information and populates it before showing the UI.
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self saveuserinfoforcurrenttoken];
            }
        }];
        return;
    }
    AFHTTPSessionManager *smanager = [SharedHTTPManager syncmanager];
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    NSError *error;
    
    id responseObject = [smanager syncPOST:@"https://graphql.anilist.co" parameters:@{@"query" : kAnilistCurrentUsernametoUserId, @"variables" : @{}} task:NULL error:&error];
    if (!error) {
        if (responseObject[@"data"][@"Viewer"] != [NSNull null]) {
            NSDictionary *d = responseObject[@"data"][@"Viewer"];
            NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
            [defaults setValue:d[@"id"] forKey:@"anilist-userid"];
            [defaults setValue:d[@"name"] forKey:@"anilist-username"];
            [defaults setValue:d[@"mediaListOptions"][@"scoreFormat"] forKey:@"anilist-scoreformat"];
            [defaults setValue:d[@"avatar"] != [NSNull null] && d[@"avatar"][@"large"] ? d[@"avatar"][@"large"] : @"" forKey:@"anilist-avatar"];
        }
    }
    else {
        if ([[error.userInfo valueForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: unauthorized (401)"] || [[error.userInfo valueForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: forbidden (403)"]) {
            // Remove Account
            [self removeAccount];
        }
    }
}

- (NSString *)generateSearchOptions:(NSDictionary *)options {
    NSMutableString *tmpstr = [[NSMutableString alloc] initWithString:@"media(search: $query, type: $type"];
    for (NSString *key in options.allKeys) {
        [tmpstr appendFormat:@", %@: %@", key, options[key]];
    }
    [tmpstr appendString:@")"];
    return tmpstr;
}
@end
