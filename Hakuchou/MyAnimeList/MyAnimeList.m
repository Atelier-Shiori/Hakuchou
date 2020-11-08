//
//  MyAnimeList.m
//  Shukofukurou
//
//  Created by 天々座理世 on 2017/04/11.
//  Copyright © 2017年 MAL Updater OS X Group. All rights reserved. Licensed under 3-clause BSD License
//

#import "MyAnimeList.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFHTTPSessionManager+Synchronous.h>
#import "AtarashiiAPIListFormatMAL.h"
#import "HUtility.h"
#import "OAuthCredManager.h"
#import "SharedHTTPManager.h"
#import "PKCEGenerator.h"

@interface MyAnimeList ()
    @property (strong) NSString *clientid;
    @property (strong) NSString *redirectURL;
    @property (strong) AFHTTPSessionManager *manager;
    @property (strong) NSString *verifier;
    @property (strong) NSMutableArray *tmparray;
@end


@implementation MyAnimeList
@synthesize manager;

NSString *const kJikanAPIURL = @"https://api.jikan.moe/v3";

- (instancetype)initWithClientId:(NSString *)clientid withRedirectURL:(NSString *)redirectURL {
    if (self = [self init]) {
        self.clientid = clientid;
        self.redirectURL = redirectURL;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        manager = [SharedHTTPManager jsonmanager];
    }
    return self;
}

#pragma mark MyAnimeList Functions

#pragma mark OAuth Tokens

- (NSURL *)retrieveAuthorizeURL {
    _verifier = [PKCEGenerator generateCodeChallenge:[PKCEGenerator createVerifierString]];
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://myanimelist.net/v1/oauth2/authorize?response_type=code&client_id=%@&redirect_uri=%@&code_challenge=%@&code_challenge_method=plain", _clientid, [HUtility urlEncodeString:_redirectURL], _verifier]];
}

- (bool)tokenexpired {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred) {
        return cred.expired;
    }
    return false;
}

- (void)refreshToken:(void (^)(bool success))completion {
    OAuthCredManager *credmanager = [OAuthCredManager sharedInstance];
    AFOAuthCredential *cred = [credmanager getFirstAccountForService:1];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:@"https://myanimelist.net/"]
                                                                     clientID:_clientid
                                                                       secret:@""];
    [OAuth2Manager setUseHTTPBasicAuthentication:NO];
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"v1/oauth2/token"
                                            parameters:@{@"grant_type":@"refresh_token", @"refresh_token":cred.refreshToken, @"redirect_uri": _redirectURL} success:^(AFOAuthCredential *credential) {
                                                NSLog(@"Token refreshed");
                                                [credmanager saveCredentialForService:1 withCredential:credential];
                                                completion(true);
                                            }
                                               failure:^(NSError *error) {
                                                   completion(false);
                NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
                                               }];
}

- (void)verifyAccountWithPin:(NSString *)pin completion:(void (^)(id responseObject))completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuth2Manager *OAuth2Manager =
    [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:@"https://myanimelist.net/"]
                                    clientID:_clientid
                                      secret:@""];
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"v1/oauth2/token"
                                            parameters:@{@"grant_type":@"authorization_code", @"code" : pin, @"redirect_uri": _redirectURL, @"code_verifier" : _verifier} success:^(AFOAuthCredential *credential) {
        [[OAuthCredManager sharedInstance] saveCredentialForService:1 withCredential:credential];
        [self getOwnMALid:^(int userid, NSString *username, NSString *avatar) {
            [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"mal-username"];
            [[NSUserDefaults standardUserDefaults] setInteger:userid forKey:@"mal-userid"];
            [[NSUserDefaults standardUserDefaults] setValue:avatar forKey:@"mal-avatar"];
             completionHandler(@{@"success":@(true)});
        } error:^(NSError *error) {
        }];
    }
                                               failure:^(NSError *error) {
                                                   errorHandler(error);
                NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
                                               }];
}
- (void)reauthAccountWithPin:(NSString *)pin completion:(void (^)(id responseObject))completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuth2Manager *OAuth2Manager =
    [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:@"https://myanimelist.net/"]
                                    clientID:_clientid
                                      secret:@""];
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"v1/oauth2/token"
                                            parameters:@{@"grant_type":@"authorization_code", @"code" : pin, @"redirect_uri": _redirectURL, @"code_verifier" : _verifier} success:^(AFOAuthCredential *credential) {
        [self getMALidWithCredential:credential completion:^(int userid, NSString *username, NSString *avatar) {
            if ([NSUserDefaults.standardUserDefaults integerForKey:@"mal-userid"] == userid) {
                [[OAuthCredManager sharedInstance] saveCredentialForService:1 withCredential:credential];
                completionHandler(@{@"success":@(true)});
            }
            else {
                completionHandler(@{@"success":@(false)});
            }
        } error:^(NSError *error) {
            completionHandler(@{@"success":@(false)});
        }];
    }
                                               failure:^(NSError *error) {
                                                   errorHandler(error);
                NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
                                               }];
}
#pragma mark Profiles
- (void)retrieveProfile:(NSString *)username completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    [manager GET:[NSString stringWithFormat:@"%@/user/%@/profile",kJikanAPIURL,username] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        completionHandler([AtarashiiAPIListFormatMAL MalUsertoAtarashii:responseObject]);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
    
}

