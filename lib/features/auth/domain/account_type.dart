enum AccountType {
  customer,
  technician,
}

extension AccountTypeX on AccountType {
  String get label {
    switch (this) {
      case AccountType.customer:
        return 'Customer';
      case AccountType.technician:
        return 'Technician';
    }
  }

  String get description {
    switch (this) {
      case AccountType.customer:
        return 'ค้นหาและจองช่างสำหรับบริการภายในบ้าน';
      case AccountType.technician:
        return 'สมัครเป็นช่างและรับงานจากลูกค้า';
    }
  }
}
