//
//  AtarashiiDataObjects.m
//  Shukofukurou
//
//  Created by 桐間紗路 on 2017/12/19.
//  Copyright © 2017年 MAL Updater OS X Group. All rights reserved.
//

#import "AtarashiiDataObjects.h"

@implementation AtarashiiAnimeObject
- (id)init {
    self = [super init];
    if (self) {
        self.titleid = 0;
        self.titleidMal = 0;
        self.title = @"";
        self.other_titles = @{};
        self.rank = 0;
        self.popularity_rank = 0;
        self.image_url = @"";
        self.type = @"";
        self.episodes = 0;
        self.status = @"";
        self.start_date = @"";
        self.end_date = @"";
        self.broadcast = @"";
        self.duration = 0;
        self.classification = @"";
        self.hashtag = @"";
        self.source = @"";
        self.season = @"";
        self.members_score = 0;
        self.members_count = 0;
        self.favorited_count = 0;
        self.synposis = @"";
        self.background = @"";
        self.producers = @[];
        self.genres = @[];
        self.manga_adaptations = @[];
        self.prequels = @[];
        self.sequels = @[];
        self.side_stories = @[];
        self.parent_story = @[];
        self.character_anime = @[];
        self.spin_offs = @[];
        self.opening_theme = @[];
        self.ending_theme = @[];
        self.recommendations = @[];
        self.mappings = @{};
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{ @"id" : @(_titleid), @"idMal" : @(_titleidMal), @"title" : _title.copy, @"other_titles" : _other_titles.copy, @"rank" : @(_rank), @"popularity_rank" : @(_popularity_rank), @"image_url" : _image_url.copy, @"type" : _type.copy, @"episodes" : @(_episodes), @"status" : _status.copy, @"start_date" : _start_date.copy, @"end_date" : _end_date.copy, @"broadcast" : _broadcast.copy, @"duration" : @(_duration), @"classification" : _classification.copy, @"hashtag" : _hashtag.copy, @"source" : _source.copy, @"season" : _season.copy, @"members_score" : @(_members_score), @"members_count" : @(_members_count), @"favorited_count" : @(_favorited_count), @"synopsis" : _synposis.copy, @"background" : _background.copy, @"producers" : _producers.copy, @"genres" : _genres.copy, @"manga_adaptations" : _manga_adaptations.copy, @"prequels" : _prequels.copy, @"sequels" : _sequels.copy, @"side_stories" : _side_stories.copy, @"parent_story" : _parent_story.copy, @"character_anime" : _character_anime.copy, @"spin_offs" : _spin_offs.copy, @"opening_theme" : _opening_theme.copy, @"ending_theme" : _ending_theme.copy, @"recommendations" : _recommendations.copy, @"mappings" : _mappings.copy };
}
@end

@implementation AtarashiiMangaObject
- (id)init {
    self = [super init];
    if (self) {
        self.titleid = 0;
        self.titleidMal = 0;
        self.title = @"";
        self.other_titles = @{};
        self.rank = 0;
        self.popularity_rank = 0;
        self.image_url = @"";
        self.type = @"";
        self.chapters = 0;
        self.volumes = 0;
        self.status = @"";
        self.members_score = 0;
        self.members_count = 0;
        self.favorited_count = 0;
        self.synposis = @"";
        self.genres = @[];
        self.anime_adaptations = @[];
        self.related_manga = @[];
        self.alternative_versions = @[];
        self.mappings = @{};
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{ @"id" : @(_titleid), @"idMal" : @(_titleidMal), @"title" : _title.copy, @"other_titles" : _other_titles.copy, @"rank" : @(_rank), @"popularity_rank" : @(_popularity_rank), @"image_url" : _image_url.copy, @"type" : _type.copy, @"chapters" : @(_chapters), @"volumes": @(_volumes), @"status" : _status.copy, @"members_score" : @(_members_score), @"members_count" : @(_members_count), @"favorited_count" : @(_favorited_count), @"synopsis" : _synposis.copy, @"genres" : _genres.copy, @"anime_adaptations" : _anime_adaptations.copy, @"related_manga" : _related_manga.copy, @"alternate_versions" : _alternative_versions.copy, @"mappings" : _mappings.copy};
}
@end

@implementation AtarashiiAnimeListObject
- (id)init {
    self = [super init];
    if (self) {
        self.titleid = 0;
        self.title = @"";
        self.entryid = 0;
        self.episodes = 0;
        self.episode_length = 0;
        self.image_url = @"";
        self.type = @"";
        self.status = @"";
        self.watched_status = @"";
        self.watched_episodes = 0;
        self.score = 0;
        self.score_type = 0;
        self.watching_start = @"";
        self.watching_end = @"";
        self.rewatching = false;
        self.rewatch_count = 0;
        self.personal_comments = @"";
        self.custom_lists = @"";
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{ @"id" : @(_titleid), @"entryid" : @(_entryid), @"title" : _title.copy, @"episodes" : @(_episodes), @"duration" : @(_episode_length), @"image_url": _image_url.copy, @"type" : _type.copy, @"status" : _status.copy, @"watched_status" : _watched_status.copy, @"watched_episodes" : @(_watched_episodes), @"score" : @(_score), @"score_type" : @(_score_type), @"watching_start" : _watching_start.copy, @"watching_end" : _watching_end.copy, @"rewatching" : @(_rewatching), @"rewatch_count" : @(_rewatch_count), @"personal_comments" : _personal_comments.copy, @"private": @(_private_entry), @"custom_lists" : _custom_lists, @"last_updated" : @(_lastupdated)};
}
@end

@implementation AtarashiiMangaListObject
- (id)init {
    self = [super init];
    if (self) {
        self.titleid = 0;
        self.title = @"";
        self.entryid = 0;
        self.chapters = 0;
        self.volumes = 0;
        self.image_url = @"";
        self.type = @"";
        self.status = @"";
        self.read_status = @"";
        self.chapters_read = 0;
        self.volumes_read = 0;
        self.score = 0;
        self.score_type = 0;
        self.reading_start = @"";
        self.reading_end = @"";
        self.rereading = false;
        self.reread_count = 0;
        self.personal_comments = @"";
        self.custom_lists = @"";
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{ @"id" : @(_titleid), @"entryid" : @(_entryid), @"title" : _title.copy, @"chapters" : @(_chapters), @"volumes" : @(_volumes), @"image_url": _image_url.copy, @"type" : _type.copy, @"status" : _status.copy, @"read_status" : _read_status.copy, @"chapters_read" : @(_chapters_read), @"volumes_read" : @(_volumes_read), @"score" : @(_score), @"score_type" : @(_score_type), @"reading_start" : _reading_start.copy, @"reading_end" : _reading_end.copy, @"rereading" : @(_rereading), @"reread_count" : @(_reread_count), @"personal_comments" : _personal_comments.copy, @"private": @(_private_entry), @"custom_lists" : _custom_lists, @"last_updated" : @(_lastupdated)};
}
@end

@implementation AtarashiiPersonObject
- (id)init {
    self = [super init];
    if (self) {
        _personid = 0;
        _name = @"";
        _alternate_names = @[];
        _given_name = @"";
        _familyname = @"";
        _native_name = @"";
        _birthdate = @"";
        _website_url = @"";
        _image_url = @"";
        _more_details = @"";
        _favorited_count = 0;
        _language = @"";
        _voice_acting_roles = @[];
        _voice_actors = @[];
        _anime_staff_positions = @[];
        _published_manga = @[];
        _appeared_anime = @[];
        _appeared_manga = @[];
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{@"id" : @(_personid), @"name" : _name.copy, @"alternate_names" : _alternate_names.copy, @"family_name" : _familyname.copy, @"native_name" : _native_name, @"birthdate" : _birthdate.copy, @"website_url" : _website_url.copy, @"image_url" : _image_url.copy, @"more_details" : _more_details.copy, @"favorited_count" : @(_favorited_count), @"language" : _language.copy, @"voice_acting_roles" : _voice_acting_roles.copy, @"anime_staff_positions" : _anime_staff_positions.copy, @"published_manga" : _published_manga.copy, @"appeared_anime" : _appeared_anime.copy, @"appeared_manga" : _appeared_manga.copy, @"actors" : _voice_actors.copy};
}
@end

@implementation AtarashiiVoiceActingRoleObject
- (id)init {
    self = [super init];
    if (self) {
        _characterid = 0;
        _name = @"";
        _image_url = @"";
        _main_role = false;
        _anime = @{};
        _manga = @{};
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{@"id" : @(_characterid), @"name" : _name.copy, @"image_url" : _image_url.copy, @"main_role" : @(_main_role), @"anime" : _anime.copy, @"manga": _manga.copy};
}
@end

@implementation AtarrashiiStaffObject
- (id)init {
    self = [super init];
    if (self) {
        _position = @"";
        _details = @"";
        _anime = @{};
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{@"position" : _position.copy, @"details" : _details.copy, @"anime" : _anime.copy};
}
@end

@implementation AtarashiiPublishedMangaObject
- (id)init {
    self = [super init];
    if (self) {
        _position = @"";
        _manga = @{};
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{@"position" : _position.copy, @"manga" : _manga.copy};
}
@end

@implementation AtarashiiReviewObject
- (id)init {
    self = [super init];
    if (self) {
        self.username = @"";
        self.date = @"";
        self.avatar_url = @"";
        self.review = @"";
        self.actual_username = @"";
    }
    return self;
}
- (NSDictionary *)NSDictionaryRepresentation {
    if (self.mediatype == 0) {
        return @{@"date" : _date.copy, @"rating" : @(_rating), @"username" : _username, @"actual_username" : _actual_username.copy, @"episodes" : @(_episodes), @"watched_episodes" : @(_watched_episodes), @"helpful" : @(_helpful), @"helpful_total" : @(_helpful_total), @"avatar_url" : _avatar_url.copy, @"review" : _review.copy };
    }
    else if (self.mediatype == 1) {
        return @{@"date" : _date.copy, @"rating" : @(_rating), @"username" : _username.copy, @"actual_username" : _actual_username.copy, @"chapters" : @(_chapters), @"read_chapters" : @(_read_chapters), @"helpful" : @(_helpful), @"helpful_total" : @(_helpful_total), @"avatar_url" : _avatar_url.copy, @"review" : _review.copy };
    }
    return @{};
}
@end

@implementation AtarashiiEpisodeObject
- (id)init {
    self = [super init];
    if (self) {
        self.episodeTitle = @"";
        self.airDate = @"";
        self.thumbnail = @"";
        self.synopsis = @"";
    }
    return self;
}
- (NSDictionary *)NSDictionaryRepresentation {
    return @{@"titleId" : @(_titleId), @"episodeId" : @(_episodeId), @"episodeTitle" : _episodeTitle, @"episodeNumber" : @(_episodeNumber), @"airDate" : _airDate, @"episodeLength" : @(_episodeLength), @"thumbnail" : _thumbnail, @"synopsis" : _synopsis};
}
@end

@implementation AtarashiiUserObject
- (id)init {
    self = [super init];
    if (self) {
        self.avatar_url = @"";
        self.last_online = @"";
        self.gender = @"";
        self.birthday = @"";
        self.location = @"";
        self.website = @"";
        self.join_date = @"";
        self.access_rank = @"";
        self.anime_list_views = 0;
        self.manga_list_views = 0;
        self.forum_posts = 0;
        self.reviews = 0;
        self.recommendations = 0;
        self.blog_posts = 0;
        self.clubs = 0;
        self.comments = 0;
        self.extradict = @{};
    }
    return self;
}
- (NSDictionary *)NSDictionaryRepresentation {
    return @{@"avatar_url" : _avatar_url.copy, @"details" : @{@"last_online" : _last_online.copy, @"gender" :  _gender.copy, @"birthday" : _birthday.copy, @"location" : _location.copy, @"website" : _website.copy, @"join_date" : _join_date.copy, @"access_rank" : _access_rank.copy, @"anime_list_views" : @(_anime_list_views), @"manga_list_views" : @(_manga_list_views), @"forum_posts" : @(_forum_posts), @"reviews" : @(_reviews), @"recommendations" : @(_recommendations), @"blog_posts" : @(_blog_posts), @"clubs" : @(_clubs), @"comments" : @(_comments), @"extra" : _extradict}};
}
@end
