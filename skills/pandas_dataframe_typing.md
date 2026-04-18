# Skill: Advanced Typing for Pandas-like DataFrames

## Description
This skill covers advanced typing patterns for DataFrame-like objects, focusing on multi-dimensional indexing, literal-based dispatch, and I/O return type switching.

## Patterns

### 1. Literal-based Dispatch for Return Types
Use `Literal` in `@overload` to switch return types based on argument values (e.g., axes, orientations).
- **Goal**: Return `Series` vs `DataFrame` depending on an `axis` argument.
- **Example**:
  ```python
  @overload
  def apply(self, func: ..., axis: Literal[0, "index"] = ...) -> Series: ...
  @overload
  def apply(self, func: ..., axis: Literal[1, "columns"]) -> DataFrame: ...
  ```

### 2. Multi-Dimensional Indexer Classes
For complex indexing (`loc`, `iloc`), use dedicated indexer classes rather than simple methods.
- **Pattern**: `loc` returns an instance of `_LocIndexerFrame`.
- **Benefit**: Encapsulates the massive number of overloads needed for different slice/list/scalar combinations.

### 3. I/O Return Type Switching (The "Path" Pattern)
Methods that save to a file or return a string should switch return types based on the presence of a path.
- **Pattern**: 
  - If `path` is provided -> returns `None`.
  - If `path` is `None` -> returns `str` or `bytes`.
- **Example**:
  ```python
  @overload
  def to_json(self, path_or_buf: FilePath | WriteBuffer[str], ...) -> None: ...
  @overload
  def to_json(self, path_or_buf: None = ..., ...) -> str: ...
  ```

### 4. Indexing "Hacks" and Mixins
Use mixins (e.g., `_GetItemHack`) to handle complex `__getitem__` logic without cluttering the main class.
- **Goal**: Distinguish between `df['col']` (returns `Series`) and `df[['col1', 'col2']]` (returns `DataFrame`).

### 5. Type Aliases for Flexibility
- `IndexLabel`: `Hashable | Sequence[Hashable]` (supports single labels and list of labels).
- `Axes`: Generic term for labels/indices.
- `ListLike`: Broad type for anything that behaves like a sequence (lists, arrays, series).

### 6. Handling `Series[Unknown]` vs. `Series[Any]` from DataFrames
Methods like `DataFrame.__getattr__` or `DataFrame.__getitem__` return `Series` objects that might have ambiguous types.
- **Discrepancy**: `pyright` sees this as `Series[Unknown]` while `mypy` sees it as `Series[Any]`.
- **Typing Recommendation**: Use a "Progressive approach" in subsequent arithmetic (e.g., `df['col'] - pd.Timestamp(...)`) so that both type checkers can infer a useful result (like `Series[Timedelta]`) without forcing an immediate cast.

### 7. Parameter Expansion and Deprecations in 3.0
- **`pivot_table`**: Now supports passing keyword arguments to `aggfunc` through `**kwargs`. Ensure the signature reflects this flexibility.
- **`plot.kde`**: Added `weights` parameter for PDF estimation.
- **`plot.scatter`**: Argument `c` now accepts a column of strings, where rows with the same string are colored identically.
- **`set_option`**: Now accepts a dictionary of options, simplifying configuration of multiple settings at once.
- **`iloc`**: Now supports boolean masks in `__getitem__` for more consistent indexing behavior across different pandas objects.
- **`json_normalize`**: Now supports passing a `Series` input while retaining the `Index`.
- **`concat`**: Behavioral change in 3.0—will raise a `ValueError` when `ignore_index=True` and `keys` is not `None`. The stubs should ideally reflect this constraint if possible, or at least be aware of it.
- **`corrwith`**: Now accepts `min_periods` as an optional argument, similar to `corr()`.
- **`cummin`, `cummax`, `cumprod`, `cumsum`**: Now have a `numeric_only` parameter.
- **`read_parquet`**: Now accepts `to_pandas_kwargs` which are forwarded to pyarrow.
- **`read_spss`**: Now supports `**kwargs` for pyreadstat.
- **`read_iceberg` and `to_iceberg`**: New functions/methods for Apache Iceberg support.
- **`copy` argument deprecation**: Deprecated in `truncate`, `tz_convert`, `tz_localize`, `infer_objects`, `align`, `astype`, `reindex`, `reindex_like`, `set_axis`, `to_period`, `to_timestamp`, `rename`, `transpose`, `swaplevel`, and `merge`.
- **Removals**: `swapaxes` has been removed. `pct_change` has deprecated the `limit` argument (must be `None`). `to_json` deprecated `epoch` date format in favor of `iso`. `mode.use_inf_as_na` has been removed from options.
- **Deprecations**: `set_index` deprecated the `verify_integrity` keyword; users should directly check `obj.index.is_unique` instead.
- **`col` / `Expression`**: `pd.col` (and `Expression` class) added to allow expression-based assignment in `assign`.

## Best Practices
- **Encapsulate Complexity**: Move complex indexer logic into private `_Indexer` classes.
- **Shared Base**: Use `NDFrame` as a generic base for shared `Series` and `DataFrame` methods, utilizing `Self`.
- **Granular Literals**: Use specific `Literal` types for `orient` in `to_dict` to provide precise return shapes (e.g., `dict[Hashable, dict]`).
- **Major Version Cleanup**: When a major version (3.0) removes methods like `swapaxes`, they should be removed from the stubs to match runtime behavior.
- **Top-level Function Updates**: Regularly check top-level functions like `concat` and `json_normalize` for signature changes that improve consistency or add support for new input types like `Series`.
