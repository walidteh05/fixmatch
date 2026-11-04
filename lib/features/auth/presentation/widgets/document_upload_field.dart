import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class DocumentUploadField extends StatelessWidget {
  const DocumentUploadField({
    super.key,
    required this.label,
    required this.files,
    required this.onPickFiles,
    required this.onRemoveFile,
    required this.onReplaceFile,
    this.required = false,
    this.allowMultiple = false,
    this.allowPdf = true,
    this.isLoading = false,
    this.helperText,
  });

  final String label;
  final bool required;
  final List<PlatformFile> files;
  final bool allowMultiple;
  final bool allowPdf;
  final bool isLoading;
  final String? helperText;
  final Future<void> Function() onPickFiles;
  final void Function(int index) onRemoveFile;
  final void Function() onReplaceFile;

  String get _fileTypeText => allowMultiple ? 'หลายรูป' : '1 ไฟล์';

  Widget _buildFilePreview(PlatformFile file) {
    final isImage = ['jpg', 'jpeg', 'png'].contains((file.extension ?? '').toLowerCase());

    if (isImage && file.path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(file.path!),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.picture_as_pdf_rounded,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSingleFileTile(BuildContext context, PlatformFile file, int index) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildFilePreview(file),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${((file.lengthSync() ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isLoading ? null : onReplaceFile,
            child: const Text('เปลี่ยน'),
          ),
          IconButton(
            onPressed: isLoading ? null : () => onRemoveFile(index),
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiImageGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GridView.builder(
        itemCount: files.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final file = files[index];
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.primaryLight,
                ),
                clipBehavior: Clip.antiAlias,
                child: file.path != null
                    ? Image.file(
                        File(file.path!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: isLoading ? null : () => onRemoveFile(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.label),
            if (required)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text(
                  '*',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: AppTextStyles.bodySmall,
          ),
        ],
        const SizedBox(height: 10),
        GestureDetector(
          onTap: isLoading ? null : onPickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('กำลังเลือกไฟล์...'),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              allowPdf ? 'เลือกไฟล์ PDF / JPG / PNG' : 'เลือกรูปภาพ JPG / PNG',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_fileTypeText • ไม่เกิน 10 MB ต่อไฟล์',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (files.isNotEmpty) ...[
          if (allowMultiple)
            _buildMultiImageGrid(context)
          else
            _buildSingleFileTile(context, files.first, 0),
        ],
      ],
    );
  }
}
