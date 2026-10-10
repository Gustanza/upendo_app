import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String company;
  final String description;
  final String location;
  final String category;
  final String type;
  final String? salary;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactWhatsApp;
  final String postedBy;
  final String postedByName;
  final DateTime createdAt;

  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.category,
    required this.type,
    this.salary,
    this.contactEmail,
    this.contactPhone,
    this.contactWhatsApp,
    required this.postedBy,
    required this.postedByName,
    required this.createdAt,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      salary: data['salary'],
      contactEmail: data['contactEmail'],
      contactPhone: data['contactPhone'],
      contactWhatsApp: data['contactWhatsApp'],
      postedBy: data['postedBy'] ?? '',
      postedByName: data['postedByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'company': company,
        'description': description,
        'location': location,
        'category': category,
        'type': type,
        'salary': salary,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'contactWhatsApp': contactWhatsApp,
        'postedBy': postedBy,
        'postedByName': postedByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get hasEmail => contactEmail != null && contactEmail!.isNotEmpty;
  bool get hasPhone => contactPhone != null && contactPhone!.isNotEmpty;
  bool get hasWhatsApp => contactWhatsApp != null && contactWhatsApp!.isNotEmpty;
  bool get hasAnyContact => hasEmail || hasPhone || hasWhatsApp;
}

const List<String> jobCategories = [
  'All',
  'Technology',
  'Finance',
  'Healthcare',
  'Education',
  'Marketing',
  'Engineering',
  'Sales',
  'Design',
  'Administration',
  'Other',
];

const List<String> jobTypes = [
  'Full-time',
  'Part-time',
  'Contract',
  'Internship',
  'Remote',
  'Freelance',
];
