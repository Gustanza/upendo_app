import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class JobService {
  final _col = FirebaseFirestore.instance.collection('jobs');

  Stream<List<JobModel>> getJobs({String? category}) {
    Query query = _col.orderBy('createdAt', descending: true);
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(JobModel.fromFirestore).toList(),
        );
  }

  Future<void> postJob(JobModel job) => _col.add(job.toFirestore());

  Future<void> deleteJob(String jobId) => _col.doc(jobId).delete();

  Stream<List<JobModel>> getMyJobs(String userId) => _col
      .where('postedBy', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(JobModel.fromFirestore).toList());
}
