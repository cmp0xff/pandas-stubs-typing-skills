# Skill: Advanced Typing Lessons from pandas-stubs PRs

## Description
This skill captures specialized workarounds and advanced patterns identified from historical PRs in the `pandas-stubs` repository, particularly for resolving variance issues and improving literal-based type safety.

## Lessons & Patterns

### 1. Resolving Contravariance in Callables
When using `Callable` in a `Mapping` (e.g., formatters), avoid unions in the key type if it causes variance rejection.
- **Problem**: `Mapping[str | int, Callable[[str | int], Any]]` might reject `dict[str, Callable[[str], Any]]` because the callable argument is contravariant.
- **Solution**: Split the mapping into a union of mappings with narrower key types.
- **Pattern**:
  ```python
  FormattersType: TypeAlias = (
      Mapping[str, Callable[..., Any]]
      | Mapping[int, Callable[..., Any]]
  )
  ```

### 2. Replacing Generic Strings with Literal Kernels
For methods like `agg`, `transform`, and `rolling`, replace `str` with a `Literal` union of valid pandas operation names (kernels).
- **Benefit**: Catch typos like `agg("summm")` at type-check time.
- **Pattern**: 
  ```python
  ReductionKernelType: TypeAlias = Literal["sum", "mean", "min", "max", ...]
  ```

### 3. Explicit Annotations for Dict Inference
Mypy and Pyright often infer `dict[object, object]` for complex dictionaries used in `agg`. Provide explicit annotations using centralized TypeAliases.
- **Pattern**: `agg_dict: dict[str, TransformReductionListType] = {"col": "sum"}`

### 4. Variance Issues with `NDFrame` Methods
Be careful with variance when return types or argument types involve generic parameters of `NDFrame`. Use `@overload` to bypass variance issues in complex methods like `to_latex` or `to_json`.

### 5. Managing Deprecations
Use specialized markers or comments (`# pyright: ignore`) when stubs need to maintain compatibility with multiple pandas versions or when transitioning between internal "NoDefault" markers.

### 6. Overload Order for `Any` and `Unknown`
Overload order is critical when dealing with `Series[Any]` or `Series[Unknown]`.
- **Problem**: When a generic type is used with `Any`, multiple overloads might apply, leading to ambiguous results.
- **Solution**: Carefully order overloads so that more specific types are checked first. Add tests that specifically use `Any` to verify which overload is selected.

### 7. No `# type: ignore` in Tests
Basic rule: Do not put `ignore` in tests unless specifically testing that the stubs should *not* accept something invalid.
- **Benefit**: Ensures that the stubs are robust and that we don't accidentally hide bugs in the type-checking logic.
- **Exceptions**: Only use when testing invalid input or when a confirmed bug in a specific type checker version must be documented.

### 8. Progressive Typing Philosophy
Move from a "Casting" approach to a "Progressive" approach for ambiguous operations.
- **Casting Approach (Old)**: Return `Never` for ambiguous operations (like `Series[Any] + Series[str]`) to force users to cast.
- **Progressive Approach (New)**: Infer the only valid resulting type if the operation is known to work at runtime (e.g., `Series[Any] - Series[Timestamp] -> Series[Timedelta]`).
- **Goal**: Improve user experience while maintaining type safety by providing the most likely correct type.

### 9. Handling Type Checker Discrepancies (`mypy` vs. `pyright`)
`mypy` and `pyright` can have different opinions on how to handle overloads with `Any`.
- **Issue**: `mypy` might return `Any` if multiple overloads are ambiguous due to `Any` being a subtype of everything. `pyright` might return `Unknown` or select the first matching overload differently.
- **Resolution**: Use `assert_type()` in tests to document and verify behavior for both type checkers. If they diverge, consider the "Progressive approach" to find a common ground.

### 10. Managing Major Version Transitions (pandas 3.0/3.1)
When pandas moves towards a major version (like 3.0), the stubs must balance between removing deprecated features and supporting the current stable release.
- **Strategy**: Don't deprecate too early if a feature is still valid in minor versions. For nightly fixes (aiming at 3.1), keep the stubs until the actual release confirms the removal.
- **Cleanup**: Once a major version arrives, clean up objects that produce warnings or have been removed in the `pandas.nightly` builds.
- **Documented Functions Only**: Only include functions in the stubs that are part of the documented public pandas API. Undocumented functions should be removed from the stubs to avoid encouraging their use.
- **Use of `@final`**: When methods in the pandas source are annotated with `@final`, they should also be annotated with `@final` in the stubs to signal that they cannot be overridden in user code.

### 11. Exception Hierarchy Changes
Be aware of changes in the exception hierarchy between pandas versions.
- **Example**: `IncompatibleFrequency` changed from subclassing `ValueError` to `TypeError` in pandas 3.0. This affects how users might catch errors and how joins behave (casting to object vs raising).

### 12. Refining Mapping Keys with Generic Hashables
When typing parameters that accept mappings (like `dtype` in `read_*` functions), use specialized hashable type variables to avoid issues with `Any`.
- **Problem**: `Mapping[Hashable, DtypeArg]` is often too broad or causes issues with specialized dictionaries.
- **Solution**: Use `HashableT0`, `HashableT1`, etc., to allow the type checker to track the specific key types more effectively.
- **Pattern**: `Mapping[HashableT0, DtypeArg]` instead of a generic `Mapping`.

### 13. Alternating Argument Patterns (The `set_option` Pattern)
For functions that accept an alternating sequence of arguments (e.g., `key1, val1, key2, val2`), use multiple overloads to provide type safety for common cases.
- **Pattern**:
  ```python
  @overload
  def set_option(pat0: str, val0: object) -> None: ...
  @overload
  def set_option(pat0: str, val0: object, pat1: str, val1: object) -> None: ...
  # Continue up to a reasonable limit (e.g., 5 pairs)
  ```
- **Fallback**: Include a final overload with `*args: Any` to handle cases beyond the explicit overloads.

### 14. Pyrefly Suppression Best Practices
`pyrefly` is used alongside `mypy` and `pyright`, but its suppressions should be handled surgically.
- **Rule**: Avoid `# pyrefly: ignore-errors` at the top of files unless the file has an overwhelming number of false positives (e.g., >20) that cannot be easily fixed.
- **Preference**: Use inline `# pyrefly: ignore[<code>]` for specific lines. Only use file-wide ignores for tests designed to check invalid usage (`TYPE_CHECKING_INVALID_USAGE`).
- **Debugging Tip**: If `pyrefly` fails to find a file or reports strange errors, check for naming conventions (e.g., trailing underscores in filenames like `test_numpy_.py` vs `test_numpy.py`).

### 15. Factoring Internal Type Aliases
To improve readability and remove redundancy in complex stubs, factor out common components of large unions into intermediate aliases.
- **Example**: Creating `ColumnValue` as an intermediate type for `IntoColumn`.
- **Note**: These internal aliases don't necessarily need to be public, but they help maintain the stubs.

### 16. Transition to `NoDefault`
Transition from the internal `NoDefaultDoNotUse` to the newly exposed `pandas.api.typing.NoDefault` where appropriate for 3.0+.
- **Pattern**: Replace `from pandas._libs.lib import NoDefaultDoNotUse` with `from pandas.api.typing import NoDefault`.

### 17. Use of `pandas.api.typing.aliases`
With pandas 3.0+, prefer importing public-facing type aliases from `pandas.api.typing` rather than the internal `pandas._typing` module.
- **Goal**: Align with pandas' goal of providing a stable public typing API.
- **Examples**: `IntervalClosedType`, `ListLike`, `ScalarIndexer`.

### 18. Mandatory `assert_type()` in Tests
Always use `assert_type()` in test files to verify that the stubs are returning the expected types, especially for complex overloads.
- **Note**: A PR is not complete without tests that explicitly check return types using `assert_type()`.

### 19. Version-Specific Warning Management (`pytest_warns_bounded`)
When managing warnings that vary by pandas version, ensure the bounds are correctly set.
- **Rule**: When moving to a new major version (e.g., 3.0), remove "expired" `pytest_warns_bounded` (where the upper bound is less than the current version).
- **Tip**: Lower bounds for 3.x specific warnings should be at least `3.0`.

### 20. Handling Optional Dependencies in Stubs
Some objects (like `ExcelWriter`) might appear as `Unknown` if optional runtime dependencies (like `xlsxwriter` or `odfpy`) are missing during type checking with strict mode.
- **Resolution**: Advise users to install these optional packages or handle the `Unknown` type if they use strict type checking.

### 21. Scalar Type Expansion
The `Scalar` type in `_typing.pyi` is being expanded to include `np.integer`, `np.floating`, and `np.complexfloating`. This prevents errors when passing numpy scalars to methods like `insert()` or `to_numpy(na_value=...)`.

### 22. Typing for `args` and `kwargs`
Use `*args: Any, **kwargs: Any` for undocumented parameters or those passed to third-party functions. For pandas functions with known optional parameters (like `pct_change` calling `shift`), replace `**kwargs` with the specific parameters to improve type safety.

