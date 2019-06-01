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

section .rodata
global printer_drone_format
global printer_target_format
global s_format
global f_format

eror: db "Error, lack of args",10,0
s_format: db "%s",0
f_format: db "%.2lf",10,0
int_format: db "%d",0
my_format: db "%hX",10,0
in_float_format: db "%f",0
short_format: db "%hu",10,0
printer_drone_format: db "%d,%.2lf,%.2lf,%.2lf,%d",10, 0
printer_target_format: db "%.2lf,%.2lf",10, 0

section .bss
    global printBuffer 
    global drone_x
    global drone_y
    global drone_alpha
    global drone_points
    global cores
    global corf_off
    global cor_soff
    global drones
    global printer
    global scheduler
    global num_of_drones
    global steps_till_print
    global current_drone
    global current_sp
    global current_cor
    global drone_size
    global create_target
    global convert_to_degrees
    global get_random
    global scale_to
    global lfsr
    global convert_to_rads 
    global beta
    global max_dist
    global target_cor
    
    global num_of_points
    global target
    global target_x_off
    global target_y_off
    global resume
    global do_resume
    global free_aloc_mem


    extern init_next_cor
    extern print_game_board
    extern target_main
    extern drone_main
    target: resb 20 ; the target structure
                        ; x - 10b
                        ;y  - 10b
    drones: resb 4 ; a pointer to the begining of the drones array
                        ;drone struct:
                        ; x - 10b
                        ; y - 10b
                        ; alpha - 10b
                        ; points - 8b
                        ; id - 8b
    ;input argumants
    num_of_drones: resb 4
    num_of_points: resb 4
    steps_till_print: resb 4
    beta: resb 10
    max_dist: resb 10
    lfsr: resb 2
    ;
    ;cores
    cores: resb 4
    printer: resb 8
    scheduler: resb 8
    target_cor: resb 8



section .data
    ;tmp buffer
    first_target: db 0
    inBuffer: dd 0
    printBuffer: dq 0
    current_drone: dd 0
    current_sp:dd 0
    current_cor: dd 0

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

    stksz equ 16*1024
    corf_off equ 0
    cor_soff equ 4

    core_size equ 8
    MAX_SHORT_VAL equ 65536

section .text
  align 16

     global main
     extern printf
     extern fprintf
     extern sscanf
     extern malloc
     extern free