#pragma mark List and Serach

- (void)retrieveOwnListWithType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [self retrieveList:@"@me" listType:type completion:completionHandler error:errorHandler];
}

- (void)retrieveList:(NSString *)username listType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [self retrieveList:username listType:type page:0 withArray:[NSMutableArray new] completion:completionHandler error:errorHandler];
}

- (void)retrieveList:(NSString *)username listType:(int)type page:(int)page withArray:(NSMutableArray *)listArray completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self retrieveList:username listType:type page:page withArray:listArray completion:completionHandler error:errorHandler];
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
    NSString * URL = @"";
    if (type == MALAnime) {
        URL = [NSString stringWithFormat:@"https://api.myanimelist.net/v2/users/%@/animelist?fields=status,media_type,num_episodes,my_list_status,start_date,finish_date,comments,num_times_rewatched,average_episode_duration%%7D&limit=1000&offset=%i", username, page];
    }
    else if (type == MALManga) {
        URL = [NSString stringWithFormat:@"https://api.myanimelist.net/v2/users/%@/mangalist?fields=status,media_type,num_chapters,num_volumes,my_list_status,start_date,finish_date,comments,num_times_reread%%7D&limit=1000&offset=%i", username, page];
    }
    
    [manager GET:URL parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [listArray addObjectsFromArray:responseObject[@"data"]];
        if (responseObject[@"paging"][@"next"]) {
            int npage = page + 1000;
            [self retrieveList:username listType:type page:npage withArray:listArray completion:completionHandler error:errorHandler];
        }
        else {
            completionHandler(type == MALAnime ? [AtarashiiAPIListFormatMAL MALtoAtarashiiAnimeList:listArray] : [AtarashiiAPIListFormatMAL MALtoAtarashiiMangaList:listArray]);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
        NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
    }];
}

- (void)retrieveAiringSchedule:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler{
    /*
    [manager GET:[NSString stringWithFormat:@"%@/2.1/anime/schedule",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"]] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
     */
}

- (void)searchTitle:(NSString *)searchterm withType:(int)type withCurrentPage:(int)currentpage completion:(void (^)(id responseObject, int nextoffset, bool hasnextpage)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self searchTitle:searchterm withType:type withCurrentPage:currentpage completion:completionHandler error:errorHandler];
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
    NSString *searchURL = type == MALAnime ? @"https://api.myanimelist.net/v2/anime" : @"https://api.myanimelist.net/v2/manga";
    NSDictionary *parameters = @{@"q" : searchterm, @"limit" : @(25), @"offset" : @(currentpage), @"fields" : type == MALAnime ? @"alternative_titles,num_episodes,status,media_type,nsfw,rating,average_episode_duration" : @"alternative_titles,num_chapters,num_volumes,status,media_type,nsfw"};
    [manager GET:searchURL parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        bool hasNextPage = false;
        int nextOffset = currentpage;
        NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
        NSLog(@"%@", searchURL);
        NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        if (responseObject[@"paging"][@"next"]) {
            hasNextPage = true;
            nextOffset = nextOffset + 25;
        }
        completionHandler(type == MALAnime ? [AtarashiiAPIListFormatMAL MALAnimeSearchtoAtarashii:responseObject] : [AtarashiiAPIListFormatMAL MALMangaSearchtoAtarashii:responseObject], nextOffset, hasNextPage);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        errorHandler(error);
        NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
    }];
}
/*
- (void)advsearchTitle:(NSString *)searchterm withType:(int)type withGenres:(NSString *)genres excludeGenres:(bool)exclude startDate:(NSDate *)startDate endDate:(NSDate *)endDate minScore:(int)minscore rating:(int)rating withStatus:(int)status completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler{
    NSMutableDictionary *d = [NSMutableDictionary new];
    [d setValue:searchterm forKey:@"keyword"];
    [d setValue:@(minscore) forKey:@"score"];
    [d setValue:@(exclude) forKey:@"genre_type"];
    [d setValue:genres forKey:@"genres"];
    NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
    dateformat.dateFormat = @"YYYY-MM-DD";
    if (startDate) {
        [d setValue:startDate forKey:@"start_date"];
    }
    if (endDate) {
        [d setValue:endDate forKey:@"end_date"];
    }
    [d setValue:@(status) forKey:@"status"];
    [d setValue:@(rating) forKey:@"rating"];
    
    NSString *URL;
    if (type == MALAnime) {
        URL = [NSString stringWithFormat:@"%@/2.1/anime/browse",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"]];
    }
    else if (type == MALManga) {
        URL = [NSString stringWithFormat:@"%@/2.1/manga/browse",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"]];
    }
    else {
        return;
    }
    [manager GET:URL parameters:d progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}*/