### 23. Exporting in `__init__.pyi`
Stubs should align with pandas source exports by using the `from .module import xyz as xyz` pattern in `__init__.pyi` files. This ensures the symbols are visible to type checkers without requiring `if TYPE_CHECKING` blocks.
### 24. Adapting to NumPy Typing Changes
To avoid issues with future NumPy versions, prefer using `np.ndarray` instead of `np.ndarray[Any, Any]` in core typing aliases if the latter causes compatibility problems. However, for `npt.NDArray`, use `npt.NDArray[Any, Any]` to satisfy strict type checking.

### 25. Simple Defaults in Stubs
For default values of parameters in stubs, use the literal values of "simple" default values (e.g., `None`, `bool`, `int`, `float`, `str`). Use the ellipsis literal `...` only for more complex default values that cannot be easily expressed.

### 26. `Union` vs. Pipe Operator (`|`)
While the pipe operator `|` is preferred for clarity and modern syntax, `typing.Union` may be used in specific cases to maintain compatibility with external tools (like `ty`) until they fully support PEP 604 syntax in all contexts.

### 27. Preserving Types in `pd.concat`
Overloads for `pd.concat` should ensure that concatenating multiple `Series[T]` objects results in a `Series[T]` rather than a `Series[Any]`. This requires careful generic tracking in the `objs` argument.

### 28. Ambiguity of `Sequence[str]`
Avoid using `Sequence[str]` in overloads where it can be confused with a single `str` (which is itself a `Sequence[str]`). This is particularly relevant for indexers and column selectors where a single string returns a `Series` but a sequence of strings returns a `DataFrame`. Prefer `Index[str]` or more specific sequence types that do not overlap with `str` if possible.

### 29. Restrictive Comparison Typing
Comparison methods (`eq`, `ne`, etc.) should remain relatively restrictive in their parameter types to help users find bugs. While runtime pandas might allow comparing anything to a `Series`, catching common errors (like comparing a `Series` to an incompatible type) is one of the primary benefits of using stubs.

### 30. Shape Types for NumPy Array Return Types
When pandas functions return numpy arrays (e.g., `to_numpy`, `str.contains`), consider using shape-parameterized types like `npt.NDArray[Literal[1], np.bool_]` for 1D arrays or `npt.NDArray[Literal[2], np.float64]` for 2D arrays. This allows type checkers to better infer types in loops and improves IDE autocompletion.

### 31. "Future-Proof" Typing Philosophy
When a parameter's default behavior is deprecated (e.g., `include_groups=True` in `groupby.apply`), the stubs may omit the parameter entirely or restrict its values to the future-safe options (e.g., `Literal[False]`). This encourages users to write code that will not break in upcoming major versions (like Pandas 3.0), even if it causes immediate (but fixable) type errors in current versions.

### 32. Documenting "Breaking Typing Changes"
Improving stubs often results in stricter checking, which can be perceived as a "breaking change" by users with unpinned dependencies. Maintaining detailed release notes for every such change is a high burden for small teams; users should expect that any new `pandas-stubs` release may surface previously uncaught type issues in their codebase.

### 33. Removal of Specialized Series and Index Classes
Continue the transition from specialized internal classes (e.g., `TimestampSeries`, `TimedeltaSeries`, `PeriodSeries`, `OffsetSeries`, `IntervalSeries`) to generic parameterized classes (e.g., `Series[Timestamp]`, `Series[Period]`). This simplifies the stub architecture and makes the types more recognizable to users.

### 34. Use and Limitations of `@override`
Using `typing_extensions.override` (or `typing.override` for 3.12+) is encouraged for clarity when a method correctly overrides a parent. However, it may not remove the need for `# type: ignore[override]` if the child method's signature is intentionally different (e.g., narrowing) in a way that the type checker still flags as an incompatible override.

### 35. Maintenance of Tooling (`ty`)
The `ty` tool (used for validating stubs) can occasionally break CI due to changes in how it handles `UnionType`, `TypeVar` bounds, or `generic` types. When this happens, it may be necessary to pin `ty` versions or apply surgical workarounds in `_typing.pyi` until the tool is fixed.

### 36. Reconciliation of Core Properties
Ensure that core properties like `.index` return the same type across different objects (e.g., `Series.index` and `DataFrame.index` should both return `Index`). Inconsistencies in these basic properties can lead to confusing errors in downstream code that expects a uniform API.

### 37. Categorical Index Return Types
When creating a categorical index (e.g., `pd.Index(..., dtype="category")`), the stubs should return `CategoricalIndex` rather than a generic `Index[CategoricalDtype]`. This ensures that categorical-specific methods and attributes are available to the user.

