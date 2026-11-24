import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianRegistrationStepException implements Exception {
  const TechnicianRegistrationStepException({
    required this.step,
    required this.cause,
  });

  final String step;
  final Object cause;

  String get causeMessage {
    final error = cause;
    if (error is PostgrestException) {
      final detailsMessage = error.details?.toString();
      final details = <String>[
        error.message,
        if (error.code != null) 'code: ${error.code}',
        if (detailsMessage != null && detailsMessage.isNotEmpty)
          'details: $detailsMessage',
        if (error.hint != null && error.hint!.isNotEmpty) 'hint: ${error.hint}',
      ];
      return details.join(' | ');
    }
    if (error is AuthException) {
      return [
        error.message,
        if (error.statusCode != null) 'status: ${error.statusCode}',
        if (error.code != null) 'code: ${error.code}',
      ].join(' | ');
    }
    if (error is StorageException) {
      return [
        error.message,
        if (error.statusCode != null) 'status: ${error.statusCode}',
      ].join(' | ');
    }
    if (error is StateError) return error.message;
    if (error is FormatException) return error.message;
    return error.toString();
  }

  @override
  String toString() => '$step: $causeMessage';
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
  });

  final Object id;
  final String name;
  final String? slug;
  final bool isActive;

  bool get isOther =>
      slug?.trim().toLowerCase() == 'other' || name.trim() == 'อื่น ๆ';

  factory ServiceCategory.fromRow(Map<String, dynamic> row) {
    final id = row['id'];
    final name = row['name'];
    final slug = row['slug'];
    final isActive = row['is_active'];

    if ((id is! String && id is! num) ||
        name is! String ||
        (slug != null && slug is! String) ||
        isActive is! bool) {
      throw const FormatException(
        'A service category has an invalid id, name, slug, or active status.',
      );
    }

    return ServiceCategory(
      id: id,
      name: name,
      slug: slug is String ? slug : null,
      isActive: isActive,
    );
  }
}

class TechnicianDocument {
  const TechnicianDocument({
    required this.documentType,
    required this.filePath,
    required this.fileExists,
    this.signedUrl,
  });

  final String documentType;
  final String filePath;
  final bool fileExists;
  final String? signedUrl;

  String get fileName => filePath.split('/').last;

  bool get isImage => const {
    'jpg',
    'jpeg',
    'png',
  }.contains(fileName.split('.').last.toLowerCase());
}

class TechnicianApplicationSnapshot {
  const TechnicianApplicationSnapshot({
    required this.profileExists,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.rejectedReason,
    required this.otherServiceDescription,
    required this.bio,
    required this.serviceArea,
    required this.serviceRadiusKm,
    required this.yearsExperience,
    required this.categoryIds,
    required this.categories,
    required this.categoryDefinitionsComplete,
    required this.otherCategorySelected,
    required this.hasIdentityDocument,
    required this.documents,
  });

  final bool profileExists;
  final String? role;
  final String? fullName;
  final String? phone;
  final String? status;
  final String? rejectedReason;
  final String? otherServiceDescription;
  final String? bio;
  final String? serviceArea;
  final int? serviceRadiusKm;
  final int? yearsExperience;
  final Set<Object> categoryIds;
  final List<ServiceCategory> categories;
  final bool categoryDefinitionsComplete;
  final bool otherCategorySelected;
  final bool hasIdentityDocument;
  final List<TechnicianDocument> documents;

  bool get isComplete =>
      (fullName?.trim().isNotEmpty ?? false) &&
      (phone?.trim().isNotEmpty ?? false) &&
      (bio?.trim().isNotEmpty ?? false) &&
      (serviceArea?.trim().isNotEmpty ?? false) &&
      (serviceRadiusKm != null && serviceRadiusKm! > 0) &&
      (yearsExperience != null && yearsExperience! >= 0) &&
      categoryIds.isNotEmpty &&
      categoryDefinitionsComplete &&
      (!otherCategorySelected ||
          (otherServiceDescription?.trim().isNotEmpty ?? false)) &&
      hasIdentityDocument;
}

abstract class TechnicianRegistrationRepository {
  Future<List<ServiceCategory>> loadActiveServiceCategories();

  Future<TechnicianApplicationSnapshot> loadApplicationSnapshot({
    required String profileId,
  });

  Future<void> updateProfileBasics({
    required String profileId,
    required String fullName,
    required String phone,
  });

