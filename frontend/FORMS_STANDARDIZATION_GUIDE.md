# Forms Standardization Guide

## Overview
This guide explains the standardized form components and patterns used throughout the PCMC application for consistent UI/UX across all forms.

## Components

### 1. StandardTextInput
A reusable text input field with consistent styling across the app.

```dart
StandardTextInput(
  controller: _titleController,
  label: 'Title',
  hint: 'Enter a title',
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
  isRequired: true,
  maxLines: 1,
  keyboardType: TextInputType.text,
  textInputAction: TextInputAction.next,
  onChanged: (value) => print(value),
  helperText: 'Help text here',
)
```

**Parameters:**
- `controller`: TextEditingController for managing the input
- `label`: Field label text
- `hint`: Placeholder text (optional)
- `validator`: Validation function (optional)
- `isRequired`: Shows asterisk if true (default: false)
- `maxLines`: Maximum lines (default: 1)
- `minLines`: Minimum lines (default: 1)
- `keyboardType`: Type of keyboard (default: text)
- `textInputAction`: Action button type (default: next)
- `onChanged`: Callback when value changes (optional)
- `helperText`: Helper text below the field (optional)

### 2. StandardDropdown
A reusable dropdown field with consistent styling.

```dart
StandardDropdown<int>(
  value: _selectedId,
  items: [
    DropdownMenuItem(value: 1, child: Text('Option 1')),
    DropdownMenuItem(value: 2, child: Text('Option 2')),
  ],
  onChanged: (value) => setState(() => _selectedId = value),
  label: 'Select an option',
  isRequired: true,
  validator: (value) => value == null ? 'Required' : null,
  hint: 'Choose one',
)
```

**Parameters:**
- `value`: Currently selected value
- `items`: List of DropdownMenuItem widgets
- `onChanged`: Callback when selection changes
- `label`: Field label text
- `isRequired`: Shows asterisk if true (default: false)
- `validator`: Validation function (optional)
- `hint`: Placeholder text (optional)

### 3. FormSectionHeader
A header for grouping related form fields.

```dart
FormSectionHeader(
  title: 'Personal Information',
  subtitle: 'Enter your basic details',
  icon: Icons.person,
)
```

**Parameters:**
- `title`: Section title (required)
- `subtitle`: Descriptive text (optional)
- `icon`: Icon to display (optional)

### 4. FormProgressIndicator
Shows progress through a multi-step form.

```dart
FormProgressIndicator(
  currentStep: 0,
  totalSteps: 4,
  stepTitles: ['Details', 'Category', 'Location', 'Attachments'],
)
```

**Parameters:**
- `currentStep`: Index of current step (0-based)
- `totalSteps`: Total number of steps
- `stepTitles`: List of step titles

### 5. FormInfoBox
A styled information/warning box.

```dart
FormInfoBox(
  message: 'This is an informational message',
  icon: Icons.info,
  backgroundColor: Color(0xFF1C3460),
  textColor: Color(0xFF8BA3BE),
)
```

**Parameters:**
- `message`: Message text (required)
- `icon`: Icon to display (default: Icons.info)
- `backgroundColor`: Background color (optional)
- `textColor`: Text color (optional)

### 6. SuccessInfoBox
A styled success message box.

```dart
SuccessInfoBox(
  message: 'Location captured successfully',
  icon: Icons.check_circle,
)
```

**Parameters:**
- `message`: Success message (required)
- `icon`: Icon to display (default: Icons.check_circle)

## MultiStepFormStepper

For multi-step forms with validation and navigation.

```dart
MultiStepFormStepper(
  steps: [
    FormStep(
      title: 'Details',
      subtitle: 'Enter basic info',
      content: _buildDetailsStep(),
      isValidated: false,
    ),
    FormStep(
      title: 'Confirmation',
      subtitle: 'Review your info',
      content: _buildConfirmationStep(),
      isValidated: false,
    ),
  ],
  currentStep: _currentStep,
  onNextStep: () => setState(() => _currentStep++),
  onPreviousStep: () => setState(() => _currentStep--),
  onSubmit: _submitForm,
  isSubmitting: _isSubmitting,
  canProceedToNext: true,
  onStepChanged: (newStep) => setState(() => _currentStep = newStep),
  nextButtonLabel: 'Next',
  previousButtonLabel: 'Back',
  submitButtonLabel: 'Submit',
)
```

**Features:**
- Visual progress indicators
- Step validation
- Back/next navigation
- Support for locked steps
- Customizable labels

## Form Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Background | `dsBackground` | #0F2438 |
| Surface | `dsSurface` | #132A46 |
| Text Primary | `dsTextPrimary` | #E8F1F9 |
| Text Secondary | `dsTextSecondary` | #8BA3BE |
| Accent | `dsAccent` | #00E5FF |
| Border | Border color | #1C3460 |
| Focus | Focus color | #00E5FF |
| Error | Error color | #FF0000 |

## Usage Examples

### Simple Registration Form

```dart
class RegistrationForm extends StatefulWidget {
  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Container(
          decoration: dsPanelDecoration(color: dsSurface),
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormSectionHeader(
                  title: 'Personal Information',
                  icon: Icons.person,
                ),
                SizedBox(height: 24),
                StandardTextInput(
                  controller: _nameController,
                  label: 'Full Name',
                  isRequired: true,
                  validator: (value) => value?.isEmpty ?? true 
                    ? 'Name is required' 
                    : null,
                ),
                SizedBox(height: 16),
                StandardTextInput(
                  controller: _emailController,
                  label: 'Email',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                SizedBox(height: 24),
                AppButton(
                  text: 'Submit',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Submit logic
                    }
                  },
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
```

### Multi-Step Grievance Form

See `submit_grievance.dart` for a complete example with:
- Details step (title, description)
- Category step (subject, area)
- Location step (address, GPS)
- Attachments step (files, images)

## Best Practices

1. **Always use StandardTextInput and StandardDropdown** instead of raw TextFormField
2. **Group related fields** using FormSectionHeader
3. **Provide clear labels and hints** for better UX
4. **Set isRequired=true** for mandatory fields
5. **Use appropriate keyboard types** (email, phone, number, etc.)
6. **Add helper text** for complex fields
7. **Validate early and show clear error messages**
8. **Use FormProgressIndicator** for multi-step forms
9. **Dispose controllers properly** in dispose() method
10. **Keep forms uncluttered** with proper spacing (SizedBox(height: 16))

## Validation Patterns

```dart
// Required field
validator: (value) => value?.isEmpty ?? true ? 'This field is required' : null,

// Email validation
validator: (value) {
  if (value?.isEmpty ?? true) return 'Email is required';
  if (!value!.contains('@')) return 'Invalid email format';
  return null;
},

// Phone validation
validator: (value) {
  if (value?.isEmpty ?? true) return 'Phone is required';
  if (value!.length < 10) return 'Phone must be at least 10 digits';
  return null;
},

// Dropdown dependency
validator: (value) {
  if (value == null && _selectedSubjectId != null) {
    return 'This field is required';
  }
  return null;
},
```

## Migration Checklist

When updating existing forms:

- [ ] Replace `TextFormField` with `StandardTextInput`
- [ ] Replace `DropdownButtonFormField` with `StandardDropdown`
- [ ] Add `FormSectionHeader` for field grouping
- [ ] Update decorations to use `dsFormFieldDecoration` if not using Standard components
- [ ] Add proper spacing between sections
- [ ] Update validation messages for consistency
- [ ] Test on mobile and tablet views
- [ ] Verify accessibility

## Troubleshooting

**Issue**: Form fields appear with wrong colors
**Solution**: Ensure you're importing the theme constants (dsTextPrimary, dsSurface, etc.)

**Issue**: Cannot scroll form when keyboard appears
**Solution**: Wrap the form in `SingleChildScrollView`

**Issue**: Validation messages not showing
**Solution**: Check that Form wrapper has the key and validate is being called

**Issue**: Dropdown not updating
**Solution**: Ensure onChanged callback includes `setState()`

## Contributing

When adding new form components:
1. Keep them consistent with existing components
2. Document all parameters
3. Add examples in this guide
4. Test on multiple screen sizes
5. Ensure accessibility compliance
