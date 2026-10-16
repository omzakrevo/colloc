import 'package:flutter/material.dart';

import '../models.dart';
import '../util/format.dart';
import 'theme.dart';

class PhotoView extends StatelessWidget {
  const PhotoView({
    super.key,
    required this.photo,
    required this.kind,
    this.fit = BoxFit.cover,
  });
  final Photo? photo;
  final ListingKind kind;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final c = kindColor(kind);
    final placeholder = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.withValues(alpha: .15), c.withValues(alpha: .35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(kindIcon(kind), size: 44, color: c.withValues(alpha: .7)),
      ),
    );
    final p = photo;
    if (p == null) return placeholder;
    if (p.bytes != null) return Image.memory(p.bytes!, fit: fit);
    return Image.network(
      p.url!,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class KindBadge extends StatelessWidget {
  const KindBadge(this.kind, {super.key});
  final ListingKind kind;
  @override
  Widget build(BuildContext context) {
    final c = kindColor(kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kindIcon(kind), size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            kind.label,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});
  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 120,
                child: PhotoView(
                  photo: l.photos.isEmpty ? null : l.photos.first,
                  kind: l.kind,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KindBadge(l.kind),
                      const SizedBox(height: 6),
                      Text(
                        l.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 14),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${l.neighborhood.isEmpty ? '' : '${l.neighborhood}, '}${l.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.kind == ListingKind.request
                            ? "Budget : ${fcfa(l.rent)}/mois"
                            : '${fcfa(l.rent)}/mois',
                        style: t.titleSmall?.copyWith(
                          color: kBrand,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${l.ownerName} · ${ago(l.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void toast(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );
