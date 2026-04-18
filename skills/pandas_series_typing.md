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
For arithmetic on `Series[Any]`, use overloads that return the most likely valid type if the operation is valid for some types. This "Progressive" approach ensures that even when the source type is unknown, the result type can be tracked if the operation itself is specialized.
- **Goal**: Maintain type safety while reducing the need for explicit casts.
- **Example**: 
  ```python
  @overload
  def __sub__(self: Series[Any], other: Series[Timestamp]) -> Series[Timedelta]: ...
  @overload
  def __add__(self: Series[Any], other: Series[str]) -> Series[str]: ...
  ```

### 8. Numeric vs. Boolean Arithmetic Specialization
Differentiate between `bool` and numeric types (`int`, `float`, `complex`) in arithmetic overloads to catch runtime errors that only affect booleans.
- **Pattern**: Use specialized overloads for `Series[bool]` that return `Never` or raise an error for unsupported operations (e.g., subtraction), while allowing them for numeric dtypes.
- **Example**:
  ```python
  @overload
  def sub(self: Series[bool], other: bool | Series[bool]) -> Never: ...  # Catch numpy boolean subtract error
  @overload
  def sub(self: Series[int], other: bool | Series[bool]) -> Series[int]: ... # Allowed
  ```

### 9. Refined Return Types for `to_numpy()`
Ensure `to_numpy()` reflects the dimensionality and dtype of the Series.
- **Rule**: `to_numpy()` on a Series should return a 1D numpy array (`np_1darray`) parameterized by the Series' subtype.
- **Advanced Pattern**: Use `@type_check_only` internal generic subclasses to track numpy dtypes without exposing them to users.

### 10. String Method Type Constraints
Methods like `.str.contains`, `.str.startswith`, and `.str.endswith` are moving towards stricter typing for the `na` parameter.
- **Rule**: Deprecate allowing non-bool values for `na` in these methods for dtypes that do not already disallow them.
- **Enhancement**: `str.get` accepts any hashable object, not just `int`. `str.translate` table parameter should be covariant. `str.wrap` parameters are keyword-only.

### 11. Series-Specific Parameter Changes in 3.0
- **`map`**: Now accepts `**kwargs` to pass to the function. The `arg` parameter is deprecated; use `func` instead. It also accepts an `engine` parameter (e.g., `Literal["python", "numba"]`).
- **`apply`**: `convert_dtype` argument has been removed.
- **`where` and `mask`**: The `other` parameter now explicitly supports `None` (type hint `Scalar | None`).
- **`shift`**: The `freq` argument now accepts `BaseOffset` (which includes offsets like `BDay`), rather than being restricted to `DateOffset`.
- **`reindex`**: The `tolerance` parameter now accepts `Timedelta` in addition to `float`.
- **`str` accessors**:
    - `str.get_dummies()` now accepts a `dtype` parameter.
    - `str.isascii()` added.
    - `str.replace()` allows a `dict` to be passed via the `pat` parameter.
- **`copy` argument deprecation**: Deprecated in `truncate`, `tz_convert`, `tz_localize`, `infer_objects`, `align`, `astype`, `reindex`, `reindex_like`, `set_axis`, `to_period`, `to_timestamp`, and `rename`.
- **Dtype Changes**: In Pandas 3.0, the default type for string-like data is `StringDtype`, which may not support certain arithmetic (like division) previously allowed on `object` dtypes. Use `PD_LTE_23` version guards for tests covering these behaviors.

### 11. Deprecation of Implicit Array Casting for Tuples
Performing arithmetic operations (like addition) between `Series` and `tuple` is deprecated and raises a `Pandas4Warning`.
- **Recommendation**: Ensure tests wrap such operations with `Pandas4Warning`. Future stubs may need to forbid this entirely.

### 12. Protocol-based Aggregations (`sum`, `cumprod`)
Aggregation methods like `sum`, `cumsum`, `prod`, and `cumprod` now use internal protocols like `_SupportsAdd` and `_SupportsMultiply`.
- **Goal**: The return type of `Series.sum` depends on the return value of its elements' `__add__` method, making it more generic and future-proof (e.g., supporting `Series[np.bool_]`).

### 13. Comprehensive Removal of Specialized Series Subclasses
Continuing the architectural cleanup, `IntervalSeries`, `PeriodSeries`, and `OffsetSeries` have been removed.
- **Replacement**: Use the generic `Series[T]` (e.g., `Series[Interval]`, `Series[Period]`, `Series[BaseOffset]`). This simplifies the stub hierarchy and aligns with the long-term goal of using a single parameterized `Series` class.

### 14. Support for Categorical Dtypes in Constructors
`Series` and `Index` constructors now explicitly support `dtype='category'`.
- **Pattern**: When using this dtype, the return type should be `Series[pd.CategoricalDtype]` or `CategoricalIndex` to ensure categorical-specific methods are available.

### 15. Pandas 3.0: Disallowed Boolean Multiplication
Multiplication involving `bool` and `str` or `bool` and `Timedelta` is now disallowed in Pandas 3.0.
- **Typing**: The stubs should return `Never` or raise an error for these combinations (e.g., `Series[bool] * Series[str]`, `Timedelta * bool`).

### 16. `ElementOpsMixin` for Shared Arithmetic
The introduction of `ElementOpsMixin` helps consolidate arithmetic logic shared between `Series` and `Index`.
- **Benefit**: Reduces code duplication and ensures that complex arithmetic overloads (including those for `Series[Any]`) are implemented consistently across both core objects.

### 17. Removal of Deprecated `view` Method
The `Series.view` method was deprecated in pandas 2.2 and has been removed from the stubs to encourage users to use `astype` or other modern alternatives.

### 18. Redundancy in `isin` Parameter
The `values` parameter in `Series.isin` should be typed as `Iterable` (or `ListLike`). Specifying `Iterable | Series` is redundant because `Series` already inherits from `Iterable`.

### 19. Support for `FloatingArray` and `Pandas` Dtypes
Constructor (`__new__`) and `astype` methods now have refined overloads for `FloatingArray` and other pandas-specific nullable dtypes.
- **Pattern**: Use specialized `DtypeArg` categories to distinguish between `Numpy`, `Pandas` (nullable), and `PyArrow` dtypes, as they lead to different internal array implementations.

### 20. Precise Return Types for `to_numpy()`
`Series.to_numpy()` return type is being refined to use 1D array aliases (e.g., `np_1darray_int`, `np_1darray_float`) from `_typing.pyi` instead of generic `npt.NDArray`.

## Best Practices
- **Prioritize Overloads**: If a method's return type depends on an argument's type, always use `@overload`.
- **Use Internal Aliases**: Avoid repeating large `Union` types; use `_typing.pyi` to define them once.
- **Minimal Implementation**: Stubs should only contain signatures, no logic. Use `...` for bodies.
- **Inheritance**: Leverage mixins (e.g., `IndexOpsMixin`) for shared functionality between Series and Index.
- **Strict Mode Compatibility**: Use `Series[Any]` or a dedicated `UnknownSeries` alias instead of plain `Series` to avoid "partially unknown" errors in strict mode.
- **String Method Type Constraints**: Methods like `.str.contains`, `.str.startswith`, and `.str.endswith` are moving towards stricter typing for the `na` parameter. Ensure properties like `s.str` pass down the subtype `S1` to the resulting methods.
- **Stricter Boolean Flags**: For parameters like `na` in string methods, prefer `bool` over broader types to align with pandas' move toward consistency.
