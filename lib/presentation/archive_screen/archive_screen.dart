import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_export.dart';
import '../../services/episode_archive_service.dart';
import '../../widgets/episode_detail_modal.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final EpisodeArchiveService _archiveService = EpisodeArchiveService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _archivedEpisodes = [];
  Map<String, dynamic>? _pagination;
  Map<String, dynamic>? _stats;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String _searchQuery = '';

  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _loadArchivedEpisodes();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchivedEpisodes({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });
    } else if (_isLoadingMore) {
      return;
    }

    try {
      final result = await _archiveService.getArchivedEpisodes(
        perPage: _perPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (result['success'] == true) {
        final episodes = List<Map<String, dynamic>>.from(result['data'] ?? []);
        final pagination = result['pagination'];

        setState(() {
          if (refresh || _currentPage == 1) {
            _archivedEpisodes = episodes;
          } else {
            _archivedEpisodes.addAll(episodes);
          }
          _pagination = pagination;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Failed to load archived episodes'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading archived episodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await _archiveService.getArchiveStats();
      if (result['success'] == true) {
        setState(() {
          _stats = result['data'];
        });
      }
    } catch (e) {
      debugPrint('Error loading archive stats: $e');
    }
  }

  Future<void> _loadMoreEpisodes() async {
    if (_pagination == null || _currentPage >= _pagination!['last_page']) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadArchivedEpisodes();
  }

  Future<void> _searchEpisodes(String query) async {
    setState(() {
      _isSearching = true;
      _searchQuery = query;
      _currentPage = 1;
    });

    await _loadArchivedEpisodes(refresh: true);

    setState(() {
      _isSearching = false;
    });
  }

  Future<void> _unarchiveEpisode(String episodeId, String episodeTitle) async {
    try {
      final result = await _archiveService.unarchiveEpisode(episodeId);

      if (result['success'] == true) {
        // Remove from list
        setState(() {
          _archivedEpisodes
              .removeWhere((episode) => episode['episode_id'] == episodeId);
        });

        // Refresh stats
        _loadStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.unarchive, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('$episodeTitle unarchived'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to unarchive episode'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unarchiving episode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkUnarchive() async {
    if (_archivedEpisodes.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unarchive All Episodes'),
        content: Text(
            'Are you sure you want to unarchive all ${_archivedEpisodes.length} episodes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unarchive All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final episodeIds = _archivedEpisodes
          .map((episode) => episode['episode_id'].toString())
          .toList();

      final result = await _archiveService.bulkUnarchive(episodeIds);

      if (result['success'] == true) {
        setState(() {
          _archivedEpisodes.clear();
        });

        // Refresh stats
        _loadStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.unarchive, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('${result['deleted_count']} episodes unarchived'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to bulk unarchive'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error bulk unarchiving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEpisodeDetail(Map<String, dynamic> episode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        Container(
          width: double.infinity,
          height: double.infinity,
          child: EpisodeDetailModal(
            episode: episode,
            episodes: [episode], // Single episode for detail view
            episodeIndex: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Episodes'),
        actions: [
          if (_archivedEpisodes.isNotEmpty)
            IconButton(
              onPressed: _bulkUnarchive,
              icon: const Icon(Icons.unarchive),
              tooltip: 'Unarchive All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search archived episodes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchEpisodes(value);
                  }
                });
              },
            ),
          ),

          // Stats card
          if (_stats != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.archive,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_stats!['total_archives']} Archived Episodes',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_stats!['unique_podcasts']} podcasts • ${_stats!['recent_archives']} this week',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Episodes list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _archivedEpisodes.isEmpty
                    ? _buildEmptyState()
                    : _buildEpisodesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching episodes found'
                : 'No archived episodes',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Archive episodes to see them here',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    return RefreshIndicator(
      onRefresh: () => _loadArchivedEpisodes(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _archivedEpisodes.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _archivedEpisodes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final episode = _archivedEpisodes[index];
          return _buildEpisodeCard(episode);
        },
      ),
    );
  }

  Widget _buildEpisodeCard(Map<String, dynamic> episode) {
    final episodeTitle = episode['episode_title'] ?? 'Unknown Episode';
    final podcastTitle = episode['podcast_title'] ?? 'Unknown Podcast';
    final archivedAt = episode['archived_at'];
    final episodeId = episode['episode_id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.archive,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          episodeTitle,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              podcastTitle,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Archived ${_formatDate(archivedAt)}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showEpisodeDetail(episode);
                break;
              case 'unarchive':
                _unarchiveEpisode(episodeId, episodeTitle);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'unarchive',
              child: Row(
                children: [
                  Icon(Icons.unarchive, size: 20),
                  SizedBox(width: 8),
                  Text('Unarchive'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showEpisodeDetail(episode),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}
