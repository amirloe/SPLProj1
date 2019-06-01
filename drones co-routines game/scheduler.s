section .text
    extern cores
    extern printer
    extern num_of_drones
    extern steps_till_print
    global init_next_cor
    extern resume
    extern do_resume

init_next_cor:

    mov eax,0;

    mov ecx,0
    rrobin:
    mov ebx,[cores]
    mov edx,ecx
    shl edx,3 ; edx = edx*8 =>based on cor-size = 8 
    add ebx,edx
    call resume

    inc eax
    cmp eax,[steps_till_print]
    jne not_print
    mov ebx,printer
    call resume
    mov eax,0

    not_print:
    ;roundrobin
    inc ecx
    cmp ecx,[num_of_drones]
    jne rrobin

   ; inc eax
    ;cmp eax,4
   ; je exit


    mov ecx,0
    jmp rrobin

    exit:
    mov eax,1
    mov ebx,0
    int 0x80
