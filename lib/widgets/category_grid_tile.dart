import 'package:flutter/material.dart';
import '../models/category_group_model.dart';
import '../models/category_model.dart';
import 'unread_badge.dart';

// The circular icon + label tile used by both the top-level category grid
// (explore_fragment.dart) and the sub-category grid (subcategories_screen.dart)
// — extracted so nesting didn't require duplicating this markup.
class CategoryGridTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryGridTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
              if (category.isProtected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: category.color,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: category.color,
                    ),
                  ),
                ),
              Positioned(
                top: -2,
                right: -2,
                child: UnreadBadge(categoryId: category.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Expanded confines the label to whatever height the grid cell has
          // left after the icon — without it, a long name wrapping to 2
          // lines can be taller than the cell's fixed aspect-ratio height
          // and overflow instead of truncating.
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid tile for a category group (the level above main categories) — same
/// footprint as CategoryGridTile, but a rounded square with a stacked
/// "layers" badge so groups read as containers rather than topics.
class CategoryGroupTile extends StatelessWidget {
  final CategoryGroup group;
  final int mainCount;
  final VoidCallback onTap;

  const CategoryGroupTile({
    super.key,
    required this.group,
    required this.mainCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [group.color, group.color.withAlpha(190)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: group.color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(group.icon, color: Colors.white, size: 44),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: group.color, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_rounded, size: 11, color: group.color),
                      const SizedBox(width: 2),
                      Text(
                        '$mainCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: group.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                group.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
