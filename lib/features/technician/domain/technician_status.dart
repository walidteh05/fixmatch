enum TechnicianStatus {
  pending,
  approved,
  rejected,
  suspended,
}

extension TechnicianStatusX on TechnicianStatus {
  String get label {
    switch (this) {
      case TechnicianStatus.pending:
        return 'PENDING REVIEW';
      case TechnicianStatus.approved:
        return 'APPROVED';
      case TechnicianStatus.rejected:
        return 'REJECTED';
      case TechnicianStatus.suspended:
        return 'SUSPENDED';
    }
  }
}
