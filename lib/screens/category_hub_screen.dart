import 'package:flutter/material.dart';

class CategoryHubArguments {
  final String id;
  final String title;
  const CategoryHubArguments({required this.id, required this.title});
}

class CategoryHubScreen extends StatelessWidget {
  const CategoryHubScreen({super.key});

  static const String routeName = '/category_hub';

  static List<_HubItem> _itemsFor(String categoryId) {
    switch (categoryId) {
      case 'mwanandoa':
        return const [
          _HubItem(title: 'Usajili', subtitle: 'Jisajili kwa majina, simu, nchi, mkoa, wilaya', icon: Icons.person_add),
          _HubItem(title: 'Ushauri nasaha', subtitle: 'Simu Tsh 10,000 · SMS Tsh 5,000', icon: Icons.phone_in_talk),
          _HubItem(title: 'Utatuzi wa mgogoro', subtitle: 'Simu Tsh 20,000 · SMS Tsh 15,000', icon: Icons.handshake),
          _HubItem(title: 'Semina za ndoa', subtitle: 'Simu / SMS / Ukumbi', icon: Icons.school),
          _HubItem(title: 'Semina za ujasiriamali', subtitle: 'Simu / SMS / Ukumbi', icon: Icons.business_center),
          _HubItem(title: 'Semina za afya ya akili', subtitle: 'Simu / SMS / Ukumbi', icon: Icons.psychology),
          _HubItem(title: 'Cheti cha ndoa', subtitle: 'Tsh 150,000', icon: Icons.badge),
        ];
      case 'kijana':
        return const [
          _HubItem(title: 'Usajili', subtitle: 'Jisajili kwa majina, simu, nchi, mkoa, wilaya', icon: Icons.person_add),
          _HubItem(title: 'Unatafuta mchumba?', subtitle: 'Chagua sifa: umri, dini, tabia, n.k.', icon: Icons.favorite_border),
          _HubItem(title: 'Una mchumba?', subtitle: 'Taarifa za uhusiano na mahari', icon: Icons.favorite),
          _HubItem(title: 'Unatafuta ajira?', subtitle: 'Fursa za kazi', icon: Icons.work),
          _HubItem(title: 'Utatuzi wa mgogoro', subtitle: 'Ushauri wa mgogoro', icon: Icons.handshake),
          _HubItem(title: 'Ushauri nasaha', subtitle: 'Nasaha na mshauri', icon: Icons.phone_in_talk),
          _HubItem(title: 'Maandalizi ya arusi', subtitle: 'Mipango ya ndoa', icon: Icons.celebration),
          _HubItem(title: 'Sherehe ya kuhitimu', subtitle: 'Tamasha la kuhitimu masomo', icon: Icons.school),
        ];
      case 'mjane':
        return const [
          _HubItem(title: 'Usajili', subtitle: 'Jisajili', icon: Icons.person_add),
          _HubItem(title: 'Huduma', subtitle: 'Huduma za mjane / mgane — inafanywa hivi karibuni', icon: Icons.support),
        ];
      case 'single_parent':
        return const [
          _HubItem(title: 'Usajili', subtitle: 'Jisajili', icon: Icons.person_add),
          _HubItem(title: 'Huduma', subtitle: 'Huduma za mzazi peke yake — inafanywa hivi karibuni', icon: Icons.family_restroom),
        ];
      default:
        return const [_HubItem(title: 'Huduma', subtitle: 'Zinafanywa hivi karibuni', icon: Icons.info_outline)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as CategoryHubArguments?;
    final title = args?.title ?? 'Kundi';
    final id = args?.id ?? '';
    final items = _itemsFor(id);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
              onTap: () {
                // Placeholder: could show a snackbar or navigate later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.title} — inafanywa hivi karibuni')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HubItem {
  final String title;
  final String subtitle;
  final IconData icon;
  const _HubItem({required this.title, required this.subtitle, required this.icon});
}