## Best Practices
- **Centralize Aliases**: Move complex unions and literal lists to `_typing.pyi` or specialized `base.pyi` files within modules.
- **Literal Value Defaults**: Use literal values for "simple" defaults (e.g., `axis=0`, `inplace=False`, `None`) in stubs.
- **Version Check for Documented API**: Regularly check the pandas API documentation and remove stub entries for functions that have been removed or are internal-only.
- **Test Variance**: Add tests that specifically use specialized types (e.g., `dict[str, Callable]`) to ensure the stubs don't accidentally reject them due to variance.
...
- **Literal Dispatch**: Always prefer `Literal` over `str` when the set of valid strings is known and finite.
- **Consistent args/kwargs**: When in doubt, use `Any` for `args/kwargs`, but strive for specificity where the underlying call is known.
- **Explicit Exports**: Always use `as` in imports within `__init__.pyi` to explicitly mark them as exported.
- **Local CI Validation**: Always run `poetry run poe test_all` (which includes formatting) or `pre-commit run --all-files` locally before pushing. This ensures that the CI doesn't fail on basic linting/formatting issues.
- **Incremental PRs**: Break down large migrations (like pandas 3.0) into smaller, thematic PRs (e.g., "Deprecations Part 1", "Plotting Fixes") for easier review.
- **Avoid Nuclear Changes**: Prefer incremental additions (e.g., adding `| None` to specific method parameters) over broad changes to core aliases like `Scalar`, as the latter can have unpredictable effects across the codebase.
- **Standardize Deprecation naming**: Use `PD_LTE_30` (or similar) consistently in `tests/__init__.py` for version-based test filtering.

### 38. Numpy Version Compatibility
`pandas-stubs` version X.Y.Z.YYMMDD is designed to work with `pandas` X.Y.Z and the "current" `numpy` release on date MM/DD/YY. Using significantly older or newer `numpy` versions may cause incorrect type deduction (e.g., `Series[bool]` instead of `Series[float|str]`).

### 39. `to_datetime` and Numpy Arrays
`pd.to_datetime` should accept `npt.NDArray[np.float64]` and other numeric numpy arrays, as they are valid at runtime.

### 40. GroupBy Key Typing
Iteration over `df.groupby(['col'])` returns `Hashable` (or `tuple[Hashable, ...]`) for the group key. It is often impossible to narrow this type statically in a general way. Use `cast(int, key)` or similar if the specific type is known.

### 41. GroupBy agg/apply/transform Precision
GroupBy operations (`agg`, `apply`, `transform`) should be precise regarding `Callable` signatures and supported `str` literals (kernels). Kernels should be defined as `Literal` unions.

### 42. `ExcelWriter` and Strict Mode
In strict mode, `ExcelWriter` may require optional packages (e.g., `xlsxwriter`, `pyxlsb`, `odfpy`) for full type resolution. Without them, it may appear as `Unknown`.

### 43. `default` in `TypeVar` (Python 3.13+)
Use `default` in `TypeVar` declarations to provide a default type for generic classes. This improves ergonomics by allowing users to omit explicit brackets (e.g., `pd.Series` defaulting to `pd.Series[Any]`).
- **Pattern**: `S1 = TypeVar("S1", bound=SeriesDtype, default=Any)`

### 44. Asymmetric Assignment in Properties (Mypy 1.16+)
Mypy 1.16+ supports asymmetric assignment on properties, where the setter accepts a wider or different type than the getter returns.
- **Benefit**: Allows properties to be flexible in what they accept while remaining precise in what they return.

### 45. Private Import Management
Centralize imports from private modules (starting with `_`) to avoid `pyright` warnings about private import usage. For tests, move these to `tests/__init__.py`. Avoid exposing private imports in public-facing stubs.

### 46. `stubtest` for Alignment
Regularly run `stubtest` to ensure that stubs match the runtime implementation. This helps identify missing/extra methods, mismatched default values, and attribute discrepancies.
- **Handling Deprecations**: The project generally prefers *not* to include deprecated arguments in stubs to discourage their use, even if `stubtest` flags the mismatch with runtime.
- **Private Aliases**: Private `TypeAlias` (starting with `_`) may trigger `PYI047` (Private TypeAlias never used) if used across files but not within the declaring file. Use `# noqa: PYI047` to suppress this if the alias is intentional.

