# Skill: Typing for Pandas Time-Series and Offsets

## Description
This skill covers specialized typing for pandas time-series functionality, including frequency offsets, date ranges, and datetime format guessing.

## Patterns

### 1. Expanded Support for `timedelta`
Many functions that previously only accepted pandas-specific offset strings or objects now support Python's native `datetime.timedelta`.
- **Pattern**: Update signatures to include `timedelta` in unions for frequency and offset parameters.
- **Example**: `to_offset()` now explicitly supports `datetime.timedelta`.

### 2. Public API and Constructor Enhancements
- **`Timedeltas.__new__`**: Now accepts `nanoseconds` as a constructor argument. Also accepts `Tick` objects (e.g., `Minute`, `Hour`, `Day`) in its first argument (`value`).
- **`Easter`**: Gained a `method` argument for different calculation methods (e.g., Orthodox).
- **`Holiday`**: Gained `exclude_dates` argument.
- **`BDay`**: Inherits from `BaseOffset` directly, not `DateOffset`. Ensure that parameters accepting offsets (like `freq` in `Series.shift`) use `BaseOffset` where appropriate.
- **`timedelta_range`**: Requires multiple overloads to correctly infer return types based on combinations of `start`, `end`, `periods`, and `freq`.
- **New Offsets**: `HalfYearBegin`, `HalfYearEnd`, `BHalfYearBegin`, `BHalfYearEnd`.
- **`guess_datetime_format`**: Now part of the public `tseries.api`.
- **`Timestamp - TimestampSeries`**: Should return `TimedeltaSeries`.
- **`TimedeltaSeries.cumsum()`**: Should return `TimedeltaSeries` to ensure downstream operations (like adding a Timestamp) work correctly.
- **`TimeAmbiguous`**: The `ambiguous` parameter in time-related functions (like `tz_localize`) now explicitly supports a single `bool` as well as arrays of bools.

### 3. Handling Deprecated Temporal Methods and Properties
- **Property Deprecations**: `dayofweek`, `dayofyear`, and `daysinmonth` are deprecated in favor of `day_of_week`, `day_of_year`, and `days_in_month` across temporal objects.
- **Alternative Methods**: `Timestamp.utcfromtimestamp()` and `Timestamp.utcnow()` are deprecated in favor of `Timestamp.fromtimestamp(ts, "UTC")` and `Timestamp.now("UTC")`.

### 4. Public Export of Temporal Errors
- **`IncompatibleFrequency`**: This error is now explicitly exported in `pandas.errors`, aligning the stubs with the documented public API.

### 5. NaT Comparison Stricter Behavior
- **`NaT` vs `datetime.date`**: Comparisons between `NaT` and `datetime.date` objects now raise on inequality comparisons (`<`, `<=`, `>`, `>=`). The stubs should reflect this by potentially using `Never` or documenting the raising behavior for these specific types.

## Best Practices
- **Union Alignment**: Always check if `timedelta` should be added to `Offset` or `Frequency` type aliases when pandas updates its support.
- **Explicit Timezones**: When typing methods that involve UTC or other timezones, prefer signatures that encourage passing the timezone as an argument rather than using deprecated specialized methods.