- (void)retrieveTitleInfo:(int)titleid withType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler{
    NSString *url = @"";
    if (type == MALAnime) {
        url = [NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%i?fields=id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,nsfw,created_at,updated_at,media_type,status,genres,my_list_status,num_episodes,start_season,broadcast,source,average_episode_duration,rating,pictures,background,related_anime,related_manga,recommendations,studios,statistics",titleid];
        
    }
    else if (type == MALManga) {
        url = [NSString stringWithFormat:@"https://api.myanimelist.net/v2/manga/%i?fields=id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,nsfw,created_at,updated_at,media_type,status,genres,my_list_status,num_volumes,num_chapters,authors%%7Bfirst_name,last_name%%7D,pictures,background,related_anime,related_manga,recommendations,serialization%%7Bname%%7D",titleid];
    }
    else {
        return;
    }
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self retrieveTitleInfo:titleid withType:type completion:completionHandler error:errorHandler];
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
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(type == MALAnime ? [AtarashiiAPIListFormatMAL MALAnimeInfotoAtarashii:responseObject] : [AtarashiiAPIListFormatMAL MALMangaInfotoAtarashii:responseObject]);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}
- (void)retrieveReviewsForTitle:(int)titleid withType:(int)type withPage:(int)page completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    NSString *url = @"";
    if (!_tmparray) {
        _tmparray = [NSMutableArray new];
    }
    if (type == MALAnime) {
        url = [NSString stringWithFormat:@"%@/anime/%i/reviews/%i",kJikanAPIURL,titleid,page];
    }
    else if (type == MALManga) {
        url = [NSString stringWithFormat:@"%@/anime/%i/reviews/%i",kJikanAPIURL,titleid,page];
    }
    else {
        return;
    }
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [self.tmparray addObjectsFromArray:[AtarashiiAPIListFormatMAL MALReviewstoAtarashii:responseObject[@"reviews"] withType:type]];
        if (((NSArray *)responseObject[@"reviews"]).count > 0) {
            int tmppage = page+1;
            [NSThread sleepForTimeInterval:1];
            [self retrieveReviewsForTitle:titleid withType:type withPage:tmppage completion:completionHandler error:errorHandler];
        }
        else {
            completionHandler(self.tmparray.mutableCopy);
            self.tmparray = nil;
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}

/*- (void)retriveUpdateHistory:(NSString *)username completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler{
    [manager GET:[NSString stringWithFormat:@"%@/2.1/history/%@",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"], username] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler([self processHistory:responseObject]);
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}*/

#pragma mark List Management

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
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    else {
        errorHandler(nil);
        return;
    }
    [manager PATCH:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%i/my_list_status", titleid] parameters:@{@"status":[[status stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"-" withString:@"_"], @"score":@(score), @"num_watched_episodes"/*@"num_episodes_watched"*/:@(episode)} success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
        NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
    }];

}

- (void)addMangaTitleToList:(int)titleid withChapter:(int)chapter withVolume:(int)volume withStatus:(NSString *)status withScore:(int)score completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler{
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
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    else {
        errorHandler(nil);
        return;
    }
    [manager PATCH:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/manga/%i/my_list_status", titleid] parameters:@{@"status":[[status stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"-" withString:@"_"], @"score":@(score), @"num_chapters_read":@(chapter), @"num_volumes_read":@(volume)} success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
        NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
    }];
}

- (void)updateAnimeTitleOnList:(int)titleid withEpisode:(int)episode withStatus:(NSString *)status withScore:(int)score withExtraFields:(NSDictionary *)efields completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler{
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
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    else {
        errorHandler(nil);
        return;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters addEntriesFromDictionary:@{@"status":[[status stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"-" withString:@"_"], @"score":@(score), @"num_watched_episodes"/*@"num_episodes_watched"*/:@(episode)}];
    if (efields) {
        [parameters addEntriesFromDictionary:efields];
    }
    [manager PATCH:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%i/my_list_status", titleid] parameters:parameters success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
        NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
    }];
}

