section .data

    ;target offsets:
    target_x_off equ 0
    target_y_off equ 10
    ;drone offsets
    drone_x equ 0
    drone_y equ 10
    drone_alpha equ 20
    drone_points equ 30
    drone_id equ 38

    drone_size equ 46

    corf_off equ 0
    cor_soff equ 4


section .text
    extern cores
    extern printer
    extern num_of_drones
    extern steps_till_print
    extern current_drone
    extern current_sp
    extern current_cor

    extern resume
    extern do_resume
    extern printer_target_format
    extern printer_drone_format
    extern target
    extern printBuffer
    extern convert_to_degrees

    extern scheduler
    extern printf
    extern drones
    global print_game_board
    
print_game_board:
    
    ; print target coordinates
    mov eax,target
    mov ebx,target_y_off
    fld tword [eax+target_y_off] ;load target-y into x87
    fstp qword [printBuffer] ; load target-y into print buffer
    push dword [printBuffer+4] ; push the second 32 bits of target-y
    push dword [printBuffer] ; push the first 32 bits of target-y
    fld tword [eax+target_x_off]; load target-x into x87
    fstp qword [printBuffer]; load target-x into print buffer
    push dword [printBuffer+4]; push the second 32 bits of target-x
    push dword [printBuffer]; push the first 32 bits of target-x
    push printer_target_format; push the format
    call printf; print the stuff
    add esp, 20; clear the stack
    


    mov ecx, 0 ; loop counter
    .print_loop:
    mov edx,[num_of_drones]
    cmp ecx, [num_of_drones] ;check if we reached the last drone
    je .end ; jump to the end

    pushad

    mov edx, 0 ;used for get the i-th drone in the array
    mov eax, drone_size
    mul ecx ;calculate the offset from the beginning of the array
    add eax,drone_points ;calculate the offset in the struct for points
    mov edx, [drones] ; edx = *drones
    push dword [edx+eax] ; push into the stack drones[i].points
    
    mov edx, 0 ;used for get the i-th drone in the array
    mov eax, drone_size
    mul ecx ;calculate the offset from the beginning of the array
    add eax,drone_alpha ;calculate the offset in the struct for alpha
    mov edx, [drones] ; edx = *drones
    fld tword [edx+eax] ; loading drones[i].alpha into x87
    call convert_to_degrees
    fstp qword [printBuffer] ;poping drones[i].alpha into print buffer
    push dword [printBuffer+4]
    push dword [printBuffer]    


    mov edx, 0 ;used for get the i-th drone in the array
    mov eax, drone_size
    mul ecx ;calculate the offset from the beginning of the array
    add eax,drone_y ;calculate the offset in the struct for y
    mov edx, [drones] ; edx = *drones
    fld tword [edx+eax] ; loading drones[i].y into x87
    fstp qword [printBuffer] ;poping drones[i].y into print buffer
    push dword [printBuffer+4]
    push dword [printBuffer]


    mov edx, 0 ;used for get the i-th drone in the array
    mov eax, drone_size
    mul ecx ;calculate the offset from the beginning of the array
    add eax,drone_x ;calculate the offset in the struct for x
    mov edx, [drones] ; edx = *drones
    fld tword [edx+eax] ; loading drones[i].x into x87
    fstp qword [printBuffer] ;poping drones[i].x into print buffer
    push dword [printBuffer+4]
    push dword [printBuffer]

    mov edx, 0 ;used for get the i-th drone in the array
    mov eax, drone_size
    mul ecx ;calculate the offset from the beginning of the array
    add eax,drone_id ;calculate the offset in the struct for points
    mov edx, [drones] ; edx = *drones
    push dword [edx+eax] ; push into the stack drones[i].points

    push printer_drone_format
    call printf
    add esp, 36


    popad

    inc ecx
    jmp .print_loop

    .end:
    mov ebx, scheduler

    call dword resume
    jmp print_game_board 
    








