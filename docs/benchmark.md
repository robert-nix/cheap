## Vector pool benchmark

This benchmark is *not* representative of the pretty part of this libraryl it
only shows the difference between storing floating point vectors in Typed Arrays
and storing them in JavaScript objects.

The vector pool is initialized with ~10% null values, ~90% random vectors.

### Memory size (per vector)

[This test](/test/memory_size.coffee) is performed by allocating large vectors
with both typed arrays and plain objects and simply measuring process memory
usage changes.

engine | objects | typed array
--- | --- | ---
v8 64-bit | ~136 bytes | ~16 bytes

### Chrome 39 (32-bit v8 on Desktop x86)

Pool Size | 1e3 | 1e5 | 1e6
--- | --- | --- | ---
VectorPool init | 17,816 ops/sec<br>±0.48% | 199 ops/sec<br>±0.29% | 16.51 ops/sec<br>±15.95%
plain init | 26,418 ops/sec<br>±0.35% | 62.35 ops/sec<br>±0.43% | 1.42 ops/sec<br>±17.66%
VectorPool seq read | 65,974 ops/sec<br>±1.16% | 506 ops/sec<br>±3.80% | 53.29 ops/sec<br>±5.13%
plain seq read | 73,240 ops/sec<br>±0.38% | 683 ops/sec<br>±0.40% | 67.55 ops/sec<br>±0.48%
VectorPool rand read | 41,398 ops/sec<br>±0.35% | 321 ops/sec<br>±0.54% | 12.35 ops/sec<br>±1.27%
plain rand read | 42,830 ops/sec<br>±0.35% | 164 ops/sec<br>±1.32% | 7.40 ops/sec<br>±0.86%
VectorPool seq write | 50,397 ops/sec<br>±0.59% | 474 ops/sec<br>±0.69% | 46.82 ops/sec<br>±1.25%
plain seq write | 72,044 ops/sec<br>±0.21% | 683 ops/sec<br>±0.28% | 66.17 ops/sec<br>±0.23%
VectorPool rand write | 32,340 ops/sec<br>±0.23% | 258 ops/sec<br>±0.58% | 10.01 ops/sec<br>±1.86%
plain rand write | 40,943 ops/sec<br>±0.42% | 74.23 ops/sec<br>±0.92% | 3.88 ops/sec<br>±1.27%
VectorPool lifetime sim | 158,992 ops/sec<br>±0.39% | 1,120 ops/sec<br>±1.64% | 62.71 ops/sec<br>±0.96%
plain lifetime sim | 28,959 ops/sec<br>±0.94% | 4.37 ops/sec<br>±1.92% | 0.04 ops/sec<br>±3.72%

### node v0.10 (64-bit v8 on Desktop x86)

Pool Size | 1e3 | 1e5 | 1e6
--- | --- | --- | ---
VectorPool init | 8,596 ops/sec<br>±8.73% | 167 ops/sec<br>±10.83% | 17.77 ops/sec<br>±12.32%
plain init | 28,468 ops/sec<br>±3.03% | 242 ops/sec<br>±0.39% | 3.08 ops/sec<br>±1.24%
VectorPool seq read | 34,499 ops/sec<br>±1.38% | 333 ops/sec<br>±2.00% | 32.91 ops/sec<br>±2.23%
plain seq read | 77,868 ops/sec<br>±1.25% | 681 ops/sec<br>±1.45% | 66.35 ops/sec<br>±2.00%
VectorPool rand read | 27,868 ops/sec<br>±1.74% | 185 ops/sec<br>±1.93% | 9.38 ops/sec<br>±1.31%
plain rand read | 46,105 ops/sec<br>±1.30% | 81.10 ops/sec<br>±6.29% | 4.20 ops/sec<br>±13.95%
VectorPool seq write | 19,291 ops/sec<br>±2.83% | 199 ops/sec<br>±3.38% | 21.21 ops/sec<br>±2.16%
plain seq write | 56,443 ops/sec<br>±2.12% | 429 ops/sec<br>±2.83% | 18.07 ops/sec<br>±10.57%
VectorPool rand write | 20,845 ops/sec<br>±1.74% | 151 ops/sec<br>±3.47% | 6.15 ops/sec<br>±3.33%
plain rand write | 33,282 ops/sec<br>±2.23% | 38.90 ops/sec<br>±7.93% | 2.99 ops/sec<br>±13.71%
VectorPool lifetime sim | 146,955 ops/sec<br>±1.96% | 853 ops/sec<br>±11.23% | 48.50 ops/sec<br>±0.97%
plain lifetime sim | 29,701 ops/sec<br>±1.51% | 4.40 ops/sec<br>±2.83% | 0.04 ops/sec<br>±3.40%

