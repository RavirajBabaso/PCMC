// lib/screens/citizen/submit_grievance.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:main_ui/providers/master_data_provider.dart';
import 'package:main_ui/services/grievance_service.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/widgets/file_upload_widget.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:main_ui/widgets/form_fields.dart';
import 'package:main_ui/widgets/multi_step_form_stepper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SubmitGrievance extends ConsumerStatefulWidget {
  const SubmitGrievance({super.key});

  @override
  ConsumerState<SubmitGrievance> createState() => _SubmitGrievanceState();
}

class _SubmitGrievanceState extends ConsumerState<SubmitGrievance> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  // Form state
  int _currentStep = 0;
  int? _selectedSubjectId;
  int? _selectedAreaId;
  final List<PlatformFile> _attachments = [];
  Position? _currentPosition;
  bool _isSubmitting = false;

  // Form validation keys for each step
  final _detailsFormKey = GlobalKey<FormState>();
  final _categoryFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Add listeners to rebuild when text fields change to enable/disable Next button
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      setState(() => _isSubmitting = true);
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location services are disabled. Please enable them in Settings.',
          ),
        ),
      );
      await Geolocator.openLocationSettings();
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied. Please allow location access.',
            ),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission permanently denied. Please enable it from Settings.',
          ),
        ),
      );
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final fileBytes = kIsWeb ? await pickedFile.readAsBytes() : null;
      final filePath = kIsWeb ? null : pickedFile.path;
      final fileName = pickedFile.name;
      final fileSize = kIsWeb
          ? fileBytes?.length ?? 0
          : await File(pickedFile.path).length();

      if (!mounted) return;
      setState(() {
        _attachments.add(
          PlatformFile(
            name: fileName,
            size: fileSize,
            path: filePath,
            bytes: fileBytes,
          ),
        );
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _nextStep() {
    // Validate current step before proceeding
    if (!_validateCurrentStep()) {
      return;
    }
    setState(() => _currentStep++);
  }

  void _previousStep() {
    setState(() => _currentStep--);
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _detailsFormKey.currentState?.validate() ?? false;
      case 1:
        return _categoryFormKey.currentState?.validate() ?? false &&
            _selectedSubjectId != null &&
            _selectedAreaId != null;
      case 2:
        return _locationFormKey.currentState?.validate() ?? false;
      case 3:
        return true; // No validation needed for attachments
      default:
        return false;
    }
  }

  Future<void> _submitGrievance() async {
    if (!_validateCurrentStep()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseFillAllFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final grievanceService = GrievanceService();
      await grievanceService.createGrievance(
        title: _titleController.text,
        description: _descriptionController.text,
        subjectId: _selectedSubjectId!,
        areaId: _selectedAreaId!,
        address: _addressController.text,
        attachments: _attachments,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.grievanceSubmitted),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool get _canProceedToNextStep {
    switch (_currentStep) {
      case 0:
        // Check if title and description are filled without triggering validation
        return _titleController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty;
      case 1:
        return _selectedSubjectId != null && _selectedAreaId != null;
      case 2:
        // Check if address is filled without triggering validation
        return _addressController.text.isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildDetailsStep(AppLocalizations localizations) {
    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSectionHeader(
            title: localizations.grievanceDetails,
            subtitle: 'Provide a brief title and detailed description',
            icon: Icons.description,
          ),
          const SizedBox(height: 24),
          StandardTextInput(
            controller: _titleController,
            label: localizations.title,
            hint: 'e.g., Pothole on Main Street',
            validator: (value) =>
                value!.isEmpty ? localizations.titleRequired : null,
            isRequired: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          StandardTextInput(
            controller: _descriptionController,
            label: localizations.description,
            hint: 'Describe the issue in detail',
            validator: (value) => value!.isEmpty
                ? localizations.descriptionRequired
                : null,
            isRequired: true,
            maxLines: 5,
            minLines: 3,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep(
      AppLocalizations localizations, WidgetRef ref) {
    return Form(
      key: _categoryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSectionHeader(
            title: localizations.categorization,
            subtitle: 'Categorize your grievance for better routing',
            icon: Icons.category,
          ),
          const SizedBox(height: 24),
          ref.watch(subjectsProvider).when(
            data: (subjects) => StandardDropdown<int>(
              value: _selectedSubjectId,
              items: subjects
                  .map(
                    (subject) => DropdownMenuItem<int>(
                      value: subject.id,
                      child: Text(subject.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedSubjectId = value),
              label: localizations.filterBySubject,
              isRequired: true,
              validator: (value) => value == null
                  ? localizations.subjectRequired
                  : null,
            ),
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: LoadingIndicator()),
            ),
            error: (error, stack) => Text(
              '${localizations.error}: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          ref.watch(areasProvider).when(
            data: (areas) => StandardDropdown<int>(
              value: _selectedAreaId,
              items: areas
                  .map(
                    (area) => DropdownMenuItem<int>(
                      value: area.id,
                      child: Text(area.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedAreaId = value),
              label: localizations.filterByArea,
              isRequired: true,
              validator: (value) => value == null
                  ? localizations.areaRequired
                  : null,
            ),
            loading: () => const SizedBox(
              height: 56,
              child: Center(child: LoadingIndicator()),
            ),
            error: (error, stack) => Text(
              '${localizations.error}: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(AppLocalizations localizations) {
    return Form(
      key: _locationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSectionHeader(
            title: localizations.locationDetails,
            subtitle: 'Provide location information for the issue',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 24),
          StandardTextInput(
            controller: _addressController,
            label: localizations.address ?? 'Address',
            hint: 'Enter the street address',
            validator: (value) =>
                value!.isEmpty ? 'Address is required' : null,
            isRequired: true,
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: _isSubmitting
                      ? 'Getting Location...'
                      : 'Get Location',
                  onPressed: _isSubmitting
                      ? null
                      : _getCurrentLocation,
                  icon: Icons.location_on,
                  fullWidth: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentPosition != null)
            SuccessInfoBox(
              message:
                  'Location captured: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                  '${_currentPosition!.longitude.toStringAsFixed(4)}',
            ),
          if (_currentPosition == null)
            FormInfoBox(
              message: 'Tap "Get Location" to capture GPS coordinates',
              icon: Icons.info,
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsStep(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionHeader(
          title: 'Attachments & Media',
          subtitle: 'Add photos or documents to support your complaint',
          icon: Icons.attach_file,
        ),
        const SizedBox(height: 24),
        if (_attachments.isNotEmpty) ...[
          Text(
            'Attached Files (${_attachments.length})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dsTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_attachments.length, (index) {
              final file = _attachments[index];
              return Chip(
                label: Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: const Icon(Icons.attachment, size: 18),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeAttachment(index),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
        FileUploadWidget(
          onFilesSelected: (files) {
            setState(() => _attachments.addAll(files));
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Add Media',
                onPressed: _pickImage,
                icon: Icons.image,
                fullWidth: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FormInfoBox(
          message:
              'Attachments are optional but help speed up the resolution process',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final steps = [
      FormStep(
        title: 'Details',
        subtitle: 'Describe the issue',
        content: _buildDetailsStep(localizations),
        isValidated: _detailsFormKey.currentState?.validate() ?? false,
      ),
      FormStep(
        title: 'Category',
        subtitle: 'Categorize the issue',
        content: _buildCategoryStep(localizations, ref),
        isValidated: _selectedSubjectId != null && _selectedAreaId != null,
      ),
      FormStep(
        title: 'Location',
        subtitle: 'Specify the location',
        content: _buildLocationStep(localizations),
        isValidated: _locationFormKey.currentState?.validate() ?? false,
      ),
      FormStep(
        title: 'Attachments',
        subtitle: 'Add supporting media',
        content: _buildAttachmentsStep(localizations),
        isValidated: true,
      ),
    ];

    return MultiStepFormStepper(
      steps: steps,
      currentStep: _currentStep,
      onNextStep: _nextStep,
      onPreviousStep: _previousStep,
      onSubmit: _submitGrievance,
      isSubmitting: _isSubmitting,
      canProceedToNext: _canProceedToNextStep,
      onStepChanged: (newStep) {
        if (newStep < _currentStep || steps[newStep].isValidated) {
          setState(() => _currentStep = newStep);
        }
      },
      nextButtonLabel: 'Next',
      previousButtonLabel: 'Back',
      submitButtonLabel: localizations.submit,
    );
  }
}
