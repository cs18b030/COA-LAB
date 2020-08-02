start:
#set mtvec properly
lui sp, 0x10011
la t0, trap_entry   #load t0 with temp_entry
ori t0, t0, 0       #0 for single point entry
csrw mtvec, t0      #set mtvec = t0->(trap_entry)

.p2align 0x2
#start program
_prog:
	#Some calculation
    mv a1, x0
	mv a2, x0
	addi a1, a2, 47  # a1=47

	#store address misalign
    mv a5, x0
	sw a1, 3(a5)
	# load address misalign
    mv a5, x0
	lw a1, 3(a5)
	# store access fault
	mv a5, x0
	sw a2, -4(a5)
	#load access fault
	mv a5, x0
	lw a2, -4(a5)
	#instruction access fault
	mv a5, x0
	jalr x0, -4(a5)

# finish program
_finish:
	ebreak
	j start  # jump to start
	

.p2align 2
trap_entry:
    addi sp, sp, -32*8
    #x0 is always 0
    sd x1, 1*8(sp)
    sd x2, 2*8(sp)
    sd x3, 3*8(sp)
    sd x4, 4*8(sp)
    sd x5, 5*8(sp)
    sd x6, 6*8(sp)
    sd x7, 7*8(sp)
    sd x8, 8*8(sp)
    sd x9, 9*8(sp)
    sd x10, 10*8(sp)
    sd x11, 11*8(sp)
    sd x12, 12*8(sp)
    sd x13, 13*8(sp)
    sd x14, 14*8(sp)
    sd x15, 15*8(sp)
    sd x16, 16*8(sp)
    sd x17, 17*8(sp)
    sd x18, 18*8(sp)
    sd x19, 19*8(sp)
    sd x20, 20*8(sp)
    sd x21, 21*8(sp)
    sd x22, 22*8(sp)
    sd x23, 23*8(sp)
    sd x24, 24*8(sp)
    sd x25, 25*8(sp)
    sd x26, 26*8(sp)
    sd x27, 27*8(sp)
    sd x28, 28*8(sp)
    sd x29, 29*8(sp)
    sd x30, 30*8(sp)
    sd x31, 31*8(sp)

    jal trap_handler

    ld x1, 1*8(sp)
    ld x2, 2*8(sp)
    ld x3, 3*8(sp)
    ld x4, 4*8(sp)
    ld x5, 5*8(sp)
    ld x6, 6*8(sp)
    ld x7, 7*8(sp)
    ld x8, 8*8(sp)
    ld x9, 9*8(sp)
    ld x10, 10*8(sp)
    ld x11, 11*8(sp)
    ld x12, 12*8(sp)
    ld x13, 13*8(sp)
    ld x14, 14*8(sp)
    ld x15, 15*8(sp)
    ld x16, 16*8(sp)
    ld x17, 17*8(sp)
    ld x18, 18*8(sp)
    ld x19, 19*8(sp)
    ld x20, 20*8(sp)
    ld x21, 21*8(sp)
    ld x22, 22*8(sp)
    ld x23, 23*8(sp)
    ld x24, 24*8(sp)
    ld x25, 25*8(sp)
    ld x26, 26*8(sp)
    ld x27, 27*8(sp)
    ld x28, 28*8(sp)
    ld x29, 29*8(sp)
    ld x30, 30*8(sp)
    ld x31, 31*8(sp)

    addi sp, sp, 32*8
    mret

trap_handler:
    # add to error count and restore the value
    la t0, _data
    lw t1, 4(t0) #2nd word in data section 
    addi t1, t1, 1
    sw t1, 4(t0)

    # store mepc and mcause in data memory
    # t0 has _data
    lw t0, 0(t0)
    csrr x15, mcause
	sw x15, 0(t0)
    csrr x15, mepc
	sw x15, 4(t0) 
    addi t0, t0, 8
    la t1, _data
    sw t0, 0(t1)

    #set mepc=mepc+4
    csrr x15, mepc
    addi x15, x15, 4
    csrw mepc, x15

    #set pointer for switch case:
    csrr a5, mcause
    mv a4, x0
	# case 1: instruction access fault
	addi a4, a4, 1
	beq a5, a4, _iaf
	# case 4: load address misalign
	addi a4, a4, 3
	beq a5, a4, _lam
	# case 5: load access fault
	addi a4, a4, 1
	beq a5, a4, _laf
	# case 6: store address misalign
	addi a4, a4, 1
	beq a5, a4, _sam
	# case 7: store access fault
	addi a4, a4, 1
	beq a5, a4, _saf

    ret


# instruction access fault
_iaf: #1
	la t0, _data
	lw t1, 12(t0)
	addi t1, t1, 1
	sw t1, 12(t0)
	la t0, _finish
	csrw mepc, t0
	ret

# load address misalign
_lam: #4
	la t0, _data
	lw t1, 24(t0)
	addi t1, t1, 1
	sw t1, 24(t0)
	ret

# load access fault
_laf: #5
	la t0, _data
	lw t1, 28(t0)
	addi t1, t1, 1
	sw t1, 28(t0)
	ret

# store address misalign
_sam: #6
	la t0, _data
	lw t1, 32(t0)
	addi t1, t1, 1
	sw t1, 32(t0)
	ret

# store access fault
_saf: #7
	la t0, _data
	lw t1, 36(t0)
	addi t1, t1, 1
	sw t1, 36(t0)
	ret

# data section
.section .data
.p2align 0x2
_data:
	.word	0x10013000 #start address from where mcause and mepc values stored
	.word	0		#total traps
	.word	0		#instruction address misalign = 0 at the end also
	.word	0		#instruction access fault = 1 at the end
	.word	0		#illegal instruction = 0 at the end also
	.word	0		#breakpoint = 0 at the end also
	.word	0		#load address misalign = 1 at the end
	.word 	0		#load access fault = 1 at the end
	.word	0		#store address misalign = 1 at the end
	.word 	0		#store access fault = 1 at the end