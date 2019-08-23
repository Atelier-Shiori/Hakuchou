//
//  OAuthCredManager.m
//  Shukofukurou-IOS
//
//  Created by 香風智乃 on 2/4/19.
//  Copyright © 2019 MAL Updater OS X Group. All rights reserved.
//

#import "OAuthCredManager.h"
#import <AFNetworking/AFNetworking.h>

@implementation OAuthCredManager

#ifdef DEBUG
    #if TARGET_OS_IOS
    NSString *const kKitsuKeychainIdentifier = @"Shukofukurou - Kitsu DEBUG";
    NSString *const kAniListKeychainIdentifier = @"Hiyoko - AniList DEBUG";
    NSString *const kMyAnimeListKeychainIdentifier = @"Hiyoko - MyAnimeList DEBUG";
    #else
        NSString *const kKitsuKeychainIdentifier = @"Shukofukurou - Kitsu DEBUG";
        NSString *const kAniListKeychainIdentifier = @"Shukofukurou - AniList DEBUG";
        NSString *const kMyAnimeListKeychainIdentifier = @"Shukofukurou - MyAnimeList DEBUG";
    #endif
#else
    #if TARGET_OS_IOS
    NSString *const kKitsuKeychainIdentifier = @"Shukofukurou - Kitsu";
    NSString *const kAniListKeychainIdentifier = @"Hiyoko - AniList";
    NSString *const kMyAnimeListKeychainIdentifier = @"Hiyoko - MyAnimeList";
    #else
    NSString *const kKitsuKeychainIdentifier = @"Shukofukurou - Kitsu";
    NSString *const kAniListKeychainIdentifier = @"Shukofukurou - AniList";
    NSString *const kMyAnimeListKeychainIdentifier = @"Shukofukurou - MyAnimeList";
    #endif
#endif

+ (instancetype)sharedInstance {
    static OAuthCredManager *sharedManager = nil;
    static dispatch_once_t oauthcredmanagertoken;
    dispatch_once(&oauthcredmanagertoken, ^{
        sharedManager = [[OAuthCredManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        [self getFirstAccountForService:1];
        [self getFirstAccountForService:2];
        [self getFirstAccountForService:3];
    }
    return self;
}

- (AFOAuthCredential * _Nullable)getFirstAccountForService:(int)service {
    NSString *keychainidentifier;
    switch (service) {
        case 1:
            if (_MyAnimeListCredential) {
                return _MyAnimeListCredential;
            }
            keychainidentifier = kMyAnimeListKeychainIdentifier;
            break;
        case 2:
            if (_KitsuCredential) {
                return _KitsuCredential;
            }
            keychainidentifier = kKitsuKeychainIdentifier;
            break;
        case 3:
            if (_AniListCredential) {
                return _AniListCredential;
            }
            keychainidentifier = kAniListKeychainIdentifier;
            break;
        default:
            return nil;
    }
    AFOAuthCredential *cred = [AFOAuthCredential retrieveCredentialWithIdentifier:keychainidentifier];
    if (cred) {
        switch (service) {
            case 1:
                _MyAnimeListCredential = cred;
                return _MyAnimeListCredential;
            case 2:
                _KitsuCredential = cred;
                return _KitsuCredential;
            case 3:
                _AniListCredential = cred;
                return _AniListCredential;
        }
    }
    return nil;
}

- (AFOAuthCredential * _Nullable)saveCredentialForService:(int)service withCredential:(AFOAuthCredential *)cred {
    NSString *keychainidentifier;
    switch (service) {
        case 1:
            keychainidentifier = kMyAnimeListKeychainIdentifier;
            break;
        case 2:
            keychainidentifier = kKitsuKeychainIdentifier;
            break;
        case 3:
            keychainidentifier = kAniListKeychainIdentifier;
            break;
        default:
            return nil;
    }
    [AFOAuthCredential storeCredential:cred withIdentifier:keychainidentifier];
    switch (service) {
        case 1:
            _MyAnimeListCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:keychainidentifier];
            return _MyAnimeListCredential;
        case 2:
            _KitsuCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:keychainidentifier];
            return _KitsuCredential;
        case 3:
            _AniListCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:keychainidentifier];
            return _AniListCredential;
    }
    return nil;
}

- (bool)removeCredentialForService:(int)service {
    NSString *keychainidentifier;
    switch (service) {
        case 1:
            keychainidentifier = kMyAnimeListKeychainIdentifier;
            break;
        case 2:
            keychainidentifier = kKitsuKeychainIdentifier;
            break;
        case 3:
            keychainidentifier = kAniListKeychainIdentifier;
            break;
        default:
            return false;
    }
    bool success = [AFOAuthCredential deleteCredentialWithIdentifier:keychainidentifier];
    switch (service) {
        case 1:
            _MyAnimeListCredential = nil;
            break;
        case 2:
            _KitsuCredential = nil;
            break;
        case 3:
            _AniListCredential = nil;
            break;
    }
    return success;
}

- (void)fixkeychainaccessability {
    if (_MyAnimeListCredential) {
        [AFOAuthCredential storeCredential:_MyAnimeListCredential withIdentifier:kMyAnimeListKeychainIdentifier];
    }
    if (_AniListCredential) {
        [AFOAuthCredential storeCredential:_AniListCredential withIdentifier:kAniListKeychainIdentifier];
    }
    if (_KitsuCredential) {
        [AFOAuthCredential storeCredential:_KitsuCredential withIdentifier:kKitsuKeychainIdentifier];
    }
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"FixKeychainItems"];
}
@end
