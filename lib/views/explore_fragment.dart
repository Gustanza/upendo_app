import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/category_service.dart';
import '../utils/category_navigation.dart';
import '../utils/category_tree.dart';
import '../widgets/category_grid_tile.dart';

class ExploreFragment extends StatefulWidget {
  const ExploreFragment({super.key});

  @override
  State<ExploreFragment> createState() => _ExploreFragmentState();
}

class _ExploreFragmentState extends State<ExploreFragment> {
  // Created once so tab switches/rebuilds don't reattach the listeners.
  late final Stream<CategoryTree> _tree = CategoryService().watchTree();

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 15,
    mainAxisSpacing: 25,
    childAspectRatio: 0.8,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00AEEF), // Light Blue
                Color(0xFF00008B), // Dark Blue
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 60,
            left: 20,
            right: 20,
            bottom: 30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed:
                    () {}, // Optional: Handle back if this was a separate screen
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.exploreTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.exploreSubtitle,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),

        // Grid: category groups first, then main categories that aren't in
        // any group (all of them, until an admin creates groups). A
        // category that's someone else's child never appears here — it
        // only shows up inside that parent's SubcategoriesScreen.
        Expanded(
          child: StreamBuilder<CategoryTree>(
            stream: _tree,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(context.l10n.errorWithDetails('${snapshot.error}')),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tree = snapshot.data!;
              if (!tree.hasGroups && tree.ungroupedMains.isEmpty) {
                return Center(child: Text(context.l10n.noCategoriesNow));
              }

              return CustomScrollView(
                slivers: [
                  if (tree.hasGroups) ...[
                    _sectionHeader(context.l10n.categoryGroupsTitle),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      sliver: SliverGrid.builder(
                        gridDelegate: _gridDelegate,
                        itemCount: tree.groups.length,
                        itemBuilder: (context, index) {
                          final group = tree.groups[index];
                          return CategoryGroupTile(
                            group: group,
                            mainCount: tree.mainsIn(group.id).length,
                            onTap: () => openCategoryGroup(context, group),
                          );
                        },
                      ),
                    ),
                    if (tree.ungroupedMains.isNotEmpty)
                      _sectionHeader(context.l10n.otherCategoriesTitle),
                  ],
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, tree.hasGroups ? 0 : 20, 20, 110),
                    sliver: SliverGrid.builder(
                      gridDelegate: _gridDelegate,
                      itemCount: tree.ungroupedMains.length,
                      itemBuilder: (context, index) {
                        final category = tree.ungroupedMains[index];
                        return CategoryGridTile(
                          category: category,
                          onTap: () => openCategory(
                            context,
                            category,
                            hasChildren: tree.hasChildren(category),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1D2E),
          ),
        ),
      ),
    );
  }
}