- (void)updateMangaTitleOnList:(int)titleid withChapter:(int)chapter withVolume:(int)volume withStatus:(NSString *)status withScore:(int)score withExtraFields:(NSDictionary *)efields completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
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
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    else {
        errorHandler(nil);
        return;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    [parameters addEntriesFromDictionary:@{@"status":[[status stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByReplacingOccurrencesOfString:@"-" withString:@"_"], @"score":@(score), @"num_chapters_read":@(chapter), @"num_volumes_read":@(volume)}];
    if (efields) {
        [parameters addEntriesFromDictionary:efields];
    }
    [manager PATCH:[NSString stringWithFormat:@"https://api.myanimelist.net/v2/manga/%i/my_list_status", titleid] parameters:parameters success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
        NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
    }];
}

- (void)removeTitleFromList:(int)titleid withType:(int)type completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
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
    if (cred) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    else {
        errorHandler(nil);
        return;
    }
    NSString *deleteURL;
    if (type == MALAnime) {
        deleteURL = [NSString stringWithFormat:@"https://api.myanimelist.net/v2/anime/%i/my_list_status", titleid];
    }
    else if (type == MALManga) {
        deleteURL = [NSString stringWithFormat:@"https://api.myanimelist.net/v2/manga/%i/my_list_status", titleid];
    }
    else {
        return;
    }
    [manager DELETE:deleteURL parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
        NSLog(@"Error: %@ Response: %@", error.localizedDescription, [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding]);
    }];
}

#pragma mark Messages
/*
- (void)retrievemessagelist:(int)page completionHandler:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    if ([self verifyAccount]) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@",[Keychain getBase64]] forHTTPHeaderField:@"Authorization"];
        [manager GET:[NSString stringWithFormat:@"%@/2.1/messages",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"]] parameters:@{@"page":@(page)} progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            completionHandler(responseObject);
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            errorHandler(error);
        }];
    }
    else {
        errorHandler(nil);
    }
}

- (void)retrievemessage:(int)messageid completionHandler:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    if ([self verifyAccount]) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@",[Keychain getBase64]] forHTTPHeaderField:@"Authorization"];
        [manager GET:[NSString stringWithFormat:@"%@/2.1/messages/%i",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"], messageid] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            completionHandler(responseObject);
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            errorHandler(error);
        }];
    }
    else {
        errorHandler(nil);
    }
}

- (void)sendmessage:(NSString *)username withSubject:(NSString *)subject withMessage:(NSString *)message withthreadID:(int)threadid completionHandler:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    if ([self verifyAccount]) {
        NSDictionary *pram;
        if (threadid == 0) {
            pram = @{@"username":username, @"subject":subject, @"message":message};
        }
        else {
            pram = @{@"username":username, @"subject":subject, @"message":message, @"id":@(threadid)};
        }
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@",[Keychain getBase64]] forHTTPHeaderField:@"Authorization"];
        [manager POST:[NSString stringWithFormat:@"%@/2.1/messages",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"]] parameters:pram progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            completionHandler(responseObject);
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            errorHandler(error);
        }];
    }
    else {
        errorHandler(nil);
    }
}

- (void)deletemessage:(int)messageid completionHandler:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    if ([self verifyAccount]) {
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Basic %@",[Keychain getBase64]] forHTTPHeaderField:@"Authorization"];
        [manager DELETE:[NSString stringWithFormat:@"%@/2.1/messages/%i",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"], messageid] parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
            completionHandler(responseObject);
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            errorHandler(error);
        }];
    }
    else {
        errorHandler(nil);
    }
}*/

#pragma mark People Methods

- (void)retrieveStaff:(int)titleid completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    NSString *url = [NSString stringWithFormat:@"%@/2.1/anime/cast/%i",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"],titleid];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
        NSLog(@"%@",error.localizedDescription);
    }];
}

- (void)retrievePersonDetails:(int)personid completion:(void (^)(id responseObject)) completionHandler error:(void (^)(NSError * error)) errorHandler{
    NSString *url = [NSString stringWithFormat:@"%@/2.1/people/%i",[[NSUserDefaults standardUserDefaults] valueForKey:@"malapiurl"],personid];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(responseObject);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}

#pragma mark -
#pragma mark Private Methods

- (AFOAuthCredential *)getFirstAccount {
    return [[OAuthCredManager sharedInstance] getFirstAccountForService:1];
}

