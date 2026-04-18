# Skill: Advanced Typing for Pandas-like Index Objects

## Description
This skill covers the typing architecture for Index objects, focusing on generic specialization, shared functionality via mixins, and factory-like constructor patterns.

## Patterns

### 1. Generic Index Specialization
Use a generic type parameter (e.g., `S1`) to track the type of data held by the Index.
- **Pattern**: `class Index(IndexOpsMixin[S1], ElementOpsMixin[S1], ...): ...`
- **Goal**: Allow type-safe operations like `idx: Index[int] = pd.Index([1, 2, 3])`.

### 2. The Mixin Pattern for Shared Logic
Extract shared operations (e.g., `shape`, `ndim`, `to_numpy`, `value_counts`) into mixins used by both `Index` and `Series`.
- **Primary Mixin**: `IndexOpsMixin[S1]` (defined in `core/base.pyi`).
- **Benefit**: Ensures consistency between Index and Series APIs without duplication.

### 3. Factory Constructors (`__new__`)
Use dozens of `@overload` signatures on the `Index.__new__` method to return specialized Index types based on input data.
- **Goal**: `pd.Index([1, 2])` returns `Index[int]`, `pd.Index(['a', 'b'])` returns `Index[str]`.
- **Pattern**: 
  ```python
  @overload
  def __new__(cls, data: Sequence[int], ...) -> Index[int]: ...
  @overload
  def __new__(cls, data: Sequence[str], ...) -> Index[str]: ...
  ```

### 4. Specialized Subclasses for Temporal Data
Define subclasses like `DatetimeIndex` and `TimedeltaIndex` for data types with unique attributes (e.g., `.year`, `.days`).
- **Pattern**: Use a common base like `DatetimelikeIndex` if multiple temporal types share logic.

### 5. Multi-Level Indexing (`MultiIndex`)
Treat `MultiIndex` as a specialized `Index` that often holds tuples or complex levels.
- **Note**: `MultiIndex` usually inherits from `Index` but overrides many methods to handle hierarchical levels.

### 6. Temporal Index Arithmetic Mirroring
`TimedeltaIndex` and `DatetimeIndex` arithmetic should mirror the behavior of their Series counterparts (`Series[Timedelta]` and `Series[Timestamp]`).
- **Goal**: Maintain consistency between Series and Index arithmetic operations.
- **Verification**: Use `assert_type()` in tests for both Series and Index to ensure identical typing results for similar operations.

### 7. Removal and Deprecation of Invalid Methods in 3.0
- **`Index.sort()`**: Removed (previously raised `TypeError`, now `AttributeError`).
- **Property Deprecations**: `dayofweek`, `dayofyear`, and `daysinmonth` are deprecated in favor of `day_of_week`, `day_of_year`, and `days_in_month` for temporal indices.

### 8. Enhanced Index Key and Location Support
- **`get_loc`**: Now also accepts subclasses of `tuple` as keys.
- **`MultiIndex.get_loc`**: Return types can be `int`, `slice`, or `np.ndarray[bool]`. Ensure stubs reflect this variability.
- **`from_product`**: Should accept broader iterable types (e.g., `set`) in the `iterables` argument.

### 9. Deprecation of Implicit Array Casting for Tuples
Performing arithmetic operations (like addition) between `Index` and `tuple` is deprecated and raises a `Pandas4Warning`.
- **Note**: This aligns `Index` behavior with `Series` and emphasizes moving away from implicit casting of list-likes.

## Best Practices
- **Bind TypeVars**: Always bind your generic parameters (e.g., to a `SeriesDType` union) to restrict them to valid pandas types.
- **Mixin Cohesion**: Keep `IndexOpsMixin` focused on operations that are truly identical between Index and Series.
- **Accessor Patterns**: For specialized attributes (like temporal ones), consider using descriptors or accessor objects to avoid bloating the main Index classes.
- **Runtime Alignment**: Ensure that methods that raise `AttributeError` at runtime (like `Index.sort`) are not present in the stubs, even if they were present in older versions.
