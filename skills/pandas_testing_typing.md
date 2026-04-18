# Skill: Typing for Pandas Testing Utilities

## Description
This skill covers the typing of pandas testing functions, such as `assert_frame_equal`, `assert_series_equal`, and `assert_index_equal`. It focuses on maintaining consistency with pandas' internal testing logic and handling deprecations in testing arguments.

## Patterns

### 1. Consistency Across Testing Functions
Testing functions for different pandas objects (`DataFrame`, `Series`, `Index`) often share similar parameters (e.g., `check_dtype`, `check_exact`).
- **Goal**: Ensure that shared parameters have consistent types across all `assert_*_equal` functions.

### 2. Handling Deprecations in Testing
Pandas occasionally deprecates or removes parameters in its testing suite to simplify the API or remove redundant checks.
- **Pattern**: Mark deprecated parameters in stubs as soon as they are deprecated in pandas.
- **`pytest_warns_bounded`**: When moving to a new major version (e.g., 3.0), remove "expired" `pytest_warns_bounded` (where the upper bound is less than the current version).
- **Example**: `check_datetimelike_compat` has been deprecated in `assert_frame_equal`, `assert_series_equal`, and `assert_index_equal` in pandas 3.0.

### 3. Flexible Input Types for Comparisons
Testing functions often accept a variety of types for comparison, especially for `Index` and `Series`.
- **Note**: Ensure that the stubs reflect the actual flexibility of the runtime (e.g., comparing a `RangeIndex` with a generic `Index`).
- **`assert_type`**: Mandatory for new tests in `pandas-stubs` to verify return types of public methods.

## Best Practices
- **Mirror Runtime Deprecations**: If a parameter starts raising a `FutureWarning` at runtime, it should be noted or handled carefully in the stubs to warn users.
- **Strictness where Necessary**: Use `bool` for flags rather than `Any` to provide better type safety during testing development.
