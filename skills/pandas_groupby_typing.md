# Skill: Advanced Typing for Pandas-like GroupBy Objects

## Description
This skill covers the hierarchical typing structure for GroupBy objects, focusing on generic container tracking, specialized Series/DataFrame subclasses, and complex return type mapping for reductions and transformations.

## Patterns

### 1. Hierarchical Generic Structure
Use a base class that tracks the original container type (`NDFrameT`) and specialized subclasses for specific container behaviors.
- **Base**: `BaseGroupBy[NDFrameT]` (where `NDFrameT` is `Series` or `DataFrame`).
- **Specialized**:
  - `SeriesGroupBy(GroupBy[Series[S1]], Generic[S1, ByT])`: Tracks the Series dtype (`S1`) and grouping key (`ByT`).
  - `DataFrameGroupBy(GroupBy[DataFrame], Generic[ByT])`: Tracks the grouping key (`ByT`).

### 2. Result Type Continuity
Ensure methods that return a modified group (like `get_group`) return the original container type using the `NDFrameT` type variable.
- **Goal**: `df.groupby(...).get_group(...)` should return a `DataFrame`.

### 3. Reductions vs. Transformations
Distinguish between operations that reduce dimensionality (aggregate) and those that preserve it (transform).
- **Reductions**: Often return a `Series` or `DataFrame` with a different index but related data. Use overloads to handle cases where the inner data type changes (e.g., `mean` returning `float`).
- **Transformations**: Use overloads to match the input container's shape and type exactly.

### 4. Selection-Based Return Types
In `DataFrameGroupBy`, track whether columns have been selected (e.g., via `df.groupby(...)[['col']]`) using internal boolean literals or specialized subclasses.
- **Benefit**: `df.groupby(...).size()` returns a `Series`, while `df.groupby(...)['col'].mean()` return types vary.

### 5. String Kernel Typing
Use `Literal` unions (e.g., `ReductionKernelType`) to type string-based aggregations (`agg('sum')`).
- **Pattern**: 
  ```python
  @overload
  def aggregate(self, func: Literal["sum", "mean", ...]) -> NDFrameT: ...
  ```

### 6. GroupBy Specific Deprecations and Changes in 3.0
- **Keyword-Only Arguments**: Deprecated non-keyword arguments in `groupby()` except for `by` and `level`.
- **`sum`, `mean`, `median`, `prod`, `min`, `max`, `std`, `var`, `sem`**: Now accept a `skipna` parameter.
- **`NamedAgg`**: Now supports passing `*args` and `**kwargs` to the `aggfunc`.
- **`Rolling` and `Expanding`**: Added `first()`, `last()`, `nunique()`, and `pipe()` methods.
- **`ResamplerGroupBy`**: `interpolate()` should be excluded from this class (split from `Resampler`).
- **`pct_change()`**: Argument `limit` is deprecated and must be `None`.
- **`interpolate()`**: Prevented from being used on datetime-like objects within `groupby.resample` operations.

## Best Practices
- **Track the Key**: Use a `ByT` generic to track what was used for grouping (e.g., `Hashable`, `Sequence`, or `Index`).
- **Callable Overloads**: Provide detailed overloads for `apply` and `transform` to handle different lambda signatures (e.g., `Callable[[Series], Scalar]` vs `Callable[[Series], Series]`).
- **Internal Aliases**: Use private type variables like `_TT` for internal logic switching to keep the public API clean.
- **Consistency with NDFrame**: Ensure that arguments and deprecations in GroupBy methods are kept in sync with the corresponding methods in `Series` and `DataFrame`.
