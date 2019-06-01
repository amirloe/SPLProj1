%macro shit 0
    pushad      
    fstp qword [printBuffer]
    push dword [printBuffer+4]
    push dword [printBuffer]
    push f_format
    call printf
    add esp,12
    fld qword [printBuffer]
    popad
%endmacro

%macro hoo 0
    push test_foo
    call printf
    add esp,4
%endmacro

section .rodata
test_print_format: db "Drone id %d: I am a winner",10,0
test_foo: db "foo", 10, 0

section .data
alpha: dd 0
delta: dd 0
current_off: dd 0



section .text

extern printf
extern resume
extern scheduler
extern s_format
extern drones
extern current_drone
extern scale_to
extern get_random
extern lfsr
extern convert_to_rads
extern convert_to_degrees
extern beta
extern max_dist
extern printBuffer
extern f_format
extern target
extern target_cor
extern num_of_points
extern free_aloc_mem
global drone_main

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


drone_main:
    finit
    mov edx,[esp]
    mov [current_drone],edx
;(*) calculate random angle ∆α       ; generate a random number in range [-60,60] degrees, with 16 bit resolution
    call get_random ;get new random number for y

    mov eax,0
    mov ax,[lfsr]
    push eax;get from the randomized number in range number
    push dword 60
    push dword -60
    call scale_to
    add esp,12
    call convert_to_rads
    fstp dword [alpha]

;(*) calculate random distance ∆d    ; generate random number in range [0,50], with 16 bit resolution 
    call get_random ;get new random number for y

    mov eax,0
    mov ax,[lfsr]
    push eax;get from the randomized number in range number
    push dword 50
    push dword 0
    call scale_to
    add esp,12
    fstp dword [delta]   

;(*) calculate a new drone position given ∆d and ∆α as follows:
 ;   (*) first change the current angle to be α + ∆α, keeping the angle between [0, 360] by wraparound if needed
    mov eax,[current_drone]
    dec eax
    mov edx,0
    mov ecx,drone_size
    mul ecx
    add eax,drone_alpha
    mov edx,[drones]
    fld tword [edx+eax]
    fadd dword [alpha]
    call convert_to_degrees
    pushad
    mov ebx,360
    push ebx
    call check_if_in_range
    add esp,4
    popad
    call convert_to_rads
    fstp tword [edx+eax]


  ;  (*) then move ∆d at the direction defined by the current angle, wrapping around the torus if needed

    fld tword [edx+eax] ;load the new angel to stack
    fsincos ;make sin and cos
    fld dword [delta] ; load the distance
    fmulp ;multipaly to get d*cos beta

    mov eax,[current_drone]
    dec eax
    mov edx,0
    mov ecx,drone_size
    mul ecx
    add eax,drone_x
    mov edx,[drones]
    fld tword [edx+eax] ; load the old x value
    faddp ; add to it the d*cos beta

    pushad
    mov ebx,100
    push ebx
    call check_if_in_range
    add esp,4
    popad ; set in the range of the board (0-100)

    fstp tword [edx+eax] ; save the new y value


    fld dword [delta]; load the distance
    fmulp ;multipaly to get d*sin beta

    mov eax,[current_drone]
    dec eax
    mov edx,0
    mov ecx,drone_size
    mul ecx
    add eax,drone_y
    mov edx,[drones]
    fld tword [edx+eax] ; load the old y value
    faddp ; add to it the d*sin beta


    pushad
    mov ebx,100
    push ebx
    call check_if_in_range
    add esp,4
    popad ; set in the range of the board (0-100)
    fstp tword [edx+eax] ; save the new x value

;(*) call mayDestroy(…) to check if a drone may destroy the target
   call mayDestroy
   ;call my_test

;(*) if yes
 ;   (*) destroy the target	
  ;  (*) if number of destroyed targets for this drone are >= T	
   ;    (*) print “Drone id <id>: I am a winner”	
    ;   (*) stop the game (return to main() function or exit)
    ;(*) resume target co-routine

    cmp dword eax, 1
    jne .return_sched

    ;can destroy target increase drone points
    mov eax,[current_drone]
    dec eax
    mov edx,0
    mov ecx,drone_size
    mul ecx
    add eax,drone_points
    mov edx,[drones]

    inc dword [edx+eax]

    ;check if drone won
    mov ecx, [edx+eax]
    cmp ecx, [num_of_points]
    jl .not_win
    
    ;print drone is the winner
    push dword [current_drone]
    push test_print_format
    call printf
    add esp, 8

    call free_aloc_mem

    mov eax,1
    mov ebx,0
    int 0x80
    
    ;TODO return to main

    ;if the drone didn't win switch to the target co-routine to create new target
    .not_win:
    mov ebx, target_cor
    call resume
    jmp drone_main

    ; if drone can't destroy switch back to the scheduler
   ; push dword [current_drone]
   ; push dword test_print_format
   ; call printf
   ; add esp,8