### Firefox 34 (32-bit SpiderMonkey on Desktop x86)

Pool Size | 1e3 | 1e5 | 1e6
--- | --- | --- | ---
VectorPool init | 5,854 ops/sec<br>±7.52% | 68.36 ops/sec<br>±8.07% | 7.24 ops/sec<br>±8.71%
plain init | 7,015 ops/sec<br>±2.76% | 58.63 ops/sec<br>±6.77% | 6.37 ops/sec<br>±9.24%
VectorPool seq read | 33,754 ops/sec<br>±1.37% | 367 ops/sec<br>±1.08% | 36.08 ops/sec<br>±2.14%
plain seq read | 164,147 ops/sec<br>±3.65% | 1,524 ops/sec<br>±7.74% | 144 ops/sec<br>±2.12%
VectorPool rand read | 13,014 ops/sec<br>±2.65% | 80.25 ops/sec<br>±2.87% | 6.35 ops/sec<br>±5.41%
plain rand read | 22,241 ops/sec<br>±2.13% | 62.27 ops/sec<br>±7.23% | 5.11 ops/sec<br>±1.19%
VectorPool seq write | 22,891 ops/sec<br>±3.23% | 215 ops/sec<br>±4.14% | 25.09 ops/sec<br>±4.17%
plain seq write | 153,349 ops/sec<br>±1.52% | 1,574 ops/sec<br>±1.07% | 131 ops/sec<br>±0.99%
VectorPool rand write | 13,738 ops/sec<br>±1.53% | 113 ops/sec<br>±1.95% | 6.10 ops/sec<br>±2.42%
plain rand write | 22,709 ops/sec<br>±1.88% | 78.02 ops/sec<br>±2.22% | 5.03 ops/sec<br>±2.02%
VectorPool lifetime sim | 52,516 ops/sec<br>±3.82% | 453 ops/sec<br>±1.88% | 31.46 ops/sec<br>±0.96%
plain lifetime sim | 30,782 ops/sec<br>±3.62% | 229 ops/sec<br>±5.84% | 15.21 ops/sec<br>±13.55%

### Chrome for Android (v8 on Nexus 4 ARMv7)

Pool Size | 1e3 | 1e5 | 1e6
--- | --- | --- | ---
VectorPool init | 2,311 ops/sec<br>±2.98% | 25.42 ops/sec<br>±2.59% | 2.12 ops/sec<br>±58.52%
plain init | 4,744 ops/sec<br>±1.68% | 8.22 ops/sec<br>±16.79% | 0.23 ops/sec<br>±61.33%
VectorPool seq read | 6,886 ops/sec<br>±1.09% | 69.31 ops/sec<br>±0.78% | 6.38 ops/sec<br>±0.93%
plain seq read | 9,568 ops/sec<br>±1.06% | 59.75 ops/sec<br>±0.50% | 5.97 ops/sec<br>±2.25%
VectorPool rand read | 4,543 ops/sec<br>±0.37% | 29.34 ops/sec<br>±3.47% | 2.36 ops/sec<br>±2.06%
plain rand read | 4,592 ops/sec<br>±1.42% | 14.43 ops/sec<br>±1.26% | 1.31 ops/sec<br>±0.93%
VectorPool seq write | 5,788 ops/sec<br>±0.34% | 55.90 ops/sec<br>±1.34% | 5.49 ops/sec<br>±3.96%
plain seq write | 9,469 ops/sec<br>±2.85% | 57.71 ops/sec<br>±2.51% | 5.74 ops/sec<br>±0.24%
VectorPool rand write | 3,634 ops/sec<br>±1.84% | 25.21 ops/sec<br>±0.86% | 1.96 ops/sec<br>±1.50%
plain rand write | 4,577 ops/sec<br>±1.96% | 14.90 ops/sec<br>±3.09% | 1.30 ops/sec<br>±2.01%
VectorPool lifetime sim | 26,171 ops/sec<br>±1.59% | 186 ops/sec<br>±2.18% | 13.92 ops/sec<br>±0.55%
plain lifetime sim | 4,032 ops/sec<br>±1.79% | 1.42 ops/sec<br>±5.31% | 0.01 ops/sec<br>±1.12%
