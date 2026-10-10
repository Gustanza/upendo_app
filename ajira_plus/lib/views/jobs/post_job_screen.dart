import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/job_model.dart';
import '../../services/job_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobService = JobService();

  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String _selectedCategory = jobCategories[1];
  String _selectedType = jobTypes[0];
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _salaryCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  bool get _hasContact =>
      _emailCtrl.text.trim().isNotEmpty ||
      _phoneCtrl.text.trim().isNotEmpty ||
      _whatsappCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one contact method (email, phone, or WhatsApp).'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final job = JobModel(
        id: '',
        title: _titleCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        category: _selectedCategory,
        type: _selectedType,
        salary: _salaryCtrl.text.trim().isEmpty ? null : _salaryCtrl.text.trim(),
        contactEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        contactWhatsApp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        postedBy: user.uid,
        postedByName: user.displayName ?? 'Anonymous',
        createdAt: DateTime.now(),
      );
      await _jobService.postJob(job);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionLabel('Job Details'),
            const SizedBox(height: 12),
            _buildField(_titleCtrl, 'Job title', Icons.title_rounded, required: true),
            const SizedBox(height: 14),
            _buildField(_companyCtrl, 'Company name', Icons.business_rounded, required: true),
            const SizedBox(height: 14),
            _buildField(_locationCtrl, 'Location', Icons.location_on_outlined, required: true),
            const SizedBox(height: 14),
            _buildCategoryDropdown(),
            const SizedBox(height: 14),
            _buildTypeSelector(),
            const SizedBox(height: 14),
            _buildField(_salaryCtrl, 'Salary / Range (optional)', Icons.payments_outlined),
            const SizedBox(height: 24),
            _sectionLabel('Description'),
            const SizedBox(height: 12),
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _sectionLabel('Contact Methods'),
            const SizedBox(height: 4),
            const Text(
              'Add at least one so applicants can reach you.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            _buildField(_emailCtrl, 'Email address', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _buildField(_phoneCtrl, 'Phone number', Icons.call_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _buildField(_whatsappCtrl, 'WhatsApp number', Icons.chat_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Post Job'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descCtrl,
      maxLines: 6,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        labelText: 'Describe the role, requirements, responsibilities...',
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: Icon(Icons.description_outlined, color: AppTheme.textSecondary),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Add a job description';
        if (v.trim().length < 20) return 'Description is too short';
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textSecondary),
      ),
      items: jobCategories
          .where((c) => c != 'All')
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v!),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Type',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: jobTypes.map((type) {
            final selected = type == _selectedType;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
