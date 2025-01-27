class Tag {
  final String username;

  Tag({
    required this.username,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      username: json['user']['username'] ?? '',
    );
  }
}

class VideoPost {
  final String id;
  final String parentVideoId;
  final String username;
  final String profileImage;
  final String activityStatus;
  final String description;
  final String videoUrl;
  final String thumbUrl;
  final int likeCount;
  final int tagCount;
  final int commentCount;
  final int shareCount;
  final String upvoted;
  final List<Tag> tags; // Updated to use Tag objects

  VideoPost({
    required this.id,
    required this.parentVideoId,
    required this.username,
    required this.profileImage,
    required this.activityStatus,
    required this.description,
    required this.videoUrl,
    required this.thumbUrl,
    required this.likeCount,
    required this.tagCount,
    required this.commentCount,
    required this.shareCount,
    required this.upvoted,
    required this.tags,
  });

  factory VideoPost.fromJson(Map<String, dynamic> json) {
    return VideoPost(
      id: json['id'] ?? '',
      parentVideoId: json['parent_video_id'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['picture_url'] ?? '',
      activityStatus: json['following'] ? 'Following' : 'Not Following',
      description: json['title'] ?? '',
      videoUrl: json['video_link'] ?? '',
      thumbUrl: json['thumbnail_url'] ?? '',
      likeCount: json['upvote_count'] ?? 0,
      tagCount: json['tag_count'] ?? 0,
      commentCount: json['voting_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      upvoted: json['upvoted'] ? '1' : '0',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tagJson) => Tag.fromJson(tagJson))
              .toList() ??
          [],
    );
  }
}