### 47. Aligning Module Names for IDE Support
Rename internal modules in stubs to match their runtime locations (e.g., renaming a `strings` module to `accessor.py` if that's where the runtime class lives).
- **Benefit**: Fixes IDE features like documentation hover and "Go to definition," as editors like VS Code/Pylance can correctly map the stub to the runtime source.

### 48. Semi-Automated Default Updates
When adding parameter defaults to replace `...`:
- **Simple Defaults**: Values like `None`, `int`, `float`, `bool`, or `str` literals are encouraged.
- **Complex Defaults**: Keep using `...` for complex runtime defaults that are hard to express statically.
- **Accuracy**: Prefer defaults found in function signatures over those found only in docstrings, as the latter can be outdated or inaccurate.

### 49. Negative Typing with `Never`
Use `Never` in overloads to explicitly reject invalid input combinations that might otherwise be caught by a broad signature.
- **Example**: In `to_dict`, use overloads returning `Never` to flag invalid argument combinations that would fail at runtime.
- **Goal**: Provide a form of "negative typing" that helps users catch logic errors early.

### 50. Parameterized Array Return Types (1D Arrays)
When returning numpy arrays from Series or Index methods (e.g., `to_numpy`, `str.contains`), specify the dimensionality if known.
- **Pattern**: Use `npt.NDArray[S1]` or similar to indicate a 1D array of the corresponding subtype. This is part of the shift towards more precise return types in the stubs.

### 51. Arithmetic Typing for `Series[Any]`
When a `Series[Any]` (often resulting from `df['col']`) is used in arithmetic with a specific type (like `Timestamp` or `str`), the stubs should ideally report an error. This forces the user to `cast` the `Series[Any]` to a specific type, preventing subtle runtime errors where the column might not actually contain the expected type.

### 52. `SupportsAdd` and `SupportsRAdd` Protocols
Use `_typeshed.SupportsAdd` and `SupportsRAdd` to simplify arithmetic overloads in `other` parameters. This can significantly reduce code duplication while maintaining broad compatibility for types that implement these standard protocols.

### 53. Pandas 3.0 Binary Operation Changes
Pandas 3.0 introduces stricter rules for binary operations. Specifically, multiplication between `bool` and `str`, or `bool` and `Timedelta`, is now disallowed. The stubs should reflect this by returning `Never` or causing a typing error to alert users of these breaking changes.

### 54. `__init__.pyi` and Mypy Visibility
For Mypy to correctly resolve types within a submodule, an `__init__.pyi` file must exist in every directory along the import path. If Pyright correctly identifies a type but Mypy reports it as `Any`, it is likely due to a missing `__init__.pyi` file in the package hierarchy.

### 55. Ruff "Ignore" Strategy for Code Quality
Transitioning Ruff configuration from a `select` to an `ignore` strategy surfaces more opportunities to improve code quality by flagging all non-compliant code. Complying with rules like `ANN201` (missing return type for public functions) ensures that test functions explicitly return `-> None`, which significantly reduces "unknown" errors in `pyright` strict mode.

### 56. `ElementOpsMixin` for Arithmetic DRY
Use internal mixins like `ElementOpsMixin` to consolidate arithmetic logic shared between `Index` and `Series`. This "Don't Repeat Yourself" (DRY) approach reduces maintenance overhead and ensures that bug fixes or improvements to arithmetic are applied consistently across both objects.

### 57. `Frequency` and `PeriodFrequency` Aliases
Use a centralized `Frequency` alias (e.g., `str | BaseOffset`) for most time-series operations. For `Period` objects specifically, use a more restrictive `PeriodFrequency` alias that only includes offsets valid for periods (e.g., `YearEnd`, `MonthEnd`, `Day`, `Hour`), helping users avoid invalid frequency combinations.

### 58. `Index.where` Flexibility
The `other` parameter in `Index.where` should be typed to accept both `Series` and `Index` (and scalar values), as runtime pandas allows these and aligns them by index/position where appropriate.

### 59. `ExtensionArray` Accumulations
`ExtensionArray` supports an internal `_accumulate` method for operations like `cumsum`, `cumprod`, `cummin`, and `cummax`. These should be typed to return the appropriate `ExtensionArray` type to support custom array implementations.

### 60. Dropping Specialized Series Subclasses
Continue the architectural cleanup by removing internal-only Series subclasses such as `IntervalSeries`, `PeriodSeries`, and `OffsetSeries`. These should be replaced by generic parameterized `Series[T]` (e.g., `Series[pd.Period]`), which is more idiomatic and reduces the complexity of the stub codebase.

### 61. Distinguishing _DataLike from ListLike
The internal _ListLike was often misused in places that didn't actually accept dict.
- **Solution**: Rename internal _ListLike to _DataLike if it includes dict. Use ListLike (which already includes Index and Series) for places that accept sequences but NOT dictionaries.

### 62. Avoiding Index[Timedelta]
Stubs should avoid overloads that create or assume Index[Timedelta], as it is usually seen as an Index with object dtype at runtime.
- **Recommendation**: Encourage users to use TimedeltaIndex instead. If a computation result must be object dtype, return Index or Index[Any].

### 63. Overload Order for Iterable vs. str
In methods like loc, str is technically an Iterable[Hashable]. However, df.loc[..., 'col'] returns a Series, while df.loc[..., ['col']] returns a DataFrame.
- **Pattern**: Place the str (or Hashable) overload before the Iterable overload to ensure correct return type inference.

### 64. Consistency with np_ndarray_xxx Aliases
When typing numpy array arguments or return values, prefer using the internal aliases from _typing.pyi (e.g., np_ndarray_bool, np_1darray_int) rather than npt.NDArray[...] for consistency across the stubs.

### 65. Prefer np.floating over np.double
In stubs, prefer using np.floating as a bound or element type instead of specific precisions like np.double or np.float64, unless the operation is strictly limited to that precision.

### 66. Explicit Defaults in Stubs
Prefer providing explicit literal default values in stubs (e.g., : bool = False, : Literal[True] = True, : None = None) instead of using the ellipsis : bool = .... This provides better information to IDEs and users.

### 67. Prefer Mapping over dict for Arguments
For method arguments (e.g., in __deepcopy__ or rename), prefer Mapping over dict to be more permissive and allow custom mapping implementations.

### 68. Redundancy in Iterable | Series
Since Series inherits from Iterable, specifying Iterable | Series in a union is redundant. Use just Iterable (or ListLike if appropriate).

### 69. MutableSequence for Covariance Issues
list is not covariant, which can cause issues in type checking when passing lists of subtypes. In some cases, using MutableSequence or Sequence can alleviate these issues.
### 70. Regex Escaping in `pytest_warns_bounded`
When using `pytest_warns_bounded` to check for deprecation warnings, ensure that any parentheses in the expected message (like `resample(...)`) are escaped in the regex (e.g., `resample\(...\)`). Truncating the message to its stable prefix is often a safer approach.

### 71. `pyright_strict` Progression and Explicit Type Arguments
When moving towards `pyright_strict`, avoid bare generic types like `list`, `dict`, `Callable`, `tuple`, `Sequence`, `Mapping`, `GroupBy`, or `np.dtype`. Always provide explicit type arguments, using `Any` if a more specific type cannot be determined (e.g., `list[Any]`, `dict[Any, Any]`, `Callable[..., Any]`, `np.dtype[Any]`).

### 72. Explicit `Any` for `np.dtype` on Python 3.10
For Python 3.10 with older numpy, `np.dtype` requires an explicit `Any` argument (e.g., `np.dtype[Any]`) because its `TypeVar` does not have a default value in those environments.

### 73. Removal of Static-Typing-Irrelevant Mixins
Remove undocumented internal mixins and base classes (e.g., `SelectionMixin`, `ExtensionScalarOpsMixin`, `ExtensionOpsMixin`) that are used in the runtime as implementation details but do not provide useful information for static typing. This simplifies the stub hierarchy and avoids encouraging the use of internal-only APIs.

### 74. Version-Specific Behavior with `PD_LTE_23`
In tests, use version-based conditional checks (e.g., `if PD_LTE_23:`) to handle behavioral differences or bugs that have been fixed in newer pandas versions (like 3.0), ensuring tests pass across all supported pandas versions.

### 75. Consistent NumPy Aliases in Tests
For consistency and readability in tests, prefer using internal NumPy array aliases (e.g., `np_ndarray_intp`, `np_ndarray_int64`, `np_ndarray_float`) when performing type assertions with `assert_type()`.

### 76. Generic Support for `ExcelWriter`
`ExcelWriter` should be typed with generic support and overloads to handle different engine types and their specific behaviors correctly.

### 77. Numpy 2.4.0 `double` Change and Overload Order
In numpy 2.4.0, `double` changed from an abstract type alias to a concrete class reference (`float64`).
- **Issue**: The generic `dtype: type[S1]` overload might match `np.double` before more specific overloads like `dtype: FloatDtypeArg`.
- **Solution**: Reorder overloads so that specific `DtypeArg` (like `FloatDtypeArg`) are checked before generic `type[S1]`.

### 78. `NumpyExtensionArray` Rename (Pandas 3.0)
`PandasArray` has been renamed to `NumpyExtensionArray` in pandas-dev/pandas#53694.
- **Action**: Stubs should use `NumpyExtensionArray` to align with the runtime. It is produced when no other Pandas array applies or when a Python-native/numpy dtype is imposed (non-datetime).

### 79. Handling `np.nan` in Integer/Boolean Arrays
Supporting `np.nan` in integer or boolean arrays in stubs is challenging because `Literal[np.nan]` is not possible.
- **Trade-off**: Adding `float` to the argument list might make it impossible to differentiate from overloads that produce `FloatingArray`. In such cases, it might be better not to support `np.nan` explicitly if it causes ambiguity.

### 80. `ASTYPE_x_ARGS` Division for Precision
Dividing a broad `ASTYPE_ARGS` into more specific categories (e.g., `ASTYPE_FLOAT_ARGS`, `ASTYPE_BYTES_ARGS`) improves precision.
- **Benefit**: Allows for more targeted testing and better type safety across `ExtensionArray`, `Index`, and `Series`.

### 81. Replacement for `ensure_clean` in Tests
`ensure_clean` was removed from `pandas._testing` in pandas-dev/pandas#63487.
- **Pattern**: Replace `with ensure_clean() as path:` with `path = str(tmp_path / str(uuid.uuid4()))`.

### 82. Generic `pd.StringDtype` and `ArrowStringArray`
To support different string storage backends (Python vs. Arrow), `pd.StringDtype` was made generic.
- **Pattern**: `pd.array([np.nan], "string")` may result in `BaseStringArray`, `StringArray`, or `ArrowStringArray` depending on the storage and whether `pyarrow` is installed.

### 83. Generic `np_ndarray_xxx` with Shape Type Variable
Exposing the shape type variable in internal numpy aliases (e.g., `np_ndarray_int64`) simplifies stubs.
- **Benefit**: Allows for more precise shape tracking and reduces redundancy in stub definitions.

### 84. `xs` Method Restriction
In `DataFrame.xs` and `Series.xs`, the `key` parameter can no longer be a `list` (propagated from pandas#41789).
- **Rule**: Update stubs to restrict `key` to non-list types where applicable.

### 85. Strategy for `reportPrivateUsage`
To enable `reportPrivateUsage` while keeping symbols "private" from users:
- **Solution**: Move types used only for typing into private stub files (e.g., `_typing.pyi` or modules starting with `_`), but name the symbols themselves *without* leading underscores (e.g., `Dtype_` instead of `_Dtype`).
- **Rationale**: Pyright doesn't complain about importing from a private *module*, only about importing private *symbols*.

### 86. Pandas 3.0 String Array Behavior
`pd.array([], str)` behavior changed in 3.0:
- **Pre-3.0**: Returns `NumpyExtensionArray`.
- **3.0+**: Returns `BaseStringArray`.
- **NA Value**: In 3.0, the `na_value` for this is `float("nan")` instead of `pd.NA`.

### 87. Type Completeness Check in CI
Using Pyright's type completeness check (`pyright --verifytypes`) ensures that all publicly exported symbols have known types.
- **Goal**: Different from type correctness; it ensures there are no "Unknown" types in the public API surface.

### 88. `TimeAmbiguous` and `bool`
The `ambiguous` parameter in time-related functions supports a single `bool` as well as an array of bools.
- **Action**: Update `TimeAmbiguous` alias to include `bool`.

### 89. Broader Iterables in `MultiIndex.from_product`
`MultiIndex.from_product` accepts broader iterables than just sequences (e.g., sets).
- **Action**: Change `iterables` parameter type to `Sequence[Iterable[Hashable]]`.

### 90. `Timedelta` and `Tick` Objects
The `Timedelta` constructor accepts `Tick` objects (like `Minute`, `Hour`, `Day`).
- **Action**: Update `Timedelta` stubs to include `Tick` in the accepted types for the first argument.

### 91. Dropping Python 3.10 and `pytest_warns_bounded` Cleanup
Pandas 3.0 drops support for Python 3.10 and matures many deprecations.
- **Action**: Drop Python 3.10 from test matrices.
- **Cleanup**: Remove "expired" `pytest_warns_bounded` (where the upper bound is < 3.0). Update version-based test guards (e.g., `PD_LTE_23` -> `PD_LTE_30`).

### 92. Inequality Comparison of `NaT` and `datetime.date`
In pandas 3.0+, comparing `NaT` with `datetime.date` using inequality operators (`<`, `<=`, `>`, `>=`) raises an error. The stubs should reflect this by using `Never` or appropriate overloads that do not include these comparisons.

### 93. `iloc` and Boolean Masks
`iloc` now officially supports boolean masks for indexing, matching the behavior of `loc` and `[]`. Ensure that `iloc.__getitem__` and `iloc.__setitem__` overloads include boolean-like arrays/Series.

### 94. `set_option` with Dictionary
`set_option` now accepts a single dictionary of options (e.g., `pd.set_option({"display.max_rows": 10, "display.max_columns": 5})`). Update the stubs with an overload for `dict[str, Any]`.

### 95. Multiple `set_option` Arguments
To support the pattern `pd.set_option(pat1, val1, pat2, val2, ...)`, provide explicit overloads for up to 5 pairs of arguments. This provides better type safety than a single `*args: Any` signature.

### 96. Deprecation of `Timestamp.utcfromtimestamp` and `utcnow`
These methods are deprecated in favor of `Timestamp.fromtimestamp(ts, "UTC")` and `Timestamp.now("UTC")`. Stubs should mark them as deprecated or remove them if targeting pandas 3.0+.

### 97. Keyword-only Arguments in `groupby`
In pandas 3.0+, all arguments to `groupby` except `by` and `level` must be passed as keywords. Update the stub signature to use the `*` separator.

### 98. `Index.get_loc` and Tuple Subclasses
`Index.get_loc` now accepts subclasses of `tuple` as keys. Ensure the `key` parameter is broad enough to include `tuple` and its variants.

### 99. `read_*(dtype)` as `Mapping[Hashable, DtypeArg]`
When typing the `dtype` parameter in I/O functions (like `read_csv`, `read_parquet`), use `Mapping[Hashable, DtypeArg]` instead of `defaultdict`. While `defaultdict` works, it is a subset of the required `Mapping` interface.

### 100. `Series.where` and `mask` allowing `None`
The `other` parameter in `Series.where` and `Series.mask` now explicitly supports `None`. Ensure the type hint is `Scalar | None` (or similar) to avoid unnecessary `type: ignore`.

### 101. `pd.col` Typing
Support for `pd.col` (likely for expressions) should be added to the stubs to unblock users of newer pandas expression APIs.

### 102. `to_offset` and `datetime.timedelta`
`pd.tseries.frequencies.to_offset` now accepts `datetime.timedelta` objects in addition to strings and offsets.

### 103. `concat` and Subclasses
When concatenating objects that are subclasses of `DataFrame` or `Series`, the stubs should ideally preserve the subclass type if all inputs share the same subclass. This may require complex generic overloads.

### 104. `tseries.api.guess_datetime_format` Public API
`guess_datetime_format` has been promoted to the public API in `pandas.tseries.api`. Ensure it is exported and correctly typed.

### 105. `pivot_table` and `aggfunc` `**kwargs`
`pivot_table` (and `DataFrame.pivot_table`) now allows passing `**kwargs` that are forwarded to the `aggfunc`. Update the signature to include `**kwargs: Any`.

### 106. `Series.map` and `engine`
`Series.map` now accepts an `engine` parameter (e.g., `Literal["python", "numba"]`) to specify the execution engine.

### 107. `json_normalize` and `Series` with `Index`
`json_normalize` now supports `Series` input while retaining the original `Index`. Update the input type from `list[dict]` to include `Series`.

### 108. `IncompatibleFrequency` as `TypeError`
In pandas 3.0, `IncompatibleFrequency` (in `pandas.errors`) subclasses `TypeError` instead of `ValueError`. This affects how users catch it and how it behaves in joins.

### 109. Removal of `mode.use_inf_as_na` and `swapaxes`
These options and methods have been removed in pandas 3.0. Stubs should remove them to prevent users from using deprecated/removed APIs.

### 110. The Overload-Overlap Trap with Subclasses
When adding an overload returning `Never` for a specific type (e.g., `datetime.date`), mypy will flag an `overload-overlap` if a previous overload accepts a subclass (e.g., `datetime.datetime`) and returns a different type.
- **Problem**: Mypy sees that the subclass (`datetime`) *also* matches the base class (`date`) overload, and if the return types differ (`bool` vs `Never`), it reports an error.
- **Solution**: Apply `type: ignore[overload-overlap]` precisely to the overlapping `@overload` decorator.
- **Note**: The placement of the ignore is critical; putting it on the `def` statement may not satisfy mypy in all versions.

### 111. The Reachability Trap with `Never`
Using `assert_type(x, Never)` in tests causes mypy to identify subsequent code in the same block as unreachable.
- **Problem**: `Statement is unreachable [unreachable]` errors in existing test suites when adding new `Never` restrictions.
- **Solution**: Use `if TYPE_CHECKING:` blocks and ensure the `Never` assertion is the last statement in its block, or use `Any` casting to "break" the `Never` propagation if you must continue execution in the same test function.

### 112. Prefer Standard `TYPE_CHECKING` for Tests
Avoid relying on `pd.api.typing.TYPE_CHECKING` in tests for guarding type-checker-only code.
- **Problem**: The pandas stubs may not always export `TYPE_CHECKING` in a way that satisfies all type checkers in all contexts, leading to `attr-defined` errors.
- **Solution**: Always import `TYPE_CHECKING` from the standard `typing` module.

## Best Practices
