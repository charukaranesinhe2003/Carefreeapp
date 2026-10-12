import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../nav.dart';
import '../theme.dart';
import '../widgets.dart';
import 'details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(String value) {
    final app = AppScope.of(context);
    app.setSearch(value);
    app.rememberSearch(value);
    goTab(context, 0);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final query = _controller.text.trim();
    final suggestions = searchSuggestions(query);

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  const BackButtonRound(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {});
                        AppScope.of(context).setSearch(value);
                      },
                      onSubmitted: _go,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search area or place...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded, color: Color(0xFFE7B3CC)),
                              ),
                        fillColor: const Color(0xFFFFF8FB),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                children: [
                  if (query.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        app.liveLoading ? 'UPDATING NEAREST PLACES...' : 'NEAREST PHARMACIES AND CLINICS',
                        style: const TextStyle(
                          color: Color(0xFFB0A8AE),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    if (app.liveLoading)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: LinearProgressIndicator(minHeight: 3, color: AppColors.primary, backgroundColor: Color(0xFFF6C6E0)),
                      ),
                    if (app.results.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: Text('No pharmacies or clinics match yet', style: TextStyle(color: AppColors.muted)),
                      ),
                    for (var i = 0; i < app.results.length; i++)
                      RiseIn(
                        index: i,
                        child: _SearchRow(
                          icon: app.results[i].kind == PlaceKind.clinic ? Icons.local_hospital_rounded : Icons.local_pharmacy_rounded,
                          iconColor: AppColors.primary,
                          place: app.results[i],
                          title: app.results[i].name,
                          subtitle: '${app.results[i].kindLabel} · ${app.results[i].area} · ${app.distanceLabel(app.results[i])}',
                          onTap: () {
                            app.rememberSearch(query);
                            openPlace(context, app.results[i]);
                          },
                        ),
                      ),
                  ],
                  if (query.isEmpty && suggestions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        'MATCHES',
                        style: TextStyle(
                          color: Color(0xFFB0A8AE),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    for (var i = 0; i < suggestions.length; i++)
                      RiseIn(
                        index: i,
                        child: _SearchRow(
                          icon: Icons.place_rounded,
                          iconColor: AppColors.primary,
                          title: suggestions[i],
                          subtitle: 'Open this result',
                          onTap: () => _go(suggestions[i]),
                        ),
                      ),
                  ],
                  if (query.isEmpty) Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 4, 4),
                    child: Row(
                      children: [
                        const Text(
                          'RECENT SEARCHES',
                          style: TextStyle(
                            color: Color(0xFFB0A8AE),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const Spacer(),
                        if (app.recentSearches.isNotEmpty)
                          TextButton(
                            onPressed: app.clearSearches,
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (query.isEmpty && app.recentSearches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: Text('No searches yet', style: TextStyle(color: AppColors.muted)),
                    ),
                  if (query.isEmpty)
                  for (var i = 0; i < app.recentSearches.length; i++)
                    RiseIn(
                      index: i + 1,
                      child: _SearchRow(
                        icon: Icons.history_rounded,
                        iconColor: AppColors.primary,
                        title: app.recentSearches[i].query,
                        subtitle: app.recentSearches[i].when,
                        onTap: () => _go(app.recentSearches[i].query),
                        onDelete: () => app.deleteSearch(app.recentSearches[i].query),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onDelete,
    this.place,
  });

  final IconData icon;
  final Color iconColor;
  final Place? place;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            if (place != null)
              SizedBox(
                width: 52,
                height: 52,
                child: PlacePhoto(place: place!, height: 52, radius: 12),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded, color: AppColors.primary, size: 18),
              )
            else
              const Icon(Icons.north_east_rounded, color: Color(0xFFD4D0D2), size: 16),
          ],
        ),
      ),
    );
  }
}
