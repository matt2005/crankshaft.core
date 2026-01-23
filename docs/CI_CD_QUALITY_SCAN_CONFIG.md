# CI/CD Quality Scan - Configuration Reference

## Quick Start

### For GitHub Actions
The optimised workflow is already enabled. No action required on next commit.

### For Local Development

**First time setup:**
```bash
# Install build tools
./.github/scripts/install-dev-tools.sh

# Enable ccache (optional but recommended)
export PATH="/usr/lib/ccache:$PATH"
```

**Run quality checks:**
```bash
# Quick check (recommended for PRs)
./scripts/quality-check.sh

# Full check with all options
./scripts/quality-check.sh 8  # 8 parallel jobs
```

## Configuration Options

### CMake Build Options

```bash
# For optimised quality scans
cmake -B build -GNinja \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SLIM_UI=ON \
  -DENABLE_UI=OFF \
  -DCMAKE_C_COMPILER_LAUNCHER=ccache \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
  ..
```

| Option | Value | Purpose |
|--------|-------|---------|
| `CMAKE_BUILD_TYPE` | Release | Faster compilation |
| `ENABLE_SLIM_UI` | ON | Lightweight UI only |
| `ENABLE_UI` | OFF | Skip full UI build |
| `CMAKE_C_COMPILER_LAUNCHER` | ccache | Cache compiler results |
| `CMAKE_CXX_COMPILER_LAUNCHER` | ccache | Cache compiler results |
| `CMAKE_GENERATOR` | Ninja | Faster than Unix Makefiles |

### Environment Variables

```bash
# Number of parallel clang-tidy jobs (default: nproc)
export CLANG_TIDY_JOBS=4

# ccache configuration
export CCACHE_MAXSIZE=500M      # Cache size limit
export CCACHE_COMPRESS=1        # Enable compression
export CCACHE_BASEDIR=$PWD      # Base directory for path normalisation

# Build system
export CMAKE_BUILD_PARALLEL_LEVEL=4  # Parallel build jobs
```

## Performance Tuning

### Slow Build?

1. **Check ccache status:**
   ```bash
   ccache --show-stats
   ```

2. **Clear and rebuild:**
   ```bash
   rm -rf build ~/.cache/ccache
   cmake -B build -GNinja ... && ninja -C build
   ```

3. **Verify Ninja is used:**
   ```bash
   cat build/CMakeCache.txt | grep CMAKE_GENERATOR
   ```

### Slow clang-tidy?

1. **Check job parallelism:**
   ```bash
   export CLANG_TIDY_JOBS=8  # Increase jobs
   ./scripts/quality-check.sh
   ```

2. **Skip specific files:**
   ```bash
   # Edit .github/scripts/quality/check-tidy.sh
   # Add to SKIP_PATTERNS array:
   # "path/to/slow_file.cpp"
   ```

3. **Reduce checks:**
   ```bash
   # Review .clang-tidy configuration
   # Can further reduce check set if needed
   ```

## Workflow File Structure

**File:** `.github/workflows/quality-scan.yml`

```yaml
# Job configuration
- name: Build project for SAST (slim UI only, Release mode)
  run: |
    cmake -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_UI=OFF \
      -DENABLE_SLIM_UI=ON \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache \
      ..

# Cache configuration
cache:
  path: |
    build/
    ~/.cache/ccache
  key: quality-scan-${{ runner.os }}-${{ hashFiles('CMakeLists.txt', ...) }}
```

## Integration with IDE

### VS Code

Add to `.vscode/tasks.json`:
```json
{
  "label": "Quality Check (Optimised)",
  "type": "shell",
  "command": "${workspaceFolder}/scripts/quality-check.sh",
  "group": {
    "kind": "test",
    "isDefault": false
  },
  "presentation": {
    "reveal": "always",
    "panel": "new"
  }
}
```

