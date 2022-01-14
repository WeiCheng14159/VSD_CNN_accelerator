.section .text
.align 2
.globl dma_set
dma_set:
    li  a5, 0x40000000 # dma_addr
    sw  a1, 0x0(a5)    # source
    sw  a2, 0x4(a5)    # destination
    sw  a0, 0x8(a5)    # quantity, x
    li  a3, 1
    sw  a3, 0xc(a5)    # enable
    wfi
    nop
    ret

.section .text
.align 2
.globl boot
boot:
    addi  sp, sp, -4
    sw    ra, 0(sp)
    csrsi mstatus, 0x8 # Enalbe glabal interrupt
    li    t6, 0x800
    csrs  mie, t6     # Enable local interrupt

     lui	a5, %hi(_dram_i_end)      # 0x2000
     addi	a5, a5, %lo(_dram_i_end)  
     addi	a4,a5,4
     lui	a1,0x20000
     mv	a1,a1
     sub	a0,a4,a1
     lui	a5,0x10
     mv	a2,a5
     call dma_set
     
     lui	a5,0x20
     mv	a5,a5
     addi	a4,a5,4 # 20004 <__bss_end+0x4>
     lui	a2,0x20
     mv	a2,a2
     sub	a0,a4,a2
     lui	a5,0x20101
     mv	a1,a5
     call dma_set
     lw	ra,0(sp)
     addi	sp,sp,4
     ret