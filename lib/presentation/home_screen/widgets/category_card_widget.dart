import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/home_screen/widgets/category_card_widget.dart

class CategoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const CategoryCardWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use stable count display - no randomization to prevent rebuilds
    String displayCount;
    int count = int.tryParse(category["count"].toString()) ?? 0;
    if (count == 0) {
      // Use a stable fallback count instead of random
      displayCount = "250";
    } else if (count >= 1000) {
      displayCount =
          "${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k";
    } else {
      displayCount = count.toString();
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(int.parse(category["gradientStart"])),
              Color(int.parse(category["gradientEnd"])),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Category Icon
              Container(
                padding: EdgeInsets.all(2.5.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildCategoryIcon(),
              ),
              SizedBox(height: 1.5.h),
              // Category Name
              Text(
                category["name"] ?? "",
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              // Podcast Count
              Text(
                "$displayCount podcasts",
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    final icon = category["icon"];
    if (icon == null) {
      return const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 20,
      );
    }

    // Check if the icon is a URL (starts with http)
    if (icon.toString().startsWith('http')) {
      return CustomImageWidget(
        imageUrl: icon,
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      );
    }

    // Otherwise, treat it as a Material icon name
    return Icon(
      _getMaterialIcon(icon.toString()),
      color: Colors.white,
      size: 20,
    );
  }

  IconData _getMaterialIcon(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'sentiment_very_satisfied':
        return Icons.sentiment_very_satisfied;
      case 'gavel':
        return Icons.gavel;
      case 'school':
        return Icons.school;
      case 'newspaper':
        return Icons.newspaper;
      case 'business':
        return Icons.business;
      case 'science':
        return Icons.science;
      case 'computer':
        return Icons.computer;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'favorite':
        return Icons.favorite;
      case 'palette':
        return Icons.palette;
      case 'account_balance':
        return Icons.account_balance;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'podcasts':
        return Icons.podcasts;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'sports_football':
        return Icons.sports_football;
      case 'sports_hockey':
        return Icons.sports_hockey;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'sports_volleyball':
        return Icons.sports_volleyball;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'healing':
        return Icons.healing;
      case 'psychology':
        return Icons.psychology;
      case 'theater_comedy':
        return Icons.theater_comedy;
      case 'movie':
        return Icons.movie;
      case 'tv':
        return Icons.tv;
      case 'radio':
        return Icons.radio;
      case 'book':
        return Icons.book;
      case 'library_books':
        return Icons.library_books;
      case 'history_edu':
        return Icons.history_edu;
      case 'public':
        return Icons.public;
      case 'language':
        return Icons.language;
      case 'translate':
        return Icons.translate;
      case 'church':
        return Icons.church;
      case 'mosque':
        return Icons.mosque;
      case 'synagogue':
        return Icons.synagogue;
      case 'temple_buddhist':
        return Icons.temple_buddhist;
      case 'temple_hindu':
        return Icons.temple_hindu;
      case 'politics':
        return Icons.policy;
      case 'security':
        return Icons.security;
      case 'local_police':
        return Icons.local_police;
      case 'flight':
        return Icons.flight;
      case 'directions_car':
        return Icons.directions_car;
      case 'train':
        return Icons.train;
      case 'directions_boat':
        return Icons.directions_boat;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_bar':
        return Icons.local_bar;
      case 'coffee':
        return Icons.coffee;
      case 'cake':
        return Icons.cake;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'spa':
        return Icons.spa;
      case 'wellness':
        return Icons.health_and_safety;
      case 'child_care':
        return Icons.child_care;
      case 'elderly':
        return Icons.elderly;
      case 'pets':
        return Icons.pets;
      case 'nature':
        return Icons.nature;
      case 'landscape':
        return Icons.landscape;
      case 'forest':
        return Icons.forest;
      case 'beach_access':
        return Icons.beach_access;
      case 'park':
        return Icons.park;
      case 'agriculture':
        return Icons.agriculture;
      case 'eco':
        return Icons.eco;
      case 'recycling':
        return Icons.recycling;
      case 'solar_power':
        return Icons.solar_power;
      case 'wind_power':
        return Icons.wind_power;
      case 'electric_car':
        return Icons.electric_car;
      case 'architecture':
        return Icons.architecture;
      case 'construction':
        return Icons.construction;
      case 'engineering':
        return Icons.engineering;
      case 'precision_manufacturing':
        return Icons.precision_manufacturing;
      case 'factory':
        return Icons.factory;
      case 'warehouse':
        return Icons.warehouse;
      case 'store':
        return Icons.store;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'payment':
        return Icons.payment;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'analytics':
        return Icons.analytics;
      case 'insights':
        return Icons.insights;
      case 'data_usage':
        return Icons.data_usage;
      case 'code':
        return Icons.code;
      case 'developer_mode':
        return Icons.developer_mode;
      case 'bug_report':
        return Icons.bug_report;
      case 'build':
        return Icons.build;
      case 'settings':
        return Icons.settings;
      case 'tune':
        return Icons.tune;
      case 'wifi':
        return Icons.wifi;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'smartphone':
        return Icons.smartphone;
      case 'laptop':
        return Icons.laptop;
      case 'tablet':
        return Icons.tablet;
      case 'desktop_windows':
        return Icons.desktop_windows;
      case 'headphones':
        return Icons.headphones;
      case 'speaker':
        return Icons.speaker;
      case 'mic':
        return Icons.mic;
      case 'videocam':
        return Icons.videocam;
      case 'photo_camera':
        return Icons.photo_camera;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'videocam_off':
        return Icons.videocam_off;
      case 'mic_off':
        return Icons.mic_off;
      case 'volume_up':
        return Icons.volume_up;
      case 'volume_down':
        return Icons.volume_down;
      case 'volume_off':
        return Icons.volume_off;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'pause':
        return Icons.pause;
      case 'stop':
        return Icons.stop;
      case 'skip_next':
        return Icons.skip_next;
      case 'skip_previous':
        return Icons.skip_previous;
      case 'fast_forward':
        return Icons.fast_forward;
      case 'fast_rewind':
        return Icons.fast_rewind;
      case 'shuffle':
        return Icons.shuffle;
      case 'repeat':
        return Icons.repeat;
      case 'queue_music':
        return Icons.queue_music;
      case 'playlist_play':
        return Icons.playlist_play;
      case 'library_music':
        return Icons.library_music;
      case 'album':
        return Icons.album;
      case 'audiotrack':
        return Icons.audiotrack;
      case 'graphic_eq':
        return Icons.graphic_eq;
      case 'equalizer':
        return Icons.equalizer;
      case 'trending_down':
        return Icons.trending_down;
      case 'show_chart':
        return Icons.show_chart;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'bubble_chart':
        return Icons.bubble_chart;
      case 'scatter_plot':
        return Icons.scatter_plot;
      case 'timeline':
        return Icons.timeline;
      case 'schedule':
        return Icons.schedule;
      case 'event':
        return Icons.event;
      case 'today':
        return Icons.today;
      case 'date_range':
        return Icons.date_range;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'access_time':
        return Icons.access_time;
      case 'access_time_filled':
        return Icons.access_time_filled;
      case 'update':
        return Icons.update;
      case 'sync':
        return Icons.sync;
      case 'sync_alt':
        return Icons.sync_alt;
      case 'cloud':
        return Icons.cloud;
      case 'cloud_upload':
        return Icons.cloud_upload;
      case 'cloud_download':
        return Icons.cloud_download;
      case 'cloud_sync':
        return Icons.cloud_sync;
      case 'folder':
        return Icons.folder;
      case 'folder_open':
        return Icons.folder_open;
      case 'folder_shared':
        return Icons.folder_shared;
      case 'create_new_folder':
        return Icons.create_new_folder;
      case 'drive_file_move':
        return Icons.drive_file_move;
      case 'drive_file_rename_outline':
        return Icons.drive_file_rename_outline;
      case 'drive_folder_upload':
        return Icons.drive_folder_upload;
      case 'file_download':
        return Icons.file_download;
      case 'file_upload':
        return Icons.file_upload;
      case 'file_copy':
        return Icons.file_copy;
      case 'file_present':
        return Icons.file_present;
      case 'description':
        return Icons.description;
      case 'article':
        return Icons.article;
      case 'text_snippet':
        return Icons.text_snippet;
      case 'note':
        return Icons.note;
      case 'note_add':
        return Icons.note_add;
      case 'edit_note':
        return Icons.edit_note;
      case 'sticky_note_2':
        return Icons.sticky_note_2;
      case 'draw':
        return Icons.draw;
      case 'brush':
        return Icons.brush;
      case 'format_paint':
        return Icons.format_paint;
      case 'color_lens':
        return Icons.color_lens;
      case 'gradient':
        return Icons.gradient;
      case 'opacity':
        return Icons.opacity;
      case 'style':
        return Icons.style;
      case 'texture':
        return Icons.texture;
      case 'filter':
        return Icons.filter;
      case 'filter_list':
        return Icons.filter_list;
      case 'filter_alt':
        return Icons.filter_alt;
      case 'filter_alt_off':
        return Icons.filter_alt_off;
      case 'sort':
        return Icons.sort;
      case 'sort_by_alpha':
        return Icons.sort_by_alpha;
      case 'search':
        return Icons.search;
      case 'search_off':
        return Icons.search_off;
      case 'manage_search':
        return Icons.manage_search;
      case 'find_in_page':
        return Icons.find_in_page;
      case 'find_replace':
        return Icons.find_replace;
      case 'pageview':
        return Icons.pageview;
      case 'zoom_in':
        return Icons.zoom_in;
      case 'zoom_out':
        return Icons.zoom_out;
      case 'fullscreen':
        return Icons.fullscreen;
      case 'fullscreen_exit':
        return Icons.fullscreen_exit;
      case 'crop':
        return Icons.crop;
      case 'crop_free':
        return Icons.crop_free;
      case 'crop_landscape':
        return Icons.crop_landscape;
      case 'crop_portrait':
        return Icons.crop_portrait;
      case 'crop_square':
        return Icons.crop_square;
      case 'crop_rotate':
        return Icons.crop_rotate;
      case 'crop_din':
        return Icons.crop_din;
      case 'crop_original':
        return Icons.crop_original;
      case 'crop_16_9':
        return Icons.crop_16_9;
      case 'crop_3_2':
        return Icons.crop_3_2;
      case 'crop_5_4':
        return Icons.crop_5_4;
      case 'crop_7_5':
        return Icons.crop_7_5;
      default:
        return Icons.podcasts;
    }
  }
}
