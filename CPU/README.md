CPU Code
============

Repository structure
--------------------
*  `Common/`: the hash and mmap functions
*  `Struct/`: the data structures, including heap, CuckooMap, CM Sketch, Count Sketch and StreamSummary
*  `Single/`: the single-key sketching algorithms, including CMHeap, CountHeap, Elastic Sketch, SpaceSaving and Univmon 
*  `Multiple/`: the hardware and software versions of CocoSketch and USS
*  `HCBench.h`: the benchmark of heavy changes
*  `HHBench.h`: the benchmark of heavy hitters
*  `HHHBench.h`: the benchmark of 1-d hierarchical heavy hitters 
*  `HHH2Bench.h`: the benchmark of 2-d hierarchical heavy hitters

Requirements
-------
- cmake
- g++

How to run
-------
```bash
$ cmake .
$ make
$ ./CPU your-dataset
```
