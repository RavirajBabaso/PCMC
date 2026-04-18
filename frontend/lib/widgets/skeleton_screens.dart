import 'package:flutter/material.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/widgets/app/loading_skeleton.dart';

/// Skeleton screen for card content
class CardSkeleton extends StatelessWidget {
  final int count;
  final double spacing;
  final EdgeInsets padding;

  const CardSkeleton({
    super.key,
    this.count = 3,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: List.generate(count, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.6,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                LoadingSkeleton(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.7,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 12),
                LoadingSkeleton(
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.5,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Skeleton screen for form fields
class FormSkeleton extends StatelessWidget {
  final int fieldCount;
  final double spacing;
  final EdgeInsets padding;

  const FormSkeleton({
    super.key,
    this.fieldCount = 4,
    this.spacing = 20,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title/header skeleton
          LoadingSkeleton(
            height: 24,
            width: MediaQuery.of(context).size.width * 0.5,
            borderRadius: BorderRadius.circular(8),
            margin: EdgeInsets.only(bottom: spacing),
          ),
          // Form fields
          ...List.generate(fieldCount, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    height: 14,
                    width: 100,
                    borderRadius: BorderRadius.circular(6),
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  LoadingSkeleton(
                    height: 56,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            );
          }),
          // Button skeleton
          const SizedBox(height: 24),
          LoadingSkeleton(
            height: 56,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }
}

/// Skeleton screen for list items
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final double spacing;
  final EdgeInsets padding;

  const ListSkeleton({
    super.key,
    this.itemCount = 6,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: List.generate(itemCount, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: spacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.6,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 8),
                      LoadingSkeleton(
                        height: 12,
                        width: MediaQuery.of(context).size.width * 0.4,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Skeleton screen for table/data grid
class TableSkeleton extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final double spacing;
  final EdgeInsets padding;

  const TableSkeleton({
    super.key,
    this.rowCount = 5,
    this.columnCount = 3,
    this.spacing = 12,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: List.generate(rowCount, (rowIndex) {
          return Container(
            margin: EdgeInsets.only(bottom: spacing),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: dsAccent.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: List.generate(columnCount, (colIndex) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: colIndex < columnCount - 1 ? spacing : 0,
                    ),
                    child: LoadingSkeleton(
                      height: 14,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// Skeleton screen for image with text
class ImageCardSkeleton extends StatelessWidget {
  final int count;
  final double imageHeight;
  final double spacing;
  final EdgeInsets padding;

  const ImageCardSkeleton({
    super.key,
    this.count = 3,
    this.imageHeight = 180,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: List.generate(count, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image skeleton
                LoadingSkeleton(
                  height: imageHeight,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 12),
                // Title skeleton
                LoadingSkeleton(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.6,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                // Subtitle skeleton
                LoadingSkeleton(
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.4,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Skeleton screen for profile
class ProfileSkeleton extends StatelessWidget {
  final EdgeInsets padding;

  const ProfileSkeleton({
    super.key,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar skeleton
          LoadingSkeleton(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(40),
            margin: const EdgeInsets.only(bottom: 16),
          ),
          // Name skeleton
          LoadingSkeleton(
            height: 18,
            width: 150,
            borderRadius: BorderRadius.circular(8),
            margin: const EdgeInsets.only(bottom: 12),
          ),
          // Role skeleton
          LoadingSkeleton(
            height: 14,
            width: 120,
            borderRadius: BorderRadius.circular(6),
            margin: const EdgeInsets.only(bottom: 24),
          ),
          // Info sections
          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: dsAccent.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    height: 14,
                    width: 100,
                    borderRadius: BorderRadius.circular(6),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  LoadingSkeleton(
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Skeleton screen for page/detail view
class DetailPageSkeleton extends StatelessWidget {
  final EdgeInsets padding;

  const DetailPageSkeleton({
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          LoadingSkeleton(
            height: 240,
            borderRadius: BorderRadius.circular(12),
            margin: const EdgeInsets.only(bottom: 24),
          ),
          // Title skeleton
          LoadingSkeleton(
            height: 20,
            width: MediaQuery.of(context).size.width * 0.7,
            borderRadius: BorderRadius.circular(8),
            margin: const EdgeInsets.only(bottom: 16),
          ),
          // Metadata skeleton
          Row(
            children: [
              LoadingSkeleton(
                width: 80,
                height: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(width: 16),
              LoadingSkeleton(
                width: 60,
                height: 12,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Content skeleton
          ...List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: LoadingSkeleton(
                height: 14,
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ],
      ),
    );
  }
}
