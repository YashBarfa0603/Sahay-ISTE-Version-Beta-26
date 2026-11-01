/// Model representing a verified YouTube video tutorial for applying to a government scheme.
class YouTubeTutorialModel {
  final String schemeId;
  final String videoId;
  final String videoTitle;
  final String videoTitleHindi;
  final String youtubeUrl;
  final String thumbnailUrl;
  final String channelName;
  final String language;
  final String? duration;
  final bool isVerified;
  final String? description;
  final String? descriptionHindi;

  const YouTubeTutorialModel({
    required this.schemeId,
    required this.videoId,
    required this.videoTitle,
    required this.videoTitleHindi,
    required this.youtubeUrl,
    required this.thumbnailUrl,
    required this.channelName,
    required this.language,
    this.duration,
    this.isVerified = true,
    this.description,
    this.descriptionHindi,
  });

  factory YouTubeTutorialModel.fromVideoId({
    required String schemeId,
    required String videoId,
    required String videoTitle,
    required String videoTitleHindi,
    required String channelName,
    required String language,
    String? duration,
    String? description,
    String? descriptionHindi,
    String? customUrl,
  }) {
    return YouTubeTutorialModel(
      schemeId: schemeId,
      videoId: videoId,
      videoTitle: videoTitle,
      videoTitleHindi: videoTitleHindi,
      youtubeUrl: customUrl ?? 'https://www.youtube.com/watch?v=$videoId',
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
      channelName: channelName,
      language: language,
      duration: duration,
      description: description,
      descriptionHindi: descriptionHindi,
    );
  }
}