main:
    push ebp
	mov ebp, esp

    mov ecx,[ebp+8]    ; ecx = argc
    cmp dword ecx,7
    jb error

    call get_input

    ;Gnerate "random" target and Drones:
    ;first the target is simple so we do this shit
    set_target: 

    call create_target

    ;now, malloc memory for the drones array
    ;calc how many place is needed
    malloc_data:
        malloc_drones:
            mov edx,0
            mov eax,[num_of_drones]
            mov ecx,drone_size
            mul ecx
            mov ecx,eax ; ecx = drone_size*Num_of_drones

            push ecx
            call malloc
            add esp,4

            mov [drones],eax

        ;loop that genretes random values for each drone:
        generate_drove_vals:
            mov ebx, 0 ; a register that will hold random value
            mov ecx, 0 ; counter

            .loop_gen_vals:
            cmp dword ecx,[num_of_drones]
            je .end_generate ; jump to end when reach the end of the array
            
            call get_random ; generates random value
            mov bx, [lfsr] ; move the random value to register
            push ebx
            push dword 100
            push dword 0
            call scale_to
            add esp, 12

            mov edx,0
            mov eax,drone_size
            mul ecx
            add eax,drone_x
            mov edx,[drones]
            
            fstp tword [edx+eax] ; generate random x-value for the drone

            call get_random ; generates random value
            mov bx, [lfsr] ; move the random value to register
            push ebx
            push dword 100
            push dword 0
            call scale_to
            add esp, 12

            mov edx,0
            mov eax,drone_size
            mul ecx
            add eax,drone_y
            mov edx,[drones]

            fstp tword [edx+eax] ; generate random y-value for the drone
            
            call get_random ; generates random value
            mov bx, [lfsr] ; move the random value to register
            push ebx
            push dword 360
            push dword 0
            call scale_to
            add esp, 12
            call convert_to_rads
           

            mov edx,0
            mov eax,drone_size
            mul ecx
            add eax,drone_alpha
            mov edx,[drones]

            fstp tword [edx+eax] ; generate random angel for the drone

            mov edx,0
            mov eax,drone_size
            mul ecx
            add eax,drone_id
            mov edx,[drones]

            mov ebx,ecx
            inc ebx
            mov [edx+eax],ebx ;set the drone id on the struct
            
            inc ecx
            
            jmp .loop_gen_vals

            .end_generate:





        ;End of ranomized Drones Location.


        malloc_cores:
            mov edx,0
            mov eax,[num_of_drones]
            mov ecx,core_size
            mul ecx
            mov ecx,eax; ecx  = core_size*Num_of_cores
            tri:
            pushad
            push ecx
            call malloc
            add esp,4
            mov [cores],eax
            popad



            

        mov ecx,0
        core_alloc:
            cmp ecx,[num_of_drones]
            je end_malloc_cores
            mov edx,0
            mov eax,core_size
            mul ecx

        mov [inBuffer],eax 
        ;compute the offset of the current co-routine

        pushad
        push dword stksz
        call malloc
        add esp,4
        mov edx,[inBuffer]
        mov ecx,[cores]

        add eax,stksz
        mov [ecx+edx+cor_soff],eax ;save the pointer on the struct
        mov dword [ecx+edx+corf_off],drone_main
        popad 
        
        inc ecx
        jmp core_alloc

        end_malloc_cores:

        ;start the scheduler main function:
        ;The schdulr malloc:

        mov dword [scheduler+corf_off],init_next_cor
        pushad
        push dword stksz
        call malloc
        add esp,4

        add eax,stksz
        mov [scheduler+cor_soff],eax ;save the pointer on the struct       
        popad ;allocate memory for the current stack

        


        ;The printer malloc:

        mov dword [printer+corf_off],print_game_board
        pushad
        push dword stksz
        call malloc
        add esp,4
  
        add eax,stksz
        mov [printer+cor_soff],eax ;save the pointer on the struct
        popad ;allocate memory for the current stack

        ;the target malloc

        mov dword [target_cor+corf_off],target_main
        pushad
        push dword stksz
        call malloc
        add esp,4
  
        add eax,stksz
        mov [target_cor+cor_soff],eax ;save the pointer on the struct
        popad ;allocate memory for the current stack



        
    ;init cors
    init_drones:
        mov ecx,0
    inco_term:
        cmp ecx,[num_of_drones]
        je init_scheduler
        push dword [cores]
        push ecx
        call intco
        add esp,8
        inc ecx
        jmp inco_term


    init_scheduler:
        push dword scheduler
        push dword 0
        call intco
        add esp,8
    init_printer:
        push dword printer
        push dword 0
        call intco
        add esp,8 
    init_target:
        push dword target_cor
        push dword 0
        call intco
        add esp,8

    pushad

    mov [current_sp],esp
    mov ebx,scheduler
    jmp do_resume

    jmp end       


    intco:
        push ebp
	    mov ebp, esp
        pushad

        mov ebx,[ebp+8]
        shl ebx,1 ;index = index*2

        mov edx,[ebp+12]; argumant of the relvant array
        
       ; mov eax,[edx+4*ebx+corf_off]
        mov [current_sp],esp
        mov esp,[edx+4*ebx+cor_soff] ;based on the fact that cor size is 8
        cmp edx,[cores]
        jne not_drone

        yes:
        mov ecx,ebx
        shr ecx,1
        inc ecx
        push ecx

        not_drone:
        push dword [edx+4*ebx+corf_off]
        pushfd
        pushad
        mov [edx+4*ebx+cor_soff],esp
        
        mov esp,[current_sp]
        popad
        mov esp,ebp
        pop ebp
        ret


    
    


    error:

    push s_format
    push eror
    call printf
    add esp,8
    end:
    mov esp, ebp	
	pop ebp
    ret

