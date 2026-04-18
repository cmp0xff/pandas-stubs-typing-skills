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

## Best Practices
- **Encapsulate Complexity**: Move complex indexer logic into private `_Indexer` classes.
- **Shared Base**: Use `NDFrame` as a generic base for shared `Series` and `DataFrame` methods, utilizing `Self`.
- **Granular Literals**: Use specific `Literal` types for `orient` in `to_dict` to provide precise return shapes (e.g., `dict[Hashable, dict]`).
