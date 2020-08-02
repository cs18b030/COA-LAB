/**
1.) Initially the code will run in M mode. Here, we will set the 3 level page table with 
    appropriate ppn and identical mapping. We have a total of three pages:
        a.) Page-1: For having M code(inaccesible from S mode), m_trap entry and code for satp
        b.) Page-2: For the dummy process, infinite loop
        c.) Page-3: For the supervisor trap entry code and loading page 2.
2.) In page 1-> we set the all the pmp registers, all the PTEs, other registers like
    mtvec, stvec and medeleg. This part is R, W and X protected from S mode.
3.) We then jump to S mode and enable satp for paging. Then we move to page 2
4.) As this page is not loaded, it should raise a page fault and direct us to page-3(s_trap_handler). 
4.) We load the page there, and move back to page 2, and execute the dummy process.
*/

page_1:
    # set up sp, mtvec, stvec
    li     sp, 0x10012000
    la      t0, m_trap_entry
    csrw    mtvec, t0
    la      t0, page_3
    csrw    stvec, t0

    # set medeleg to enable trap delegation(page miss here) in S mode.
    andi    t0, t0, 0
    li      t0, 0xffff
    csrs    medeleg, t0

    ###########################  PAGING  ##########################
    # set up 3 level page table, the second page but not the first page.
    # root-1st level
    li      t0, 0x10020000
    li      t1, 0x4008401
    sd      t1, 0(t0)
    # 2nd level
    li      t0,0x10021400
    li      t1,0x4008801
    sd      t1,0(t0)
    #3rd level
    #ppn for 0x10010000
    li      t0, 0x10022080
    li      t1, 0x40040cf
    sd      t1,0(t0)
    # #ppn for 0x10011000----we dont set it up here
    # li      t0,0x10022088
    # li      t1,0x400444f
    # sd      t1,0(t0)
    #ppn for 0x10012000 
    li      t0, 0x10022090
    li      t1, 0x40048cf
    sd      t1,0(t0)
    #for enabling page 2 later(with dummy process code)
    li      t0, 0x10022110
    li      t1, 0x40088cf
    sd      t1,0(t0)

    ##################################################################

    # set up pmp registers to protect the M mode code from R, W and X.
    la      t0, page_1
    srli    t0,t0,2
    csrw    pmpaddr0, t0
    la      t0, m_trap_entry
    srli    t0,t0,2
    csrw    pmpaddr1, t0
    # set pmpaddr2 to a big value to include the page table also
    li      t0, 0x11010000
    srli    t0,t0,2
    csrw    pmpaddr2, t0
    # set the pmpcfg0 to disable W, R and X in M mode.
    li      t0, 0xffffff
    csrrc   zero, pmpcfg0, t0
    li      t0, 0xf0800
    csrs    pmpcfg0, t0

    # jump to supervisor code
    li      t0, 0x1800
    csrrc   zero,mstatus, t0    # clear the 11th and 12th bit in mstatus
	li      t0, 0x0800
	csrs    mstatus, t0         # set mpp (previous mode) with supervisor mode
	la      t0, supervisor     # set mepc value 
	csrw    mepc, t0
	mret                        

    m_trap_entry:
        # This exception was raised when S mode tried to accessed M code.
        # go back to label->continue
        la      t0, page_2
        csrw    mepc, t0
        mret

    supervisor:
        # set up satp to enable paging
        mv      t0, x0
        addi    t0,t0,8
        slli    t0,t0,60
        li      t1,0x10020000
        srli    t1,t1,12
        or      t0,t1,t0
        csrw    satp,t0

        # we show that M-mode code is R,W,X protected.
        # we try and execute the page_1 code again. This should raise an exception
        j       page_1
        nop

.p2align 12
# page-2-> It should create a page miss as this page is not set up currently.
# This page has a dummy process(infinite loop), which should run after page miss is handled.
page_2:
    j       page_2
    nop

.p2align 12
page_3:
    # set the second page
    #ppn for 0x10011000 
    li      t0,0x10022088
    li      t1,0x400444f
    sd      t1,0(t0)
    # check scause value
    sret