- (bool)removeAccount {
    return [[OAuthCredManager sharedInstance] removeCredentialForService:1];;
}

- (long)getCurrentUserID {
    return [NSUserDefaults.standardUserDefaults integerForKey:@"mal-userid"];
}

- (void)getOwnMALid:(void (^)(int userid, NSString *username, NSString *avatar)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    AFOAuthCredential *cred = [self getFirstAccount];
    if (cred && cred.expired) {
        [self refreshToken:^(bool success) {
            if (success) {
                [self getOwnMALid:completionHandler error:errorHandler];
            }
        }];
        return;
    }
    [manager.requestSerializer clearAuthorizationHeader];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    [manager GET:@"https://api.myanimelist.net/v2/users/@me?fields=avatar" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(((NSNumber *)responseObject[@"id"]).intValue, responseObject[@"name"], responseObject[@"picture"] != [NSNull null] && responseObject[@"picture"] ? responseObject[@"picture"] : @"");
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
}

- (void)getMALidWithCredential:(AFOAuthCredential *)cred completion:(void (^)(int userid, NSString *username, NSString *avatar)) completionHandler error:(void (^)(NSError * error)) errorHandler {
    [manager.requestSerializer clearAuthorizationHeader];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", cred.accessToken] forHTTPHeaderField:@"Authorization"];
    [manager GET:@"https://api.myanimelist.net/v2/users/@me?fields=avatar" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        completionHandler(((NSNumber *)responseObject[@"id"]).intValue, responseObject[@"name"], responseObject[@"picture"] != [NSNull null] && responseObject[@"picture"] ? responseObject[@"picture"] : @"");
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        errorHandler(error);
    }];
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
    else {
        return;
    }
    NSError *error;
    
    id responseObject = [smanager syncGET:@"https://api.myanimelist.net/v2/users/@me?fields=avatar" parameters:nil task:NULL error:&error];
    if (!error) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setValue:responseObject[@"id"] forKey:@"mal-userid"];
        [defaults setValue:responseObject[@"name"] forKey:@"mal-username"];
        [defaults setValue:responseObject[@"picture"] != [NSNull null] && responseObject[@"picture"] ? responseObject[@"picture"] : @"" forKey:@"mal-avatar"];
    }
    else {
        if ([[error.userInfo valueForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: unauthorized (401)"] || [[error.userInfo valueForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: forbidden (403)"]) {
            // Remove Account
            [self removeAccount];
        }
    }
}
/*
- (id)processHistory:(id)object {
    if ([object isMemberOfClass:[NSArray class]]) {
        return @[];
    }
    NSArray *a = object;
    NSMutableArray *history = [NSMutableArray new];
    for (NSDictionary *d in a) {
        NSDictionary *item = d[@"item"];
        NSNumber *idnum = item[@"id"];
        NSString *title = item[@"title"];
        NSString *type = d[@"type"];
        NSNumber *segment;
        NSString *segment_type = @"";
        if (item[@"watched_episodes"]) {
            segment = item[@"watched_episodes"];
            segment_type = @"Episode";
        }
        else {
            segment = item[@"chapters_read"];
            segment_type = @"Chapter";
        }
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init] ;
        dateFormatter.dateFormat = @"yyyy-MM-dd";
        NSDate *datetime;
        if (d[@"time_updated"]) {
            NSString *strdate = d[@"time_updated"];
            strdate = [strdate substringWithRange:NSMakeRange(0, 10)];
            datetime = [dateFormatter dateFromString:strdate];
        }
        else {
            datetime = [NSDate date]; // Just updated, set now date.
        }
        [dateFormatter setDateFormat:nil];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        NSString *lastupdated = [NSDateFormatter localizedStringFromDate:datetime
                                                               dateStyle: NSDateFormatterShortStyle
                                                               timeStyle: NSDateFormatterNoStyle];
        [history addObject:@{@"id":idnum, @"title":title, @"type":type, @"last_updated":lastupdated, @"segment":segment, @"segment_type":segment_type}];
    }
    return history;
}
- (AFHTTPSessionManager*) verifymanager {
    static dispatch_once_t verifyonceToken;
    static AFHTTPSessionManager *verifymanager = nil;
    if (verifymanager) {
        [verifymanager.requestSerializer clearAuthorizationHeader];
    }
    dispatch_once(&verifyonceToken, ^{
        verifymanager = [AFHTTPSessionManager manager];
        verifymanager.requestSerializer = [SharedHTTPManager httprequestserializer];
        verifymanager.responseSerializer =  [AFHTTPResponseSerializer new];
    });
    return verifymanager;
};*/
@end
