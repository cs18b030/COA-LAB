#define mtime  0x200bff8
#define mtimecmp 0x2004000

_start:
    # initialise all values to 0
    andi t0, t0, 0
    mv t1, x0
    andi t2, t2, 0
    mv t3, x0

    # reset mtip bit in mip register
    li t0, mtimecmp
    addi t1, t1, -1
    sw t1, 0(t0)    # put -1 in mtimecmp

    #setup sp
    lui sp, 0x10011

    # enable vectoe based interrupt handlng
    la t0, vector_trap_handler
    ori t0, t0, 1       # least significant bit is set to 1, rest of the address is vector_trap_entry
    csrw mtvec, t0
    
    # set MIE and MTIE bit to enable global interrupt and machine time interrupt respectively
    li t0, 8
    csrrs zero, mstatus, t0
    li t0, 128
    csrrs zero, mie, t0
    

    # create a delta value, should be high enough
   
    #t2 will have the delta value
    addi t2, t2, 999
    slli t2, t2, 50
    lui t2, 0x50000    

    li t3, mtimecmp # t3 has address of mtimecmp
    li t1, mtime    # t1 has address of mtime
    ld t0, 0(t1)    # t0 has mtime reg value
    add t0, t2, t0  #t0 = delta +mtime value
    sd t0, 0(t3)
    mv t0, x0
    sw t0, 4(t3)

here:
    j here  #infinite loop
     
.p2align 2
vector_trap_handler:
    j here #0
    nop
    j here #1
    nop
    j here #2
    nop
    j here #3
    nop
    j here #4
    nop
    j here #5
    nop
    j here #6
    nop
    j timer_interrupt
    nop
    j here #8
    nop
    j here #9
    nop
    j here #10
    nop

timer_interrupt:
    # increment counter by 1
    la t2, _data
    lw t3,4(t2)
    addi t3,t3, 1
    sw t3,4(t2)
    
    # store mcause value in data
    csrr t1, mcause
    lw t3, 0(t2)
    sw t1,0(t3)
    addi t3, t3, 0x4
    sw t3, 0(t2)

    #clearing the mtip bit
    li t6,mtimecmp
    li t1, -1
    sw t1,0(t6)

    #jump back
    j here

.section .data
.p2align 0x2
_data:
	.word  0x10012000 
	.word	0 #total number of times ttrap takes place