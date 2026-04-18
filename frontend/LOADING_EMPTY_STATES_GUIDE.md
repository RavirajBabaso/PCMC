# Loading & Empty States System

Complete system for handling loading states, skeleton screens, empty states, and error states throughout the application.

## Components Overview

### Loading Indicators

#### EnhancedLoadingIndicator
Multiple animation styles with optional messaging.

```dart
// Spinner (default)
LoadingIndicator(
  type: LoadingType.spinner,
  size: 48,
  color: dsAccent,
)

// Dots animation
LoadingIndicator(
  type: LoadingType.dots,
  message: 'Loading data...',
  fullScreen: true,
)

// Bars animation
LoadingIndicator(
  type: LoadingType.bars,
)

// Pulse animation
LoadingIndicator(
  type: LoadingType.pulse,
)

// Wave animation
LoadingIndicator(
  type: LoadingType.wave,
)
```

**Types:**
- `spinner` - Spinning circle (default)
- `dots` - Animated dots bouncing
- `bars` - Animated bars moving
- `pulse` - Pulsing ring with center dot
- `wave` - Wave motion effect

**Parameters:**
- `type`: LoadingType - Animation style
- `size`: double - Indicator size (default: 48)
- `color`: Color - Animation color (default: dsAccent)
- `message`: String - Optional loading message (optional)
- `fullScreen`: bool - Center on screen with message (default: false)

### Skeleton Screens

#### CardSkeleton
Loading skeleton for list of cards/items.

```dart
CardSkeleton(
  count: 3,
  spacing: 16,
  padding: EdgeInsets.all(16),
)
```

#### ListSkeleton
Skeleton for list items with avatar and text.

```dart
ListSkeleton(
  itemCount: 6,
  spacing: 12,
  padding: EdgeInsets.all(16),
)
```

#### FormSkeleton
Skeleton for form with fields and button.

```dart
FormSkeleton(
  fieldCount: 4,
  spacing: 20,
  padding: EdgeInsets.all(20),
)
```

#### ImageCardSkeleton
Skeleton for image cards with text.

```dart
ImageCardSkeleton(
  count: 3,
  imageHeight: 180,
)
```

#### TableSkeleton
Skeleton for data tables/grids.

```dart
TableSkeleton(
  rowCount: 5,
  columnCount: 3,
)
```

#### ProfileSkeleton
Skeleton for profile pages.

```dart
ProfileSkeleton(
  padding: EdgeInsets.all(20),
)
```

#### DetailPageSkeleton
Skeleton for detail/article pages.

```dart
DetailPageSkeleton(
  padding: EdgeInsets.all(16),
)
```

### Empty States

#### EnhancedEmptyState
Empty state with illustration and optional actions.

```dart
EnhancedEmptyState(
  type: EmptyStateType.noData,
  title: 'No Grievances',
  description: 'You haven\'t filed any grievances yet.',
  actionLabel: 'Create Now',
  onAction: () => _navigateToCreate(),
  onRetry: () => _reload(),
)
```

**Types:**
- `noData` - Inbox/document icon
- `noResults` - Search not found
- `noConnection` - WiFi/connection lost
- `noPermission` - Lock icon
- `maintenance` - Under maintenance
- `comingSoon` - Feature coming soon

#### CustomEmptyState
Empty state with custom illustration widget.

```dart
CustomEmptyState(
  illustration: _buildCustomIllustration(),
  title: 'Custom Title',
  description: 'Custom description',
  onAction: () => _doSomething(),
)
```

### Error States

#### ErrorState
Full-featured error display with retry.

```dart
ErrorState(
  title: 'Something went wrong',
  message: 'Unable to load data. Please try again.',
  errorCode: 'ERR_001',
  onRetry: () => _reload(),
  onDismiss: () => Navigator.pop(context),
)
```

#### MinimalErrorState
Minimal error display for inline use.

```dart
MinimalErrorState(
  message: 'Failed to load',
  onRetry: () => _reload(),
)
```

#### ServerErrorState
Error state for HTTP errors.

```dart
ServerErrorState(
  statusCode: 500,
  statusMessage: 'Custom error message',
  onRetry: () => _reload(),
)
```

#### NetworkErrorState
Error state for network failures.

```dart
NetworkErrorState(
  onRetry: () => _reload(),
)
```

#### TimeoutErrorState
Error state for request timeouts.

```dart
TimeoutErrorState(
  onRetry: () => _reload(),
)
```

### Loading Scaffolds

Combine AppShell with loading/empty states.

#### LoadingScaffold
Simple loading indicator with app shell.

```dart
LoadingScaffold(
  title: 'My Grievances',
  currentRoute: '/citizen/grievances',
  loadingType: LoadingType.dots,
  message: 'Loading your grievances...',
)
```

#### ListLoadingScaffold
List skeleton with app shell.

```dart
ListLoadingScaffold(
  title: 'Grievances',
  currentRoute: '/citizen/grievances',
  itemCount: 6,
)
```

#### FormLoadingScaffold
Form skeleton with app shell.

```dart
FormLoadingScaffold(
  title: 'Edit Profile',
  currentRoute: '/profile/edit',
  fieldCount: 5,
)
```

#### CardLoadingScaffold
Card skeleton with app shell.

```dart
CardLoadingScaffold(
  title: 'My Tasks',
  cardCount: 3,
)
```

#### EmptyScaffold
Empty state with app shell.

```dart
EmptyScaffold(
  title: 'My Grievances',
  type: EmptyStateType.noData,
  emptyTitle: 'No Grievances',
  emptyDescription: 'You haven\'t filed any grievances yet.',
  actionLabel: 'Create New',
  onAction: () => _navigateToCreate(),
)
```