;(*) if no	
 ;   (*) switch back to a scheduler co-routine by calling resume(scheduler)	


    .return_sched:
	mov ebx,scheduler
    call resume
    jmp drone_main


;check if the top of the stack in range 0-[ebp+8]
;if it is above the max value, sub from it max value
;if it is below zero, add to it max val
check_if_in_range:
        push ebp
	    mov ebp, esp
        sub esp,4
        pushad


        fild dword [ebp+8]
        fcomip
        jbe sub_r

        fldz
        fcomip
        ja add_r

        jmp done_check

        add_r:
            fiadd dword [ebp+8]
            jmp done_check



        sub_r:
            fisub dword [ebp+8]

        done_check:
        popad
        mov esp,ebp
        pop ebp
        ret

mayDestroy:
    push ebp
    mov ebp, esp
    sub esp, 44
                ;ebp-10=dist
                ;ebp-20=gamma
                ;ebp-30=gamma-alpha-pi
                ;ebp-40=abs(alpha-gamma)
                ;ebp-44=can destory
    pushad

    ; calculate (x1-x2)^2
    
    mov ebx, target
    
    mov eax,[current_drone]
    dec eax
    mov edx,0
    mov ecx,drone_size
    mul ecx
    mov [current_off],eax
    add eax,drone_x

    mov edx,[drones]

    fld tword [ebx+target_x_off]
    fld tword [edx+eax]
    
    fsub 

    fld tword [ebx+target_x_off]
    fld tword [edx+eax]
    fsub 
    fmul 
    ; calculate (y1-y2)^2
    mov eax,[current_off]
    add eax,drone_y 

    fld tword [ebx+target_y_off]
    fld tword [edx+eax]

    fsub
    
    fld tword [ebx+target_y_off]
    fld tword [edx+eax]

    fsub

    fmul 

    ; calculate sqrt(x^2+y^2)
    fadd

    fsqrt
    ; saves the dist to temp var
    fstp tword [ebp-10]
    
	;calculate y1-y2
    mov ebx, target

    fld tword [ebx+target_y_off]
    mov eax,[current_off]
    add eax,drone_y 
    fld tword [edx+eax]

    fsub 

    ; calculate x1-x2
    mov ebx, target

    fld tword [ebx+target_x_off]
    mov eax,[current_off]
    add eax,drone_x 
    fld tword [edx+eax]

    fsub


	; calcuate atan2
    fpatan

    fstp tword [ebp-20]
    ; loads alpha into x87
    mov eax,[current_off]
    add eax,drone_alpha
    fld tword [edx+eax]

    fld tword [ebp-20]


    ;calculate abs(alpha-gamma)
    fsub

    ;save alpha-gamma to temp var ebp-30
    fstp tword [ebp-30]
    fld tword [ebp-30]
    fabs

    fldpi
    fcomip
    ja .no_add

    ; TODO check to which is the smaller angle to add the 2*pi=

    ;fstp

    fld tword [ebp-30]

    fldz
    fcomip
    jb .inc_gamma
    ;inc alpha
    fld tword [edx+eax]
    fldpi
    fldpi
    faddp
    faddp
    fld tword [ebp-20]

    jmp .compute

    .inc_gamma:

    fld tword [ebp-20]

    fldpi

    fldpi

    faddp

    faddp

    fstp tword [ebp-20]
    fld tword [edx+eax]

    fld tword [ebp-20]

    jmp .compute


    .no_add:

    mov eax,[current_off]
    add eax,drone_alpha
    fld tword [edx+eax]

    fld tword [ebp-20]


    .compute:
    fsub

    fabs

    fstp tword [ebp-40]
    fld tword [ebp-40]
    fld tword [beta]
    .foo:
    fcomip
    jb .cant
    
    ;calcualte FOL < max_dist
    fld tword [ebp-10]
    
    fld tword [max_dist]
    .goo:
    fcomip
    ja .can

    ; 0 if can't destroy
    .cant:

    mov dword [ebp-44], 0
    jmp .return

    .can:

    ; 1 if can destroy
    mov dword [ebp-44], 1

    .return:
    popad
    mov eax, [ebp-44]
    
    add esp, 44
    mov esp, ebp
    pop ebp
    ret

my_test:
    mov eax,1
    ret
