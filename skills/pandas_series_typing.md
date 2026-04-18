# Skill: Advanced Typing for Pandas-like Series

## Description
This skill provides patterns and guidelines for creating or maintaining high-fidelity typing stubs for Series-like objects, based on `pandas-stubs`. It covers complex overloads, generic specialization, and method chaining.

## Patterns

### 1. Constructor Overloading for Type Specialization
When a constructor takes a variety of data types (sequences, dictionaries, scalars), use overloads to specialize the return type.
- **Goal**: Map input `data` type to the generic type parameter of the Series.
- **Example**:
  ```python
  @overload
  def __new__(cls, data: Sequence[int], ...) -> Series[int]: ...
  @overload
  def __new__(cls, data: Sequence[Timestamp], ...) -> Series[Timestamp]: ...
  ```

### 2. Generic Type Aliases with Default Any
Use a `TypeVar` with a bound and a default (PEP 696) to allow both generic and non-generic usage.
- **Pattern**: `S1 = TypeVar("S1", bound=SeriesDType, default=Any)`
- **Benefit**: `Series` (shorthand for `Series[Any]`) works alongside `Series[int]`.

### 3. Specialized Type Aliases
Define central type aliases for common unions to ensure consistency across the codebase.
- `Scalar`: Union of native Python types, NumPy scalars, and custom types like `Timestamp`.
- `SeriesDType`: A broad alias for types that can be stored in a Series.
- `Dtype`: Handles both `ExtensionDtype` and NumPy dtypes.

### 4. Method Chaining with `Self`
Use `Self` (PEP 673) for methods that return a modified copy of the object.
- **Goal**: Ensure subclasses return their own type without re-declaring methods.
- **Example**:
  ```python
  from typing_extensions import Self
  def rename(self, index: IndexLabel = ..., ...) -> Self: ...
  ```

### 5. Interaction Overloads
Handle methods that change the object's dimensionality (e.g., `to_frame`) or interact with other core types (e.g., `Index`).
- `Series.to_frame()` -> `DataFrame`
- `Index.to_series()` -> `Series`

### 6. Transition from Specialized Series to Generic Series
Replace specialized classes like `TimestampSeries` and `TimedeltaSeries` with generic `Series[Timestamp]` and `Series[Timedelta]`.
- **Reason**: More intuitive for users; they can use `pd.Series[pd.Timestamp]` directly for casts.
- **Pattern**: Ensure all arithmetic operations that previously returned specialized Series now return correctly-parameterized generic Series.

### 7. Progressive Arithmetic Overloading for `Series[Any]`
For arithmetic on `Series[Any]`, use overloads that return the most likely valid type if the operation is valid for some types.
- **Goal**: Maintain type safety while reducing the need for explicit casts.
- **Example**: 
  ```python
  @overload
  def __sub__(self: Series[Any], other: Series[Timestamp]) -> Series[Timedelta]: ...
  ```

### 8. Specific Rules for Reductions
For certain reduction methods, the return type should be consistent even for untyped Series.
- **Rule**: `median`, `mean`, and `std` should return `float` on untyped `Series` (e.g., `Series[Any]`) as it is more user-friendly and usually the runtime result.

### 9. String Method Type Constraints
Methods like `.str.contains`, `.str.startswith`, and `.str.endswith` are moving towards stricter typing for the `na` parameter.
- **Rule**: Deprecate allowing non-bool values for `na` in these methods for dtypes that do not already disallow them.

### 10. Series-Specific Parameter Changes in 3.0
- **`map`**: Now accepts `**kwargs` to pass to the function. The `arg` parameter is deprecated; use `func` instead.
- **`apply`**: `convert_dtype` argument has been removed.
- **`str.get_dummies`**: Now accepts a `dtype` parameter.
- **`str.isascii`**: New method for checking if strings are ASCII.
- **`str.replace`**: Now accepts a dictionary for the `pat` parameter.
- **`copy` argument deprecation**: Deprecated in `truncate`, `tz_convert`, `tz_localize`, `infer_objects`, `align`, `astype`, `reindex`, `reindex_like`, `set_axis`, `to_period`, `to_timestamp`, and `rename`.
- **Property Deprecations**: `dayofweek`, `dayofyear`, and `daysinmonth` are deprecated in favor of `day_of_week`, `day_of_year`, and `days_in_month`.
- **`to_datetime`**: Now correctly accepts `integer` and `floating` ndarrays as arguments.
- **`diff()` on `Series[Any]`**: Refined return type to avoid conflicts with specialized Series like `Series[Timestamp]`.
- **`loc.__setitem__`**: Fixed key typing to allow `Index[Any]` instead of forcing matching `S1` type.

### 11. Deprecation of Implicit Array Casting for Tuples
Performing arithmetic operations (like addition) between `Series` and `tuple` is deprecated and raises a `Pandas4Warning`.
- **Recommendation**: Ensure tests wrap such operations with `Pandas4Warning`. Future stubs may need to forbid this entirely.

## Best Practices
- **Prioritize Overloads**: If a method's return type depends on an argument's type, always use `@overload`.
- **Use Internal Aliases**: Avoid repeating large `Union` types; use `_typing.pyi` to define them once.
- **Minimal Implementation**: Stubs should only contain signatures, no logic. Use `...` for bodies.
- **Inheritance**: Leverage mixins (e.g., `IndexOpsMixin`) for shared functionality between Series and Index.
- **Stricter Boolean Flags**: For parameters like `na` in string methods, prefer `bool` over broader types to align with pandas' move toward consistency.
