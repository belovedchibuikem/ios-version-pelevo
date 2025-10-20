import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../data/models/podcast.dart';
import '../../core/utils/mini_player_positioning.dart';
import './widgets/featured_podcast_card_widget.dart';

class RecommendationsScreen extends StatefulWidget {
  final List<Podcast> podcasts;
  const RecommendationsScreen({Key? key, required this.podcasts})
      : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  String _search = '';
  bool _isGrid = false;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.podcasts
        .where((p) => p.title.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended for You'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGrid = !_isGrid),
            tooltip: _isGrid ? 'List view' : 'Grid view',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search podcasts...',
                prefixIcon: Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('No podcasts found'))
                : _isGrid
                    ? GridView.builder(
                        padding: EdgeInsets.only(
                          left: 4.w,
                          right: 4.w,
                          top: 2.h,
                          bottom: MiniPlayerPositioning
                              .bottomPaddingForScrollables(),
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 2.h,
                          crossAxisSpacing: 4.w,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => FeaturedPodcastCardWidget(
                          podcast: filtered[i].toJson(),
                          isSubscribed: false,
                          onTap: () {},
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          left: 4.w,
                          right: 4.w,
                          top: 2.h,
                          bottom: MiniPlayerPositioning
                              .bottomPaddingForScrollables(),
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: FeaturedPodcastCardWidget(
                            podcast: filtered[i].toJson(),
                            isSubscribed: false,
                            onTap: () {},
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
