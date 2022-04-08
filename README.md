[prog2021arch.pdf](https://github.com/St3p99/apse-fss/files/7952523/prog2021arch.pdf)

# Architetture e Programmazione dei Sistemi di Elaborazione - Progetto a.a 2021/22


# Project description
Minimize a given function with Fish School Search Algorithm using hardware optimization techniques discussed during the lessons ( i.e. Loop unrolling, Loop vectorization, Cache blocking, ...).

## Fish School Search Algorithm
Fish School Search (FSS), proposed by Bastos Filho and Lima Neto in 2008 is, in its basic version,[1] an unimodal optimization algorithm inspired on the collective behavior of fish schools. The mechanisms of feeding and coordinated movement were used as inspiration to create the search operators. The core idea is to make the fishes “swim” toward the positive gradient in order to “eat” and “gain weight”. Collectively, the heavier fishes have more influence on the search process as a whole, what makes the barycenter of the fish school moves toward better places in the search space over the iterations.

## Hardware optimization used
In this project, we used different hardware optimization techniques with both SSE and AVX instructions in Assembler language.
In particular, we used:
- Loop vectorization: a SIMD technique to perform the same operation on multiple data points simultaneously.
- Loop unrolling: a loop transformation technique (ILP) to increase a program's speed by reducing or eliminating instructions that control the loop, such as pointer arithmetic and "end of loop" tests on each iteration. To eliminate this computational overhead, loops can be re-written as a repeated sequence of similar independent statements.
