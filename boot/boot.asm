; VM32 bootstrap (machine mode)
; Entry point: 0x00001000
; Purpose:
;   1) initialize stack and timer0
;   2) load kernel image from disk D0
;   3) transfer control to kernel entry point

; ===== MMIO constants =====
CON_DATA         = 0xF0001000

TMR0_CTRL        = 0xF0002000
TMR0_COUNT       = 0xF0002004
TMR0_COMPARE     = 0xF0002008

DISK0_CTRL       = 0xF0003000
DISK0_STATUS     = 0xF0003004
DISK0_LBA        = 0xF0003008
DISK0_SECTORS    = 0xF000300C
DISK0_BUFFER_PTR = 0xF0003010

; ===== Load addresses =====
KERNEL_LOAD_ADDR = 0x10000000
KERNEL_ENTRY     = 0x10000000
KERNEL_LBA       = 1
KERNEL_SECTORS   = 16

start:
    ; Basic stack/frame setup
    MOVI SP, 0xEFFFFFF0
    MOVI BP, 0x00000000
    CLI

    ; Configure timer0:
    ; period = 100000 ticks, periodic mode, IRQ enabled
    MOVI R0, TMR0_COUNT
    MOVI R1, 0
    STORE R1, [R0 + 0]

    MOVI R0, TMR0_COMPARE
    MOVI R1, 100000
    STORE R1, [R0 + 0]

    MOVI R0, TMR0_CTRL
    MOVI R1, 0x00000007      ; EN | PERIODIC | IRQ_EN
    STORE R1, [R0 + 0]

    ; Program disk read D0:
    ; read KERNEL_SECTORS from KERNEL_LBA to KERNEL_LOAD_ADDR
    MOVI R0, DISK0_LBA
    MOVI R1, KERNEL_LBA
    STORE R1, [R0 + 0]

    MOVI R0, DISK0_SECTORS
    MOVI R1, KERNEL_SECTORS
    STORE R1, [R0 + 0]

    MOVI R0, DISK0_BUFFER_PTR
    MOVI R1, KERNEL_LOAD_ADDR
    STORE R1, [R0 + 0]

    ; START=1, WRITE=0 (read operation)
    MOVI R0, DISK0_CTRL
    MOVI R1, 0x00000001
    STORE R1, [R0 + 0]

wait_disk_busy:
    MOVI R0, DISK0_STATUS
    LOAD R1, [R0 + 0]
    MOVI R2, 0x00000001      ; BUSY
    AND R1, R2
    JNZ wait_disk_busy

    ; Check ERR bit
    MOVI R0, DISK0_STATUS
    LOAD R1, [R0 + 0]
    MOVI R2, 0x00000004      ; ERR
    AND R1, R2
    JNZ disk_error

    STI
    JMP KERNEL_ENTRY

disk_error:
    ; Output "E" to console and stop
    MOVI R0, CON_DATA
    MOVI R1, 69              ; 'E'
    STORE R1, [R0 + 0]
    HALT
