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
- **`insert`**: Accepts `np.float32` and `np.float64` (and other numpy scalars) as `value`.
- **`assign`**: Now allows `list` and `range` for column values (via `IntoColumn`).
- **`sample`**: Argument `axis` now accepts any `Axis` (Literal 0, 1, 'index', 'columns'), not just `AxisIndex`.
- **`reindex`**: The `tolerance` parameter now accepts `Timedelta` in addition to `float`.
- **`from_records`**: Argument `columns` should be typed as `ListLike | None` (avoiding restrictive `SequenceNotStr[str]`). The `index` parameter should accept `Axes | None` (including `Index` and `Series`), not just `str` or sequences.
- **`loc`**: When using an `Index` for column selection, use `IndexType` in overloads. Avoid `Sequence[str]` for column selection as it is ambiguous with a single `str` label. Stricter typing for `.loc` and `.at` means they may return `Scalar` (including `str`, `bytes`, etc.); comparing results like `df.at[...] > 0` may require an explicit `cast(int, ...)` to satisfy type checkers.
- **`squeeze`**: Can return `DataFrame`, `Series`, or a scalar depending on the shape.
- **`take`**: Supports `np.ndarray` for the `indices` parameter (use `TakeIndexer`).
- **`pct_change`**: Returns a `DataFrame[float]` (or `Series[float]`) as it always results in floats.
- **`to_clipboard`**: Should have explicit typing for parameters matching `to_csv` instead of using `**kwargs`.
- **`squeeze`**: Correctly typed to return the original object type (`DataFrame` or `Series`) if it cannot be squeezed further, in addition to the squeezed result.
- **`float_format`**: Now supports `str` in addition to `Callable` for I/O methods.
- **`assign`**: Now allows `None` and `Sequence[Scalar]` (like `tuple`) for column values via `IntoColumn`.
- **`loc` / `iloc` setters**: Support `Mapping[Hashable, Scalar | NAType | NaTType]` for assigning values.
- **`from_dict`**: Does NOT support a list of dictionaries as input; use `pd.DataFrame()` or `from_records()` instead.
- **Iteration methods (`itertuples`, `iterrows`, `items`)**: Should return `Iterator` rather than just `Iterable`.
- **`pct_change`**: Supports `axis` parameter via `**kwargs` (forwarded to `shift`).
- **`max`, `min`, `any`, `all`**: When `axis=None`, these methods return a scalar instead of a `Series`.
- **`groupby.apply`**: The `include_groups` argument is omitted from stubs to encourage "future-proof" code, as it is deprecated in Pandas 3.0 (where the default `True` behavior is removed).
- **`read_parquet`**: Now accepts `to_pandas_kwargs` which are forwarded to pyarrow.
- **`read_spss`**: Now supports `**kwargs` for pyreadstat.
- **`read_iceberg` and `to_iceberg`**: New functions/methods for Apache Iceberg support.
- **`copy` argument deprecation**: Deprecated in `truncate`, `tz_convert`, `tz_localize`, `infer_objects`, `align`, `astype`, `reindex`, `reindex_like`, `set_axis`, `to_period`, `to_timestamp`, `rename`, `transpose`, `swaplevel`, and `merge`.
- **Removals (Pandas 2.0+)**: `swapaxes` has been removed. `pct_change` has deprecated the `limit` argument (must be `None`). `to_json` deprecated `epoch` date format in favor of `iso`. `mode.use_inf_as_na` has been removed from options. `set_axis(inplace=True)` and `Series.set_axis(inplace=True)` have been removed.
- **Deprecations**: `set_index` deprecated the `verify_integrity` keyword; users should directly check `obj.index.is_unique` instead.
- **`xs`**: Passing a list key to `Series.xs()` or `DataFrame.xs()` is disallowed in Pandas 2.0+ and 3.0. Update stubs to restrict `key` to non-list types.
- **`col` / `Expression`**: `pd.col` (and `Expression` class) added to allow expression-based assignment in `assign`.
- **`__setitem__` support for `Hashable` and `None`**: `DataFrame.__setitem__` now accepts `Hashable` for column names (to match `__iter__` return type) and `Sequence[Scalar | None]` (or `None` scalar) for values to support setting columns to null.
- **`__delitem__`**: `__delitem__` is defined in `NDFrame` (and thus `DataFrame`) to support `del df['col']`.
- **`pivot_table` aggfunc literals**: Common aggregation strings like `'nunique'`, `'sum'`, `'mean'`, etc., are supported in the `aggfunc` literal union.
- **`to_latex` formatters**: `formatters` argument correctly supports `Mapping[str | int, Callable]`.
- **`to_dict`**: Use specialized overloads with `Never` to reject invalid combinations of arguments (e.g., `index` orientation with specific flags). Return types for `orient="index"` are refined to return a nested dictionary `MutableMapping[Hashable, MutableMapping[Hashable, Any]]`.
- **`read_excel` / `read_csv` converters**: The `converters` argument now uses `Callable[[Any], Any]` instead of `Callable[[object], object]`. This change improves compatibility with `functools.partial` and lambda functions in both `pyright` and `mypy`.
- **`loc`**: When using an `Index` for column selection, use `IndexType` in overloads. `loc` now explicitly supports using an `Index` or `Series` as the second argument (column selector).
- **`from_records`**: Argument `columns` should be typed as `ListLike | None` (avoiding restrictive `SequenceNotStr[str]`). The `index` parameter should accept `Axes | None` (including `Index` and `Series`), not just `str` or sequences.
- **`where` return type**: `Series.where` (and `DataFrame.where`) return type is more flexible when `inplace=False` to handle cases where the `other` value changes the dtype (e.g., int to float).
- **`max`, `min`, `mean`, `median`**: When `axis=None`, these methods return a scalar (e.g., `float`, `int`, `Timestamp`) representing the global extremum or average across the entire DataFrame.
- **`loc` Overload Order**: `str` (and other `Hashable`) must be overloaded *before* `Iterable[Hashable]` for the column selector. This ensures that `df.loc[:, 'col']` correctly returns a `Series`, while `df.loc[:, ['col']]` returns a `DataFrame`.
- **`aggregate` and `agg` Alignment**: Ensure that both `aggregate` and `agg` have identical signatures and overloads, as they are aliases. Recent updates have synchronized their support for complex nested dictionary inputs and list-like aggregation functions.
- **`from_dataframe`**: Added typing for the Interchange Protocol `from_dataframe` method, which supports `allow_copy` and other protocol-specific arguments.
- **`boxplot`, `hist`, `pivot_table`**: These methods have been fully typed, including complex arguments like `aggfunc`, `dropna`, and various plotting parameters.

## Best Practices
- **Encapsulate Complexity**: Move complex indexer logic into private `_Indexer` classes.
- **Shared Base**: Use `NDFrame` as a generic base for shared `Series` and `DataFrame` methods, utilizing `Self`.
- **Granular Literals**: Use specific `Literal` types for `orient` in `to_dict` to provide precise return shapes (e.g., `dict[Hashable, dict]`).
- **Pivot Table Names**: Debate exists whether `pivot_table` (and others) should accept `Hashable` for `index/columns` to match `Series.name`, or stay restricted to `str` for better error catching. Current stubs often prefer `str` for column-like references.
- **Major Version Cleanup**: When a major version (3.0) removes methods like `swapaxes`, they should be removed from the stubs to match runtime behavior.
- **Top-level Function Updates**: Regularly check top-level functions like `concat` and `json_normalize` for signature changes that improve consistency or add support for new input types like `Series`.
