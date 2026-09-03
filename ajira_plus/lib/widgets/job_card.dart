import 'package:flutter/material.dart';
import '../main.dart';
import '../models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CompanyAvatar(company: job.company),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.company,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _TimeAgo(createdAt: job.createdAt),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(
                  icon: Icons.location_on_outlined,
                  label: job.location,
                  color: AppTheme.textSecondary,
                ),
                _Badge(
                  icon: Icons.work_outline_rounded,
                  label: job.type,
                  color: AppTheme.primary,
                  filled: true,
                ),
                if (job.salary != null && job.salary!.isNotEmpty)
                  _Badge(
                    icon: Icons.payments_outlined,
                    label: job.salary!,
                    color: AppTheme.accent,
                    filled: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyAvatar extends StatelessWidget {
  final String company;
  const _CompanyAvatar({required this.company});

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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          company.isNotEmpty ? company[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _color,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.1) : AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled ? color.withValues(alpha: 0.2) : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: filled ? color : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeAgo extends StatelessWidget {
  final DateTime createdAt;
  const _TimeAgo({required this.createdAt});

  String get _label {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
    );
  }
}
