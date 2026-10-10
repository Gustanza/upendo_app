import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../models/job_model.dart';
import '../../services/job_service.dart';

class JobDetailScreen extends StatelessWidget {
  final JobModel job;

  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == job.postedBy;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isOwner),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildBadges(),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: job.hasAnyContact ? _buildContactBar(context) : null,
    );
  }

  Widget _buildAppBar(BuildContext context, bool isOwner) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            tooltip: 'Delete job',
            onPressed: () => _confirmDelete(context),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompanyAvatar(company: job.company, size: 56),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.company,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Posted by ${job.postedByName}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _InfoChip(icon: Icons.location_on_outlined, label: job.location),
        _InfoChip(icon: Icons.work_outline_rounded, label: job.type, highlight: true),
        _InfoChip(icon: Icons.category_outlined, label: job.category),
        if (job.salary != null && job.salary!.isNotEmpty)
          _InfoChip(icon: Icons.payments_outlined, label: job.salary!, highlight: true, accentColor: AppTheme.accent),
      ],
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppTheme.border, height: 1);
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Description',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          job.description,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildContactBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact to apply',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (job.hasEmail) ...[
                Expanded(child: _ContactButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: AppTheme.primary,
                  onTap: () => _launch('mailto:${job.contactEmail}', context),
                )),
                const SizedBox(width: 10),
              ],
              if (job.hasWhatsApp) ...[
                Expanded(child: _ContactButton(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _launch(
                    'https://wa.me/${_cleanPhone(job.contactWhatsApp!)}',
                    context,
                  ),
                )),
                const SizedBox(width: 10),
              ],
              if (job.hasPhone)
                Expanded(child: Row(
                  children: [
                    Expanded(child: _ContactButton(
                      icon: Icons.call_outlined,
                      label: 'Call',
                      color: AppTheme.accent,
                      onTap: () => _launch('tel:${job.contactPhone}', context),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _ContactButton(
                      icon: Icons.sms_outlined,
                      label: 'SMS',
                      color: const Color(0xFFF59E0B),
                      onTap: () => _launch('sms:${job.contactPhone}', context),
                    )),
                  ],
                )),
            ],
          ),
        ],
      ),
    );
  }

  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _launch(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this contact method.')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this job?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await JobService().deleteJob(job.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _CompanyAvatar extends StatelessWidget {
  final String company;
  final double size;
  const _CompanyAvatar({required this.company, required this.size});

  Color get _color {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF0D9488),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      AppTheme.primary,
    ];
    return colors[company.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          company.isNotEmpty ? company[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
            color: _color,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final Color? accentColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? (highlight ? AppTheme.primary : AppTheme.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? color.withValues(alpha: 0.2) : AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