Then run: <kbd>Ctrl+Shift+D</kbd> → Select "Quality Check (Optimised)"

### CLion / IntelliJ

1. **Settings → Tools → CMake**
2. Set CMake options:
   ```
   -GNinja -DCMAKE_BUILD_TYPE=Release -DENABLE_SLIM_UI=ON
   ```
3. Set environment variables:
   ```
   CMAKE_C_COMPILER_LAUNCHER=ccache;CMAKE_CXX_COMPILER_LAUNCHER=ccache
   ```

## Monitoring & Debugging

### Check Workflow Progress

1. Push code to trigger workflow
2. Go to **Actions** tab in GitHub
3. Click "Quality Scan" workflow
4. View real-time logs

### View Specific Step Logs

Click on any step to see detailed output and timing.

### Cache Hit Rate

Look for cache step output:
- ✅ Cache hit: Previous artifacts reused
- ⚠️ Partial cache miss: Some files rebuilt
- ❌ Cache miss: Full rebuild needed

## Troubleshooting

### Workflow Times Out

**Problem:** Workflow exceeds 6-hour limit

**Solutions:**
1. Increase job parallelism in CMake:
   ```cmake
   set(CMAKE_BUILD_PARALLEL_LEVEL 8)
   ```
2. Skip less critical checks temporarily
3. Split across multiple jobs (advanced)

### clang-tidy Out of Memory

**Problem:** Process killed by OOM

**Solutions:**
1. Reduce parallel jobs:
   ```bash
   export CLANG_TIDY_JOBS=2
   ```
2. Increase runner memory requirements
3. Split analysis across jobs

### Cache Size Exceeded

**Problem:** ccache size grows too large

**Solutions:**
1. Clear cache:
   ```bash
   ccache --clear
   ```
2. Reduce max size:
   ```bash
   export CCACHE_MAXSIZE=250M
   ```
3. Enable compression:
   ```bash
   export CCACHE_COMPRESS=1
   ```

## Advanced Usage

### Run Only Specific Checks

```bash
# Format only
./.github/scripts/quality/check-format.sh

# CPP Check only
./.github/scripts/quality/check-cppcheck.sh

# Clang-tidy only
./.github/scripts/quality/check-tidy.sh --parallel
```

### Custom clang-tidy Configuration

Edit `.clang-tidy`:
```yaml
Checks: >
  -abseil-*,
  -altera-*,
  bugprone-*,
  performance-*
```

### Incremental Builds

For faster iterative development:
```bash
# First build
cmake -B build -GNinja ...
ninja -C build

# Subsequent builds (incremental)
ninja -C build  # Only rebuilds changed files
```

## Performance Benchmarks

### Typical Times

| Scenario | Time | Notes |
|----------|------|-------|
| Cold build | 8-12 min | First time, no cache |
| Warm build | 2-3 min | Cache hit, incremental |
| Quality scan | 15 min | Full analysis |
| Format check | 1 min | clang-format only |
| CPP check | 3 min | cppcheck only |

### Optimisation Checklist

- [ ] Using Ninja generator? (`-GNinja`)
- [ ] Release build type? (`-DCMAKE_BUILD_TYPE=Release`)
- [ ] Slim UI enabled? (`-DENABLE_SLIM_UI=ON`)
- [ ] ccache enabled? (`CMAKE_C_COMPILER_LAUNCHER=ccache`)
- [ ] Parallel jobs configured? (`CLANG_TIDY_JOBS=4+`)
- [ ] Cache is warm? (Check GitHub Actions)

## References

- [CMake Performance](https://cmake.org/cmake/help/latest/manual/cmake-tools.md)
- [Ninja Build System](https://ninja-build.org/)
- [ccache Documentation](https://ccache.dev/)
- [clang-tidy Configuration](https://clang.llvm.org/extra/clang-tidy/)

---

**Last Updated:** January 2025  
**Version:** 1.0  
**Status:** Production Ready