#### ErrorScaffold
Error state with app shell.

```dart
ErrorScaffold(
  title: 'My Grievances',
  errorTitle: 'Failed to Load',
  errorMessage: 'Unable to fetch your grievances.',
  onRetry: () => _reload(),
)
```

#### AsyncScaffold
Generic async data loading with auto-loading state.

```dart
AsyncScaffold<List<Grievance>>(
  title: 'My Grievances',
  future: _grievanceService.getAll(),
  builder: (context, grievances) => GrievanceList(items: grievances),
  errorBuilder: (context, error) => MinimalErrorState(
    message: 'Failed to load grievances',
  ),
  onRefresh: () => Future.delayed(
    Duration(milliseconds: 500),
    () => _reload(),
  ),
)
```

#### StreamScaffold
Generic stream data with auto-loading state.

```dart
StreamScaffold<List<Notification>>(
  title: 'Notifications',
  stream: _notificationService.watchNotifications(),
  builder: (context, notifications) => NotificationList(
    items: notifications,
  ),
)
```

## Usage Patterns

### Pattern 1: Loading Indicator in List View

```dart
ref.watch(grievancesProvider).when(
  loading: () => const Center(
    child: LoadingIndicator(
      type: LoadingType.dots,
      message: 'Loading your grievances...',
    ),
  ),
  data: (grievances) => ListView.builder(
    itemCount: grievances.length,
    itemBuilder: (context, index) => GrievanceCard(
      grievance: grievances[index],
    ),
  ),
  error: (error, _) => MinimalErrorState(
    message: error.toString(),
    onRetry: () => ref.refresh(grievancesProvider),
  ),
)
```

### Pattern 2: Skeleton Loading with Riverpod

```dart
ref.watch(userProvider).when(
  loading: () => const ProfileSkeleton(),
  data: (user) => ProfileView(user: user),
  error: (error, _) => ServerErrorState(
    statusCode: 500,
    onRetry: () => ref.refresh(userProvider),
  ),
)
```

### Pattern 3: Empty State with Action

```dart
if (grievances.isEmpty) {
  return EnhancedEmptyState(
    type: EmptyStateType.noData,
    title: 'No Grievances Yet',
    description: 'Start by filing a new grievance',
    actionLabel: 'File New Grievance',
    onAction: () => _navigateToSubmit(),
  );
}
```

### Pattern 4: List with Loading and Empty States

```dart
return ref.watch(grievancesProvider).when(
  loading: () => ListLoadingScaffold(
    title: 'My Grievances',
    itemCount: 6,
  ),
  data: (grievances) {
    if (grievances.isEmpty) {
      return EmptyScaffold(
        title: 'My Grievances',
        type: EmptyStateType.noData,
        emptyTitle: 'No Grievances',
        emptyDescription: 'You haven\'t filed any grievances yet.',
        actionLabel: 'Create New',
        onAction: () => _navigateToCreate(),
      );
    }
    return GrievanceListView(items: grievances);
  },
  error: (error, _) => ErrorScaffold(
    title: 'My Grievances',
    errorTitle: 'Failed to Load',
    errorMessage: error.toString(),
    onRetry: () => ref.refresh(grievancesProvider),
  ),
)
```

## Color Scheme

All components respect the app theme:
- Background: `dsBackground` (#0F2438)
- Surface: `dsSurface` (#132A46)
- Accent: `dsAccent` (#00E5FF)
- Text Primary: `dsTextPrimary` (#E8F1F9)
- Text Secondary: `dsTextSecondary` (#8BA3BE)

## Best Practices

1. **Use appropriate skeleton** - Match content structure
   - CardSkeleton for cards
   - ListSkeleton for lists
   - FormSkeleton for forms

2. **Provide helpful loading messages** - Add context
   ```dart
   message: 'Fetching your profile...'
   ```

3. **Show empty states before errors** - Better UX
   ```dart
   if (data.isEmpty) return EmptyState();
   if (hasError) return ErrorState();
   ```

4. **Use scaffolds for full pages** - Consistent layout
   ```dart
   return AsyncScaffold(
     title: 'Page Title',
     future: _loadData(),
     builder: (context, data) => MyContent(data),
   );
   ```

5. **Provide meaningful error messages** - Help users
   ```dart
   'No connection. Check your internet and try again.'
   ```

6. **Allow retry actions** - Users can recover
   ```dart
   onRetry: () => ref.refresh(dataProvider)
   ```

## Animation Performance

- Skeleton screens use lightweight opacity animations
- Loading indicators are optimized for smooth 60fps
- Use `DisposableAnimationController` for cleanup
- All animations dispose properly in dispose()

## Accessibility

- All states include text descriptions
- Loading messages are provided
- Error messages are clear and helpful
- Buttons have proper labels

## Migration Guide

Replace old patterns:

```dart
// OLD
if (isLoading) return LoadingIndicator();
if (isEmpty) return EmptyState(icon: Icons.inbox);

// NEW
if (isLoading) return ListLoadingScaffold(
  title: 'My Items',
  itemCount: 6,
);
if (isEmpty) return EmptyScaffold(
  title: 'My Items',
  type: EmptyStateType.noData,
  emptyTitle: 'No Items',
  emptyDescription: 'You have no items yet.',
);
```

## Troubleshooting

**Issue**: Skeleton doesn't match content
**Solution**: Choose the right skeleton type matching your content

**Issue**: Loading indicator animates too fast/slow
**Solution**: Adjust animation duration in component (default: 1000-1200ms)

**Issue**: Empty state text is cut off
**Solution**: Use appropriate padding/constraints

**Issue**: Error message not visible
**Solution**: Ensure errorBuilder returns proper widget
