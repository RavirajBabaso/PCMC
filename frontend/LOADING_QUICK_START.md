# Quick Start: Loading & Empty States

## 5-Minute Integration Guide

### 1. As Simple As This

#### Loading State
```dart
import 'package:main_ui/widgets/loading_indicator.dart';

// Spinner
LoadingIndicator()

// With message
LoadingIndicator(
  type: LoadingType.dots,
  message: 'Loading...',
  fullScreen: true,
)
```

#### Empty State
```dart
import 'package:main_ui/widgets/enhanced_empty_states.dart';

EnhancedEmptyState(
  type: EmptyStateType.noData,
  title: 'No items',
  description: 'You have no items yet',
  actionLabel: 'Create',
  onAction: () => _create(),
)
```

#### Error State
```dart
import 'package:main_ui/widgets/error_states.dart';

ErrorState(
  title: 'Failed to load',
  message: 'Please check your connection',
  onRetry: () => _reload(),
)
```

### 2. For Load States

```dart
// Show skeleton while loading
ref.watch(itemsProvider).when(
  loading: () => ListSkeleton(itemCount: 6),
  data: (items) => ItemList(items: items),
  error: (error, _) => MinimalErrorState(
    message: error.toString(),
  ),
)
```

### 3. For Full Pages

```dart
// Use AsyncScaffold for complete page
return AsyncScaffold<List<Item>>(
  title: 'My Items',
  future: _loadItems(),
  builder: (context, items) => ItemList(items: items),
)
```

## Common Patterns

### Pattern: List with all states
```dart
return ref.watch(itemsProvider).when(
  loading: () => ListLoadingScaffold(
    title: 'Items',
    itemCount: 6,
  ),
  data: (items) => items.isEmpty
    ? EmptyScaffold(
        title: 'Items',
        type: EmptyStateType.noData,
        emptyTitle: 'No Items',
        emptyDescription: 'Create one to get started',
        actionLabel: 'Create',
        onAction: () => _create(),
      )
    : ItemsList(items: items),
  error: (error, _) => ErrorScaffold(
    title: 'Items',
    errorTitle: 'Failed to Load',
    errorMessage: error.toString(),
    onRetry: () => ref.refresh(itemsProvider),
  ),
)
```

### Pattern: Form with skeleton
```dart
return ref.watch(formProvider).when(
  loading: () => FormLoadingScaffold(
    title: 'Edit Profile',
    fieldCount: 5,
  ),
  data: (formData) => MyForm(data: formData),
  error: (error, _) => MinimalErrorState(
    message: 'Failed to load form',
    onRetry: () => ref.refresh(formProvider),
  ),
)
```

### Pattern: Search with no results
```dart
if (searchResults.isEmpty && hasSearched) {
  return EnhancedEmptyState(
    type: EmptyStateType.noResults,
    title: 'No results found',
    description: 'Try a different search term',
    onRetry: () => _clearSearch(),
  );
}
```

## Animation Types Comparison

| Type | Use Case | Speed |
|------|----------|-------|
| `spinner` | Default/safe choice | Fast |
| `dots` | List loading | Fast |
| `bars` | Form loading | Medium |
| `pulse` | File loading | Slow |
| `wave` | Sync/update | Medium |

## Empty State Types

| Type | Icon | Use Case |
|------|------|----------|
| `noData` | 📭 | No items created |
| `noResults` | 🔍 | Search returned nothing |
| `noConnection` | 📡 | Network error |
| `noPermission` | 🔒 | Access denied |
| `maintenance` | 🔧 | Under maintenance |
| `comingSoon` | ⭐ | Feature not ready |

## Skeleton Types

| Type | Best For |
|------|----------|
| `CardSkeleton` | Card lists |
| `ListSkeleton` | Item lists |
| `FormSkeleton` | Forms |
| `ImageCardSkeleton` | Image galleries |
| `TableSkeleton` | Data grids |
| `ProfileSkeleton` | Profile pages |
| `DetailPageSkeleton` | Articles/details |

## Color Customization

```dart
EnhancedEmptyState(
  type: EmptyStateType.noData,
  primaryColor: Colors.blue,
  secondaryColor: Colors.blue.withOpacity(0.3),
  title: 'No data',
  description: 'Create data to get started',
)
```

## Callback Patterns

### Retry
```dart
onRetry: () => ref.refresh(dataProvider)
```

### Navigate
```dart
onAction: () => Navigator.pushNamed(context, '/create')
```

### Inline Action
```dart
onAction: () {
  _controller.text = '';
  _search();
}
```

## Migration Checklist

- [ ] Replace `LoadingIndicator()` with `LoadingIndicator(type: LoadingType.dots)`
- [ ] Replace icon-only empty states with `EnhancedEmptyState`
- [ ] Add `ListSkeleton` for list loading states
- [ ] Add `FormSkeleton` for form loading
- [ ] Add return/retry buttons to all error states
- [ ] Use `AsyncScaffold` for full pages
- [ ] Test all animation speeds feel right
- [ ] Verify illustrations show correctly

## Import Everything

```dart
// All at once
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/widgets/skeleton_screens.dart';
import 'package:main_ui/widgets/enhanced_empty_states.dart';
import 'package:main_ui/widgets/error_states.dart';
import 'package:main_ui/widgets/loading_scaffolds.dart';
```

## Troubleshooting

**"Animation jumpy"** → Use correct `LoadingType` for content
**"Skeleton too tall"** → Adjust `itemCount` parameter
**"Button not working"** → Check `onAction` callback
**"Empty state text cut off"** → Increase `padding` parameter

## Performance Tips

✓ Skeletons use lightweight opacity (no heavy renders)
✓ All animations dispose properly
✓ Use `const` where possible  
✓ Limit skeleton `itemCount` to ~6 items
✓ Prefer `AsyncScaffold` over manual FutureBuilder

## More Examples

See `LOADING_EMPTY_STATES_GUIDE.md` for:
- Advanced usage
- All parameters
- Real app examples
- Integration patterns
- Accessibility details
