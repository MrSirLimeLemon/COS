org 0x7C00
bits 16

jmp short main
nop

bdb_oem:                 DB 'MSWIN4.1'
bdb_bytes_per_sector:    DW 512
bdb_sectors_per_cluster: DB 1
bdb_reserved_sectors:    DW 1
bdb_fat_count:           DB 2
bdb_dir_entries_count:   DW 0E0h
bdb_total_sectors:       DW 2880
bdb_media_descriptor_type: DB 0F0h
bdb_sectors_per_fat:     DW 9
bdb_sectors_per_track:   DW 18
bdb_heads:               DW 2
bdb_hidden_sectors:      DD 0
bdb_large_sector_count:  DD 0

ebr_drive_number: DB 0
                  DB 0
ebr_signature:    DB 29h
ebr_volume_id:    DB 12h,34h,56h,78h
ebr_volume_label: DB 'COS        '
ebr_system_id:    DB 'FAT12   '

main:  
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [ebr_drive_number], dl
    mov ax, 1
    mov cl, 1
    mov bx, 0x7E00

    ;call disk_read
    mov si, startMsg
    call print

    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh,bh
    mul bx
    add ax, [bdb_reserved_sectors]
    push ax
    mov ax, [bdb_dir_entries_count]
    shl ax, 5
    xor dx,dx
    div word [bdb_bytes_per_sector]

    test dx,dx
    jz rootDirAfter
    inc ax
rootDirAfter:
    mov cl,al
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer
    call disk_read

    xor bx,bx
    mov di,buffer
searchKernel:
    mov si, file_kernel_bin
    mov cx,11
    push di
    repe cmpsb
    pop di
    je foundKernel
    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl searchKernel
    jmp kernelNotFound
kernelNotFound:
    mov si, msg_kernel_not_found
    call print
    hlt
    jmp halt
foundKernel:
    mov ax, [di+26]
    mov [kernel_cluster], ax
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]

    call disk_read

    mov bx, kernel_load_segment
    mov es, bx
    mov bx, kernel_load_offset
loadKernelLoop:
    mov ax, [kernel_cluster]
    add ax, 31
    mov cl, 1
    mov dl, [ebr_drive_number]

    call disk_read

    add bx, [bdb_bytes_per_sector]
    mov ax, [kernel_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx,dx
    jz even
odd:
    shr ax,4
    jmp nextClusterAfter
even:
    and ax, 0x0FFF
nextClusterAfter:
    cmp ax, 0x0FF8
    jae readFinish

    mov [kernel_cluster], ax
    jmp loadKernelLoop
readFinish:
    mov dl, [ebr_drive_number]
    mov ax, kernel_load_segment
    mov ds,ax
    mov es,ax
    jmp kernel_load_segment:kernel_load_offset
    hlt

halt:
	jmp halt
;input: LBA index to ax
;cx [bits 0-5]:sector number
;cx[6-15]:cylinder
;dh:head
lba_to_chs:
    push ax;
    push dx;
    xor dx,dx
    div word [bdb_sectors_per_track]
    inc dx
    mov cx,dx

    xor dx,dx
    div word [bdb_heads]
    mov dh,dl
    mov ch,al
    shl ah,6
    or cl,ah
    pop ax
    mov dl,al
    pop ax
    ret

disk_read:
    push ax,
    push bx,
    push cx,
    push dx,
    push di,

    call lba_to_chs

    mov ah, 02h
    mov di, 3
retry:
    stc
    int 13h
    jnc doneRead

    call diskReset

    dec di
    test di,di
    jnz retry
failDiskRead:
    mov si, read_failure
    call print
    hlt
    jmp halt
diskReset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc failDiskRead
    popa
    ret
doneRead:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    
print:
    push si
    push ax
    push bx
print_loop:
    LODSB
    or al,al
    jz done_print
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp print_loop
done_print:
    pop bx
    pop ax
    pop si
    ret

startMsg db  0x0D, 0x0A,'COS :) :P XD', 0x0D, 0x0A, 0
read_failure db 'bootRF', 0x0D, 0x0A, 0
file_kernel_bin db 'KERNEL  BIN'
msg_kernel_not_found db '!KERNEL.BIN', 0x0D, 0x0A, 0
kernel_cluster dw 0 

kernel_load_segment EQU 0x2000
kernel_load_offset EQU 0
;padding
times 510 - ($ - $$) db 0
dw 0AA55h

buffer:
