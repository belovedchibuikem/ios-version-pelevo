import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../data/models/podcast.dart';
import '../../data/repositories/podcast_repository.dart';
import '../../core/utils/mini_player_positioning.dart';
import './widgets/featured_podcast_card_widget.dart';

class SeeAllPodcastsScreen extends StatefulWidget {
  const SeeAllPodcastsScreen({super.key});

  @override
  State<SeeAllPodcastsScreen> createState() => _SeeAllPodcastsScreenState();
}

class _SeeAllPodcastsScreenState extends State<SeeAllPodcastsScreen> {
  final PodcastRepository _podcastRepository = PodcastRepository();
  List<Podcast> _podcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  Future<void> _loadPodcasts() async {
    try {
      final podcasts = await _podcastRepository.getTrendingPodcasts();
      setState(() {
        _podcasts = podcasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Podcasts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _podcasts.isEmpty
              ? const Center(child: Text('No podcasts found'))
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 5.w,
                    right: 5.w,
                    top: 2.h,
                    bottom: MiniPlayerPositioning.bottomPaddingForScrollables(),
                  ),
                  itemCount: _podcasts.length,
                  itemBuilder: (context, index) {
                    final podcast = _podcasts[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: FeaturedPodcastCardWidget(
                        podcast: podcast.toJson(),
                        isSubscribed: false,
                        onTap: () {
                          // Handle podcast tap
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