  Future<void> updateTechnicianProfile({
    required String profileId,
    required String bio,
    required String serviceArea,
    required int serviceRadiusKm,
    required int yearsExperience,
    required String? otherServiceDescription,
  });

  Future<void> syncServiceCategories({
    required String technicianProfileId,
    required Set<Object> categoryIds,
    bool allowEmptySelectionToClear = false,
  });

  Future<TechnicianDocument> uploadDocument({
    required String profileId,
    required String documentType,
    required String fileName,
    required Uint8List bytes,
  });

  Future<void> deleteDocument({
    required String profileId,
    required TechnicianDocument document,
  });
}

class SupabaseTechnicianRegistrationRepository
    implements TechnicianRegistrationRepository {
  SupabaseTechnicianRegistrationRepository(this._client);

  final SupabaseClient _client;

  Future<T> _runStep<T>(String step, Future<T> Function() operation) async {
    try {
      return await operation();
    } on TechnicianRegistrationStepException {
      rethrow;
    } catch (error) {
      throw TechnicianRegistrationStepException(step: step, cause: error);
    }
  }

  @override
  Future<List<ServiceCategory>> loadActiveServiceCategories() async {
    final rows = await _client
        .from('service_categories')
        .select('id, name, slug, is_active')
        .eq('is_active', true)
        .order('name');

    return rows
        .map((row) => ServiceCategory.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<TechnicianApplicationSnapshot> loadApplicationSnapshot({
    required String profileId,
  }) async {
    final profile = await _client
        .from('profiles')
        .select('role, full_name, phone')
        .eq('id', profileId)
        .maybeSingle();
    final technicianProfile = await _client
        .from('technician_profiles')
        .select(
          'profile_id, status, rejected_reason, bio, service_area, '
          'service_radius_km, years_experience, other_service_description',
        )
        .eq('profile_id', profileId)
        .maybeSingle();

    final categoryRows = await _client
        .from('technician_service_categories')
        .select('category_id')
        .eq('technician_profile_id', profileId);
    final documentRows = await _client
        .from('technician_documents')
        .select('document_type, file_path')
        .eq('technician_profile_id', profileId);
    final documents = <TechnicianDocument>[];
    for (final row in documentRows) {
      final documentType = row['document_type'];
      final filePath = row['file_path'];
      if (documentType is! String ||
          !const {
            'identity',
            'certificate',
            'portfolio',
          }.contains(documentType) ||
          filePath is! String ||
          filePath.isEmpty) {
        throw const FormatException(
          'An existing technician document has an invalid type or file path.',
        );
      }

      final fileExists = await _documentFileExists(
        profileId: profileId,
        filePath: filePath,
      );
      final signedUrl = fileExists
          ? await _runStep(
              'สร้างลิงก์สำหรับแสดงเอกสารเดิม',
              () => _client.storage
                  .from('technician-documents')
                  .createSignedUrl(filePath, 3600),
            )
          : null;
      documents.add(
        TechnicianDocument(
          documentType: documentType,
          filePath: filePath,
          fileExists: fileExists,
          signedUrl: signedUrl,
        ),
      );
    }

    final categoryIds = <Object>{};
    for (final row in categoryRows) {
      final categoryId = row['category_id'];
      if (categoryId is! String && categoryId is! num) {
        throw const FormatException(
          'An existing technician service category has an invalid category_id.',
        );
      }
      categoryIds.add(categoryId);
    }

    final categoryRowsById = categoryIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('service_categories')
              .select('id, name, slug, is_active')
              .inFilter('id', categoryIds.toList());
    final categories = categoryRowsById
        .map((row) => ServiceCategory.fromRow(Map<String, dynamic>.from(row)))
        .toList();
    final categoryDefinitionsComplete = categories.length == categoryIds.length;
    final otherCategorySelected = categories.any(
      (category) => category.isOther,
    );
    return TechnicianApplicationSnapshot(
      profileExists: technicianProfile != null,
      role: profile?['role']?.toString(),
      fullName: profile?['full_name']?.toString(),
      phone: profile?['phone']?.toString(),
      status: technicianProfile?['status']?.toString(),
      rejectedReason: technicianProfile?['rejected_reason']?.toString(),
      otherServiceDescription: technicianProfile?['other_service_description']
          ?.toString(),
      bio: technicianProfile?['bio']?.toString(),
      serviceArea: technicianProfile?['service_area']?.toString(),
      serviceRadiusKm: _asServiceRadiusKm(
        technicianProfile?['service_radius_km'],
      ),
      yearsExperience: _asInt(technicianProfile?['years_experience']),
      categoryIds: categoryIds,
      categories: categories,
      categoryDefinitionsComplete: categoryDefinitionsComplete,
      otherCategorySelected: otherCategorySelected,
      hasIdentityDocument: documents.any(
        (document) =>
            document.documentType == 'identity' && document.fileExists,
      ),
      documents: documents,
    );
  }

  Future<bool> _documentFileExists({
    required String profileId,
    required String filePath,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    final pathSegments = filePath.split('/');
    if (currentUserId != profileId ||
        pathSegments.length < 2 ||
        pathSegments.first != profileId ||
        pathSegments.any((segment) => segment.isEmpty)) {
      return false;
    }

    try {
      return await _client.storage
          .from('technician-documents')
          .exists(filePath);
    } on StorageException catch (error) {
      if (error.statusCode == '403') {
        return false;
      }
      rethrow;
    }
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  int? _asServiceRadiusKm(Object? value) {
    final parsed = value is num
        ? value
        : value is String
        ? num.tryParse(value)
        : null;
    if (parsed == null || !parsed.isFinite || parsed % 1 != 0) {
      return null;
    }
    return parsed.toInt();
  }

  @override
  Future<void> updateProfileBasics({
    required String profileId,
    required String fullName,
    required String phone,
  }) async {
    await _runStep('บันทึกข้อมูลโปรไฟล์ผู้ใช้', () async {
      final updatedProfile = await _client
          .from('profiles')
          .update({'full_name': fullName, 'phone': phone})
          .eq('id', profileId)
          .select('id, full_name, phone')
          .maybeSingle();

      if (updatedProfile == null ||
          updatedProfile['id'] != profileId ||
          updatedProfile['full_name'] != fullName ||
          updatedProfile['phone'] != phone) {
        throw StateError(
          'Supabase did not return the expected updated profile values.',
        );
      }
    });
  }

  @override
  Future<void> updateTechnicianProfile({
    required String profileId,
    required String bio,
    required String serviceArea,
    required int serviceRadiusKm,
    required int yearsExperience,
    required String? otherServiceDescription,
  }) async {
    final existingProfile = await _runStep(
      'ตรวจสอบโปรไฟล์ช่าง',
      () => _client
          .from('technician_profiles')
          .select('profile_id')
          .eq('profile_id', profileId)
          .maybeSingle(),
    );

    if (existingProfile == null || existingProfile['profile_id'] != profileId) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบโปรไฟล์ช่าง',
        cause: StateError(
          'ไม่พบแถว technician_profiles ของบัญชีที่เข้าสู่ระบบ',
        ),
      );
    }

    await _runStep('บันทึกข้อมูล technician_profiles', () async {
      final updatedProfile = await _client
          .from('technician_profiles')
          .update({
            'bio': bio,
            'service_area': serviceArea,
            'service_radius_km': serviceRadiusKm,
            'years_experience': yearsExperience,
            'other_service_description': otherServiceDescription,
          })
          .eq('profile_id', profileId)
          .select(
            'profile_id, bio, service_area, service_radius_km, '
            'years_experience, other_service_description',
          )
          .maybeSingle();

      if (updatedProfile == null ||
          updatedProfile['profile_id'] != profileId ||
          updatedProfile['bio'] != bio ||
          updatedProfile['service_area'] != serviceArea ||
          _asServiceRadiusKm(updatedProfile['service_radius_km']) !=
              serviceRadiusKm ||
          _asInt(updatedProfile['years_experience']) != yearsExperience ||
          updatedProfile['other_service_description'] !=
              otherServiceDescription) {
        throw StateError(
          'Supabase did not return the expected updated technician profile values.',
        );
      }
    });
  }

  @override
  Future<TechnicianDocument> uploadDocument({
    required String profileId,
    required String documentType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (_client.auth.currentUser?.id != profileId) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบบัญชีก่อนอัปโหลดเอกสาร',
        cause: StateError('Auth User ไม่ตรงกับบัญชีเจ้าของเอกสาร'),
      );
    }
    if (!const {
      'identity',
      'certificate',
      'portfolio',
    }.contains(documentType)) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบชนิดเอกสาร',
        cause: ArgumentError.value(documentType, 'documentType'),
      );
    }
    if (bytes.isEmpty || bytes.lengthInBytes > 10 * 1024 * 1024) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบขนาดเอกสาร',
        cause: ArgumentError('ไฟล์ต้องมีขนาดมากกว่า 0 และไม่เกิน 10 MB'),
      );
    }

    final normalizedFileName = fileName.split(RegExp(r'[/\\]')).last;
    final safeFileName = normalizedFileName.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    final extension = safeFileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => null,
    };
    if (contentType == null ||
        (documentType == 'portfolio' && contentType == 'application/pdf')) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบชนิดไฟล์เอกสาร',
        cause: FormatException(
          'ไฟล์ต้องเป็น PDF, JPG หรือ PNG และ Portfolio ต้องเป็นรูปภาพ',
        ),
      );
    }

    final filePath =
        '$profileId/$documentType/'
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_$safeFileName';
    const bucketId = 'technician-documents';
    final storage = _client.storage.from(bucketId);
    final returnedKey = await _runStep(
      'อัปโหลดไฟล์ $documentType ไป Storage',
      () => storage.uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      ),
    );
    var metadataInsertAttempted = false;
    try {
      final expectedKey = '$bucketId/$filePath';
      final returnedPath = _relativeUploadedPath(bucketId, returnedKey);
      _logDocumentUploadDebug(
        'expectedKey=$expectedKey returnedKey=$returnedKey '
        'normalizedPath=$returnedPath',
      );
      if (returnedPath == null ||
          returnedPath != filePath ||
          !_isOwnedDocumentPath(profileId, returnedPath)) {
        throw TechnicianRegistrationStepException(
          step: 'ตรวจสอบผลการอัปโหลดเอกสาร',
          cause: StateError(
            'Storage ส่งคืน bucket หรือ path ที่ไม่ตรงกับไฟล์ที่ร้องขอ',
          ),
        );
      }

      final fileExists = await _runStep(
        'ตรวจสอบไฟล์ที่อัปโหลดใน Storage',
        () => storage.exists(filePath),
      );
      _logDocumentUploadDebug(
        'verified=$fileExists bucket=$bucketId path=$filePath',
      );
      if (!fileExists) {
        throw TechnicianRegistrationStepException(
          step: 'ตรวจสอบไฟล์ที่อัปโหลดใน Storage',
          cause: StateError('ไม่พบไฟล์ใน Storage หลังอัปโหลดสำเร็จ'),
        );
      }

      final signedUrl = await _runStep(
        'สร้างลิงก์สำหรับแสดงเอกสาร',
        () => storage.createSignedUrl(filePath, 3600),
      );
      metadataInsertAttempted = true;
      final insertedRow = await _runStep(
        'บันทึก metadata เอกสาร',
        () => _client
            .from('technician_documents')
            .insert({
              'technician_profile_id': profileId,
              'document_type': documentType,
              'file_path': filePath,
            })
            .select('technician_profile_id, document_type, file_path')
            .single(),
      );

      if (insertedRow['technician_profile_id'] != profileId ||
          insertedRow['document_type'] != documentType ||
          insertedRow['file_path'] != filePath) {
        throw TechnicianRegistrationStepException(
          step: 'ตรวจสอบผลการบันทึก metadata เอกสาร',
          cause: StateError('Supabase ส่งคืน metadata ที่ไม่ตรงกับคำขอ'),
        );
      }

      return TechnicianDocument(
        documentType: documentType,
        filePath: filePath,
        fileExists: true,
        signedUrl: signedUrl,
      );
    } catch (error) {
      final cleanupErrors = <String>[];
      final canCleanUp =
          _client.auth.currentUser?.id == profileId &&
          _isOwnedDocumentPath(profileId, filePath);
      if (metadataInsertAttempted && canCleanUp) {
        try {
          await _client
              .from('technician_documents')
              .delete()
              .eq('technician_profile_id', profileId)
              .eq('document_type', documentType)
              .eq('file_path', filePath);
        } catch (cleanupError) {
          cleanupErrors.add(
            'ลบ metadata ที่ไม่สมบูรณ์ไม่สำเร็จ: $cleanupError',
          );
        }
      } else if (metadataInsertAttempted) {
        cleanupErrors.add(
          'ไม่ได้ลบ metadata ค้าง เนื่องจาก Session ไม่ใช่เจ้าของไฟล์',
        );
      }
      if (canCleanUp) {
        try {
          final fileExists = await storage.exists(filePath);
          if (fileExists) {
            await storage.remove([filePath]);
          }
        } catch (cleanupError) {
          cleanupErrors.add('ลบไฟล์ที่อัปโหลดค้างไม่สำเร็จ: $cleanupError');
        }
      } else {
        cleanupErrors.add(
          'ไม่ได้ลบไฟล์ค้าง เนื่องจาก Session ไม่ใช่เจ้าของไฟล์',
        );
      }

      if (cleanupErrors.isNotEmpty) {
        throw TechnicianRegistrationStepException(
          step: 'จัดการไฟล์หลังขั้นตอนเอกสารล้มเหลว',
          cause: StateError('$error; ${cleanupErrors.join('; ')}'),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteDocument({
    required String profileId,
    required TechnicianDocument document,
  }) async {
    if (_client.auth.currentUser?.id != profileId ||
        !const {
          'identity',
          'certificate',
          'portfolio',
        }.contains(document.documentType) ||
        !_isOwnedDocumentPath(profileId, document.filePath)) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบสิทธิ์ก่อนลบเอกสาร',
        cause: StateError('Session หรือ path ไม่ตรงกับเจ้าของเอกสาร'),
      );
    }

    final existingRows = await _runStep(
      'ตรวจสอบ metadata ก่อนลบเอกสาร',
      () => _client
          .from('technician_documents')
          .select('file_path')
          .eq('technician_profile_id', profileId)
          .eq('document_type', document.documentType)
          .eq('file_path', document.filePath),
    );
    if (existingRows.isEmpty) return;

    final storage = _client.storage.from('technician-documents');
    final fileExists = await _runStep(
      'ตรวจสอบไฟล์ก่อนลบจาก Storage',
      () => storage.exists(document.filePath),
    );
    if (fileExists) {
      await _runStep('ลบไฟล์เอกสารจาก Storage', () async {
        await storage.remove([document.filePath]);
      });
    }

    await _runStep('ลบ metadata เอกสาร', () async {
      final deletedRows = await _client
          .from('technician_documents')
          .delete()
          .eq('technician_profile_id', profileId)
          .eq('document_type', document.documentType)
          .eq('file_path', document.filePath)
          .select('file_path');

      if (deletedRows.any((row) => row['file_path'] == document.filePath)) {
        return;
      }

      final remainingRows = await _client
          .from('technician_documents')
          .select('file_path')
          .eq('technician_profile_id', profileId)
          .eq('document_type', document.documentType)
          .eq('file_path', document.filePath);
      if (remainingRows.isNotEmpty) {
        throw StateError('Supabase did not return the deleted document row.');
      }
    });
  }

  String? _relativeUploadedPath(String bucketId, String returnedKey) {
    final bucketPrefix = '$bucketId/';
    if (!returnedKey.startsWith(bucketPrefix)) return null;
    return returnedKey.substring(bucketPrefix.length);
  }

  void _logDocumentUploadDebug(String message) {
    assert(() {
      developer.log(message, name: 'TechnicianDocumentUpload');
      return true;
    }());
  }

  bool _isOwnedDocumentPath(String profileId, String filePath) {
    final segments = filePath.split('/');
    return segments.length >= 2 &&
        segments.first == profileId &&
        segments.any((segment) => segment.isEmpty) == false;
  }

  @override
  Future<void> syncServiceCategories({
    required String technicianProfileId,
    required Set<Object> categoryIds,
    bool allowEmptySelectionToClear = false,
  }) async {
    if (categoryIds.isEmpty && !allowEmptySelectionToClear) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบรายการหมวดบริการ',
        cause: ArgumentError(
          'An empty category selection cannot clear saved categories unless '
          'allowEmptySelectionToClear is explicitly true.',
        ),
      );
    }

    final existingRows = await _runStep(
      'อ่านหมวดบริการเดิม',
      () => _client
          .from('technician_service_categories')
          .select('category_id')
          .eq('technician_profile_id', technicianProfileId),
    );

    final existingCategoryIds = <Object>{};
    for (final row in existingRows) {
      final categoryId = row['category_id'];
      if (categoryId is! String && categoryId is! num) {
        throw const TechnicianRegistrationStepException(
          step: 'อ่านหมวดบริการเดิม',
          cause: FormatException(
            'An existing technician service category has an invalid category_id.',
          ),
        );
      }
      existingCategoryIds.add(categoryId);
    }

    final activeCategoryRows = await _runStep(
      'ตรวจสอบหมวดบริการที่เปิดใช้งาน',
      () =>
          _client.from('service_categories').select('id').eq('is_active', true),
    );
    final activeCategoryIds = <Object>{};
    for (final row in activeCategoryRows) {
      final categoryId = row['id'];
      if (categoryId is! String && categoryId is! num) {
        throw const TechnicianRegistrationStepException(
          step: 'ตรวจสอบหมวดบริการที่เปิดใช้งาน',
          cause: FormatException(
            'Supabase returned an invalid active service category id.',
          ),
        );
      }
      activeCategoryIds.add(categoryId);
    }

    final unavailableCategoryIds = categoryIds
        .difference(activeCategoryIds)
        .difference(existingCategoryIds);
    if (unavailableCategoryIds.isNotEmpty) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบหมวดบริการที่เลือก',
        cause: StateError(
          'มีหมวดที่เลือกซึ่งไม่มีอยู่ หรือไม่ได้เปิดใช้งานสำหรับบัญชีนี้',
        ),
      );
    }

    final removedCategoryIds = allowEmptySelectionToClear && categoryIds.isEmpty
        ? existingCategoryIds
        : existingCategoryIds
              .intersection(activeCategoryIds)
              .difference(categoryIds);
    if (removedCategoryIds.isNotEmpty) {
      await _runStep('ลบหมวดบริการที่ยกเลิกเลือก', () async {
        final deletedRows = await _client
            .from('technician_service_categories')
            .delete()
            .eq('technician_profile_id', technicianProfileId)
            .inFilter('category_id', removedCategoryIds.toList())
            .select('category_id');

        for (final row in deletedRows) {
          final categoryId = row['category_id'];
          if ((categoryId is! String && categoryId is! num) ||
              !removedCategoryIds.contains(categoryId)) {
            throw const FormatException(
              'Supabase returned an unexpected deleted category.',
            );
          }
        }
      });
    }

    final newCategoryIds = categoryIds
        .intersection(activeCategoryIds)
        .difference(existingCategoryIds);
    if (newCategoryIds.isNotEmpty) {
      await _runStep('บันทึกหมวดบริการที่เลือก', () async {
        final upsertedRows = await _client
            .from('technician_service_categories')
            .upsert(
              newCategoryIds
                  .map(
                    (categoryId) => {
                      'technician_profile_id': technicianProfileId,
                      'category_id': categoryId,
                    },
                  )
                  .toList(),
              onConflict: 'technician_profile_id,category_id',
              ignoreDuplicates: true,
            )
            .select('technician_profile_id, category_id');

        for (final row in upsertedRows) {
          final categoryId = row['category_id'];
          if (row['technician_profile_id'] != technicianProfileId ||
              (categoryId is! String && categoryId is! num) ||
              !newCategoryIds.contains(categoryId)) {
            throw const FormatException(
              'Supabase returned an unexpected upserted category.',
            );
          }
        }
      });
    }

    final finalRows = await _runStep(
      'ตรวจสอบผลการบันทึกหมวดบริการ',
      () => _client
          .from('technician_service_categories')
          .select('category_id')
          .eq('technician_profile_id', technicianProfileId),
    );
    final finalCategoryIds = <Object>{};
    for (final row in finalRows) {
      final categoryId = row['category_id'];
      if (categoryId is! String && categoryId is! num) {
        throw const TechnicianRegistrationStepException(
          step: 'ตรวจสอบผลการบันทึกหมวดบริการ',
          cause: FormatException('Supabase returned an invalid category_id.'),
        );
      }
      finalCategoryIds.add(categoryId);
    }

    final expectedCategoryIds =
        allowEmptySelectionToClear && categoryIds.isEmpty
        ? <Object>{}
        : existingCategoryIds
              .difference(removedCategoryIds)
              .union(newCategoryIds);
    if (finalCategoryIds.length != expectedCategoryIds.length ||
        !finalCategoryIds.containsAll(expectedCategoryIds)) {
      throw TechnicianRegistrationStepException(
        step: 'ตรวจสอบผลการบันทึกหมวดบริการ',
        cause: StateError(
          'หมวดบริการที่ Supabase ส่งกลับไม่ตรงกับรายการที่ควรบันทึก',
        ),
      );
    }
  }
}