;;; get_input takes the argumants and save them in global vars
    get_input:

        mov    esi,[ebp+12] ; esi = argv

        mov ebx,[esi+4] ;ebx = argv[1]
        
        pushad
        push dword num_of_drones ;call scanf and set the value in num_of_drones
        push int_format
        push ebx
        
        call sscanf
        add esp,12
        popad

        mov ebx,[esi+8] ;ebx = argv[2]

        pushad
        push dword num_of_points ;call scanf and set the value in num_of_points
        push int_format
        push ebx
        
        call sscanf
        add esp,12
        popad

        mov ebx,[esi+12] ;ebx = argv[3]

        pushad
        push dword steps_till_print ;call scanf and set the value in steps_till_print
        push int_format
        push ebx
        
        call sscanf
        add esp,12
        popad


        mov ebx,[esi+16] ;ebx = argv[4]

        pushad
        push dword inBuffer 
        push in_float_format
        push ebx
        
        call sscanf
        add esp,12
        popad

        fld dword [inBuffer]
        call convert_to_rads
        fstp tword [beta] ;put the angel in floating point form.


        mov ebx,[esi+20] ;ebx = argv[5]

        pushad
        push dword inBuffer ;call scanf and set the value in max_dist
        push in_float_format
        push ebx
        
        call sscanf
        add esp,12
        popad

        fld dword [inBuffer]
        fstp tword [max_dist] ;put the distance in floating point form.
        


        mov ebx,[esi+24] ;ebx = argv[6]
        test:
        pushad
        push dword inBuffer ;call scanf and set the value in tmp buffer than move him to the lfsr
        push int_format
        push ebx
        
        call sscanf
        add esp,12
        popad

        and dword [inBuffer],0x0000FFFF
        mov eax,0
        mov word ax,[inBuffer]
        mov word [lfsr],ax



        ret

    ;update the lfsr to the next random number by the seed
    ;;tags 11 13 14 16
    get_random:
        push ebp
	    mov ebp, esp
        pushad

        mov eax,0
        mov ax,[lfsr] ; first put the lfsr in register

        mov ecx,16
        next_bit:
        mov ebx,eax
        shr eax,1

        and ebx,0x2D ;the value when the taps are on
        jp end_compute ;if parity flag is on the xor result is 0
        or eax,0x8000
       
        end_compute:
        dec ecx
        jnz next_bit

        mov [lfsr],ax

        ;push word [lfsr]
        ;push my_format
        ;call printf
       ; add esp,6
    
        popad
        mov esp,ebp
        pop ebp
        ret

    ;Scale to any value
    ;args: ebp+16=> the random num
    ;       ebp+12 => max val
    ;       ebp+8=> min val
    scale_to:
        push ebp
	    mov ebp, esp
        sub esp,4
        pushad

        ;mult (maxval-minval)*random_num
		fild dword [ebp+12]
        fisub dword [ebp+8]
        fimul dword [ebp+16]
        mov dword [inBuffer],MAX_SHORT_VAL
        
        fidiv dword [inBuffer]
		fiadd dword [ebp+8]
        popad
        mov eax,[ebp-4]
        add esp,4
        mov esp,ebp
        pop ebp
        ret

    convert_to_rads:
        ;on the stack there is the angel 'a' in degrees all we need to do is a*pi\180
        fldpi ;load pi 
        fmulp ; mul a*pi
        mov dword [inBuffer],180
        fidiv dword [inBuffer] ;div by 180  

        ret

    convert_to_degrees:
        mov dword [inBuffer],180
        fimul dword [inBuffer] ; mul by 180
        fldpi
        fdivp ; div by pi
        ret

    resume:
        pushfd
        pushad
        mov edx,[current_cor]
        mov[edx+cor_soff],esp
    do_resume:
        mov esp,[ebx+cor_soff]
        mov [current_cor],ebx
        popad
        popfd
        ret

    create_target:
        push ebp
	    mov ebp, esp
        sub esp,4
        pushad

        call get_random

        mov byte [first_target],1
        mov eax,0
        mov ax,[lfsr]
        push eax;get from the randomized number in range number
        push dword 100
        push dword 0
        call scale_to
        add esp,12
        fstp tword [target+target_x_off];put the x value in 10 byte form
        
        call get_random ;get new random number for y

        mov eax,0
        mov ax,[lfsr]
        push eax;get from the randomized number in range number
        push dword 100
        push dword 0
        call scale_to
        add esp,12
        fstp tword [target+target_y_off];put the y value in 10 byte form

        popad
        mov esp,ebp
        pop ebp
        ret
free_aloc_mem:
        push ebp
	    mov ebp, esp
        pushad
        ;free all malloc data
        ;free [drones]
        push dword [drones]
        call free
        add esp,4


        ;free each stack , maybe save pointer to the stack size?
        ;free [cores]
        
        popad
        mov esp,ebp
        pop ebp
        ret


