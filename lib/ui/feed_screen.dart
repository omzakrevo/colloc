import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import 'detail_screen.dart';
import 'widgets.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final f = s.filter;
    Widget chip(String label, ListingKind? k) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: f.kind == k,
        onSelected: (_) => s.setFilter(
          ListingFilter(kind: k, query: f.query, maxRent: f.maxRent),
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: s.refresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text(
              'Colloc',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Ville, quartier, mot-clé…',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        suffixIcon: f.query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  s.setFilter(
                                    ListingFilter(
                                      kind: f.kind,
                                      maxRent: f.maxRent,
                                    ),
                                  );
                                },
                              ),
                      ),
                      onSubmitted: (v) => s.setFilter(
                        ListingFilter(
                          kind: f.kind,
                          query: v,
                          maxRent: f.maxRent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          chip('Tout', null),
                          chip('Colocations', ListingKind.offer),
                          chip('Demandes', ListingKind.request),
                          chip('Agences', ListingKind.agency),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (s.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (s.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.error!),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: s.refresh,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (s.listings.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucune annonce pour le moment.\nSoyez le premier à publier !',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: s.listings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListingCard(
                      listing: s.listings[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(listing: s.listings[i]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
