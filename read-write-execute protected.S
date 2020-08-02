/**
we will write two modules. The first module will run only in M mode, while the second 
can run in both M ans S modes. 
1.) Starting from M mode in module 1, we will first set mtvec, pmpaddr and pmpcfg appropriately.
2.) We will set page size as 2MiB(>10KiB).
3.) Then we will swith to module 2, and we can run the code in both S and M mode. Also, we will show 
    that running module 1 in S mode will raise an exception.
*/

start:
    # set sp and mtvec
    li      sp, 0x10011000
    la      t0, trap_entry
    csrw    mtvec, t0

    # set pmpaddr0 and pmpaddr1
    # module_1 <= addr < module_2 run with config0
    # module_2 <= addr < BIG Number run in config1
    la      t0, module_1
    srli    t0,t0,2
    csrw    pmpaddr0, t0
    la      t0, module_2
    srli    t0,t0,2
    csrw    pmpaddr1, t0
    # set pmpaddr2 to a big value to include the page table also
    li      t0, 0x11010000
    srli    t0,t0,2
    csrw    pmpaddr2, t0

module_1:
    # set pmpcfg0 and pmpcfg1 so that module 1 is R, W and E protected, while
    # module 2 is given all the permisions
    li      t0, 0xffffff
    csrrc   zero, pmpcfg0, t0
    li      t0, 0xf0800
    csrs    pmpcfg0, t0

    # set up the page sizes = 2 Mib (>10KiB)
    li      t0,0x10020000
    li      t1,0x4008401
    sd      t1,0(t0)
    li      t0,0x10021400
    li      t1,0x400004f
    sd      t1,0(t0)

    # jump to module 2 and switch priv from M->S
    li      t0, 0x1800
    csrrc   zero,mstatus, t0    # clear the 11th and 12th bit in mstatus
	li      t0, 0x0800
	csrs    mstatus, t0         # set mpp (previous mode) with supervisor mode
	la      t0, module_2        # set mepc value 
	csrw    mepc, t0
	mret                        # mode changed

.p2align 2
module_2:
    # current mode is S.
    # It can also be run in M mode if priv is not changed
    
    # enforce paging by setting up satp
    mv      t0, x0
    addi    t0,t0,8
    slli    t0,t0,60
    li      t1,0x10020000
    srli    t1,t1,12
    or      t0,t1,t0
    csrw    satp,t0

    # we will jump to module 1 in S mode and try to execute the code in module 1.
    # this should raise an exception and we should jump to trap entry
    # with mcause value = 1 (showing instruction access fault)
    j module_1
    nop

    back_to_module_2:
    # random instructions in module 2
    mv      a0, x0
    addi    a0, a0, 4
    mv      a0, x0
    addi    a0, a0, 4
    ebreak
    nop


.p2align
trap_entry:
    li      t0, 0x1800
    csrrc   zero,mstatus, t0    # clear the 11th and 12th bit in mstatus
	li      t0, 0x0800
	csrs    mstatus, t0
    # update mepc to jump back to module 2
	la      t0, back_to_module_2
	csrw    mepc , t0
    mret



