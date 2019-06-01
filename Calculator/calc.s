;  THE ALMIGHTY CALCULATOR
;   CREATED BY:
;       AMIR LOEWENTHAL - 205629124
;       EYAL MAZUZ - 208373977
%macro printCalc 0
    push formatString
    push calc
    call printf
    add esp,8
%endmacro

%macro functionstart 0
    push ebp
	mov ebp, esp	
%endmacro

%macro functionend 0		
	mov esp, ebp	
	pop ebp
%endmacro

;puts an argument in the stack,in case of an error print error
%macro my_push 1
    mov ebx,[stack_pointer]
    cmp ebx,stack_size
    je %%overflow

    cmp byte [debug],1 
    jne %%.not_debug

    pushad             ;the printf mass up the eax register so we will save him before and after
    push push_labal
    push formatString
    push dword [stderr]
    call fprintf
    add esp,12
    popad

    pushad              ;the print_number mass up the eax register so we will save him before and after
    push %1
    call print_number
    add esp,4
    popad

    %%.not_debug:
    mov [my_stack+4*ebx],%1
    inc dword [stack_pointer]
    jmp %%end_push

    %%overflow:
        push error_1
        push formatString
        call printf
        add esp,8
        mov eax,0  
    %%end_push:

%endmacro

;takes an argument out of the stack and put it on eax,in case of an error print error
%macro my_pop 0
    mov ebx,[stack_pointer]
    cmp ebx,0
    je %%underflow
    dec dword [stack_pointer]
    dec ebx
    mov eax,[my_stack+4*ebx]

    cmp byte [debug],1
    jne %%end_pop

    pushad             ;the printf mass up the eax register so we will save him before and after
    push pop_labal
    push formatString
    push dword [stderr]
    call fprintf
    add esp,12
    popad

    pushad              ;the print_number mass up the eax register so we will save him before and after
    push eax
    call print_number
    add esp,4
    popad



    jmp %%end_pop

    %%underflow:
        push error_2
        push formatString
        call printf
        add esp,8
        mov eax,0

    %%end_pop:

%endmacro
  
  section .rodata
  calc: db "calc:",0
  error_1: db "Error: Operand Stack Overflow",10,0
  error_2: db "Error: Insufficient Number of Arguments on Stack",10,0
  error_3: db "wrong Y value",10,0
  pop_labal: db "Pop:",0
  push_labal: db "Push:",0
  formatString: db "%s",0
  formatpadHex: db "%02X",0
  formatHex: db "%X",0
  formatNumber: db "%d",10,0
  newline: db 10,0

  section .bss
    head:resd 1
    my_stack: resd 5
    inputbuffer: resb 82 

    section .data
    stack_pointer: dd 0
    link_size: equ 5
    stack_size: equ 5
    numOfOps: dd 0
    counter: dd 0
    isFirstLink: db 0 
    debug: db 0

  section .text
  align 16
     global main
     extern printf
     extern fflush
     extern malloc
     extern calloc
     extern free
     extern gets
     extern fgets
     extern fprintf
     extern stderr
main:
    ;functionstart
    functionstart
    mov ecx,[ebp+8]    ; ecx = argc
    cmp dword ecx,1
    je no_params
    mov    esi,[ebp+12] ; esi = argv
    mov ebx,[esi+4] ;ebx = argv[1]
    cmp byte [ebx],'-'
    jne no_params
    cmp byte [ebx+1],'d'
    jne no_params
    mov byte [debug],1

    ;call the main function
    no_params:
    call myCalc

    mov [numOfOps],eax
    ;print number of calculations
    push dword [numOfOps]
    push formatNumber
    call printf
    add esp,8

    jmp end

;the function do all the calculations and returns the number of ops
myCalc:
        functionstart
    infloop:
        printCalc
        ;gets(inputbuffer)
        push inputbuffer
        call gets
        add esp,4

        myread:

        cmp byte [inputbuffer],'q'
        je end_in

        cmp byte [inputbuffer],'p'
        je popandprint

        cmp byte [inputbuffer],'+'
        je unsadd

        cmp byte [inputbuffer],'d'
        je dupl

        cmp byte [inputbuffer],'^'
        je pow

        cmp byte [inputbuffer],'n'
        je numbits

        cmp byte [inputbuffer],'v'
        je negpow

        cmp byte [inputbuffer],'s'
        jne input_num
        cmp byte [inputbuffer+1],'r'
        je sqroot

    input_num:
        call add_number
        jmp infloop

    popandprint:
        call pop_and_print
        jmp infloop

    unsadd:
        call unsigned_addition
        jmp infloop

    dupl:
        call duplicate
        jmp infloop

    pow:
        call power
        jmp infloop
    
    negpow:
        call neg_power
        jmp infloop

    numbits:
        call num_of_bits
        jmp infloop

    sqroot:
        call squere_root
        jmp infloop
  
    end_in:
        call empty_stack
        mov eax,[numOfOps]
        functionend
        ret

;the function pop the top argumant on the stack and calculates its squere root
squere_root:

            functionstart
            sub     esp, 20          ; Leave space for local var on stack
            pushad                  ; Save some more caller state

            my_pop
            cmp eax,0
            je end_sqrt

            mov [ebp-4],eax ;save the link in a local var
            mov [ebp-8],eax ;keep the head of the list for later free
            mov dword [ebp-12],0 ; counter = 0
            mov dword [ebp-16],0 ;IR
            mov dword [ebp-20],0 ;currx =0

            mov eax,[ebp-4]
        .next:
            mov ebx,0
            mov byte bl,[eax] ;mov ebx,currlink.data
            push ebx
            inc dword [ebp-12]
            mov eax,[eax+1] ;eax = currlink.next
            cmp eax,0
            jne .next
        
        push dword 0

        call findx
        mov [ebp-20],eax ;curr x = x
        add esp,4 ; pop prevIR
        mov eax,[ebp-16] ; eax = prevIR
        pop ecx ;orginal data = ecx
        mov ebx,16
        mul ebx
        add eax,[ebp-20] ;eax = IRx
        mov [ebp-16],eax ; IR = IRx
        mov ebx,[ebp-20]
        mul ebx ;eax = IRx*x
        sub ecx,eax ; ecx = original - IRx*x = remainder
        dec dword [ebp-12] ; counter --
        jz found_sqrt
        ;prepare next data for the next link
        calc_next_link:
            mov eax,ecx
            shl eax,8
            pop ebx
            add eax,ebx ; eax = oldreminder | nextSection
            push eax  ; new nextSection  = eax
            mov eax,[ebp-16]
            shl eax,1 ; New IR = IR*2
            push eax
            call findx
            mov [ebp-20],eax ;curr x = x
            mov eax,[ebp-16] ;eax = prev IR
            shl eax,4
            add dword eax,[ebp-20]
            mov [ebp-16],eax ; IR=IRx
            pop eax ;eax = IR'
            shl eax,4
            add eax,[ebp-20]
            mul dword [ebp-20] ;eax = IR'x*x
            pop ecx
            sub ecx,eax ;IR'x*x - section = section reminder

            dec dword [ebp-12] ; counter --
            jz found_sqrt
            jmp calc_next_link


    

        
        found_sqrt:
        ;now create linked list of the sqrt result
        mov eax,[ebp-16]
        push_next_num:
            mov ebx,0
            mov bl,al
            push ebx
            inc dword [ebp-12]
            shr eax,8
            jnz push_next_num
        mov dword [head],0
        mov byte [isFirstLink],0

        sqrt_create_new_number:                      ;the values of the link are placed in the stack on the right order, all we have to do is to pop them
        cmp dword [ebp-12],0                        ;out and create the linked list.
        je sqrt_push_number

        call make_link
        add esp,4
        dec dword [ebp-12]

        cmp byte [isFirstLink],0                    ;if it is the first link , head =eax
        jne .not_first_link                          ;else, chain the previous head on the tail of the new head.
        mov [head],eax
        mov byte [isFirstLink],1
        jmp sqrt_create_new_number
        .not_first_link:
        mov ebx,[head]
        mov [eax+1],ebx
        mov [head],eax
        jmp sqrt_create_new_number

    sqrt_push_number:
        push dword [ebp-8]         ;free x
        call free
        add esp,4

        mov eax,[head]              ;push the new number
        my_push eax

        jmp end_sqrt

    end_sqrt:
            inc dword [numOfOps]
            popad                   ; Restore caller state (registers)
            add     esp, 20          ; Restore caller state
            pop     ebp             ; Restore caller state
            ret                     ; Back to caller
;the function recieves two argumants a,b and maximal x that keep the equation ax*x<b
findx:
            functionstart
            sub     esp,8          ; Leave space for local var on stack
            pushad                  ; Save some more caller state
            
            mov eax,[ebp+8]  ;the IR of prev link
            mov ebx,[ebp+12] ;the data of the curr link
            mov dword [ebp-4],1
        
            mov edx,0
            mov ecx,16
            mul ecx
            mov [ebp-8],eax ;save the IR on local val

            loop_term:
            mov eax,[ebp-8]
            add eax,[ebp-4] ;eax = IR'x
            mov ecx,[ebp-4] ; ecx = x
            mul ecx ; eax = IR'x*x
            cmp dword eax,[ebp+12]
            jg found_x ;if IR'x > x
            inc dword [ebp-4] ; x++
            jmp loop_term
            
            found_x:
                dec dword [ebp-4] ; x--

            popad                   ; Restore caller state (registers)
            mov     eax, [ebp-4]    ; place returned value where caller can see it
            add     esp, 8          ; Restore caller state
            pop     ebp             ; Restore caller state
            ret                     ; Back to caller

;;the function takes out x and y from the operand stack and pushes in x*2^-y.
neg_power:
        functionstart
        sub     esp, 20         ; Leave space for local var on stack
        pushad                  ; Save some more caller state

        cmp dword [stack_pointer],2 ;the negpow function works only when there are at least 2 args on stack
        jl negpow_underflow

        mov dword [ebp-20],0;counter = 0

        my_pop
        mov [ebp-4],eax ;ebp-4 = x
        mov [ebp-12],eax; save the head on ebp-12 for later delete

        my_pop
        mov [ebp-8],eax ; ebp-8 = y
        mov [ebp-16],eax; save the head on ebp-16 for later delete

        mov ebx,0    ;check if y <=200
        mov byte bl,[eax]
        cmp dword [eax+1],0
        jne neg_illegal_input
        cmp ebx,0xC8
        jg neg_illegal_input

        ;now begin the real neg pow function

        mov [ebp-8],ebx  ;keep the real value of y in ebp-8
        mov dword [head],0
        mov byte [isFirstLink],0

    neg_sub_term:
        mov eax,[ebp-8]
        sub eax,8
        jb complex_dvision ;if there are less then 8 shr to do we jump to the complex section

        mov [ebp-8],eax ;save the new value
        mov ebx,[ebp-4]
        mov ebx,[ebx+1]
        mov [ebp-4],ebx ;for each 8 shr we eliminate one link
        cmp ebx,0       ;if there are no more links and we are still need to shr, the result will be 0
        je set_zero_link
        cmp dword [ebp-8],0 ;if the number of shr divides by 8 just add the rest of the links as is
        je simple_divison
        jmp neg_sub_term

    set_zero_link:
        push ebx
        inc dword [ebp-20];counter++
        jmp neg_create_new_number
    simple_divison:
        mov eax,[ebp-4]
        mov ebx,0
        mov byte bl,[eax] ;ebx = currlink.getdata

        push ebx
        inc dword [ebp-20];counter++

        mov eax,[eax+1]
        mov [ebp-4],eax ; x = currlink.next
        cmp dword [ebp-4],0 ; if x!=null
        jne simple_divison ; add next link
        jmp neg_create_new_number ; else:create number

    complex_dvision:

    mov edx,[ebp-4]
    mov eax,0
    mov al,[edx] ;eax = currlink
    mov edx,[edx+1]
    mov ecx,[ebp-8]
    shr eax,cl ;shr eax,[ebp-8]
    cmp edx,0                    ;if currlink.next==0
    jne not_last_link

    cmp eax,0                   ;if the first link is zero and it is not the only number
                                ; dont add it
    jne push_curr_link
    cmp dword [ebp-20],0
    jne neg_create_new_number

    push_curr_link:
        push eax                                            ;push eax,done
        inc dword [ebp-20]
        jmp neg_create_new_number

    not_last_link:
        mov ebx,0 ;ebx = currlink.next
        mov bl,[edx]
        shl ebx,8  ;mov the next link into bh to get the remaining of the shr func in bl
        shr ebx,cl ;shr ebx,[epb-8]
        or eax,ebx ;or eax,ebx
        and eax,0x000000FF ;delete the overflow bits

        push eax ;push eax
        inc dword [ebp-20]
        
        mov[ebp-4],edx ;currlink = currlink.next
        jmp complex_dvision



    neg_create_new_number:                      ;the values of the link are placed in the stack on the right order, all we have to do is to pop them
        cmp dword [ebp-20],0                        ;out and create the linked list.
        je neg_push_number

        call make_link
        add esp,4
        dec dword [ebp-20]

        cmp byte [isFirstLink],0                    ;if it is the first link , head =eax
        jne .not_first_link                          ;else, chain the previous head on the tail of the new head.
        mov [head],eax
        mov byte [isFirstLink],1
        jmp neg_create_new_number
        .not_first_link:
        mov ebx,[head]
        mov [eax+1],ebx
        mov [head],eax
        jmp neg_create_new_number

    neg_push_number:
        push dword [ebp-12]         ;free x
        call free
        add esp,4
    
        push dword [ebp-16]         ;free y
        call free
        add esp,4

        mov eax,[head]              ;push the new number
        my_push eax

        jmp end_negpow


    neg_illegal_input:
        push error_3 ;print an error
        push formatString
        call printf
        add esp,8

        mov eax,[ebp-8] ;push the arguments back to the stack
        my_push eax
        mov eax,[ebp-4]
        my_push eax
        jmp end_negpow



    negpow_underflow:
        push error_2
        push formatString
        call printf
        add esp,8
        jmp end_negpow

    end_negpow:
        inc dword [numOfOps]
        popad                   ; Restore caller state (registers)
        add     esp, 20          ; Restore caller state
        pop     ebp             ; Restore caller state
        ret                     ; Back to caller


;the function pop out a number and push the number of 1 bits inside it        
num_of_bits:
        functionstart
        pushad
        sub esp,12

        mov dword [ebp-8],0 ; save the number of 1 bits on a local var
        my_pop ;try to pop an item to countbits
        cmp eax,0
        je end_num_of_bits
        mov [ebp-4],eax ;put the linked list in a local var
        mov [ebp-12],eax ; save the head of the link for later delete

        .next_link:
        mov eax,[ebp-4]
        mov ebx,0
        mov byte bl,[eax];save on ebx the node data
        mov eax,[eax+1]
        mov [ebp-4],eax ;curr node = curr.next

        push ebx
        call count_bits
        add esp,4
        add [ebp-8],eax ;add the num of 1 bits in the current node
        cmp dword [ebp-4],0
        jne .next_link

        ;now the ebp-8 contains the num of 1 bits in the number,lets make a linked list out of it!
        mov dword [head],0

        mov ebx,[ebp-8]                     ;take the first 8 bits from ebx and create a link from them
        and ebx,0x000000FF

        push ebx
        call make_link
        add esp,4

        mov [head],eax                      ;save the data on the head global var

        shr dword [ebp-8],8                 ;go to the next 8 bits of ebx
        ;there are at most 80*4=0x140 1 bits in the number therefore it needs at most 2 links
        cmp dword [ebp-8],0    ;if there is no need in an extra link push to the stack argumant
        je push_link

        mov ebx,[ebp-8]             ;take the next 8 bits from ebx and create a link from them
        and ebx,0x000000FF

        push ebx
        call make_link
        add esp,4
    
        mov edx,eax          ;chain the numbers backward in a little endian form
        mov eax,[head]
        mov [eax+1],edx
        mov [head],eax

    push_link:
        mov eax , [head]
        my_push eax

        push dword [ebp-12]  ;free the old link data
        call free_link
        add esp,4

    end_num_of_bits:
        inc dword [numOfOps]
        add esp,12
        popad
        functionend
        ret
;the function recive a number and returns the number of 1 bit in that number
count_bits:
        
            functionstart
            sub     esp, 4          ; Leave space for local var on stack
            pushad                  ; Save some more caller state
            
            mov eax,[ebp+8]
            mov ecx,0
            mov ebx,2
            .term:
                cmp eax,0
                je .done
                mov edx,0
                div ebx
                add ecx,edx
                jmp .term
                

            .done:
            mov [ebp-4],ecx
            popad                   ; Restore caller state (registers)
            mov     eax, [ebp-4]    ; place returned value where caller can see it
            add     esp, 4          ; Restore caller state
            pop     ebp             ; Restore caller state
            ret                     ; Back to caller

;the function takes out x and y from the operand stack and pushes in x*2^y.
power:
    functionstart
    sub esp,24 ;clear space for 4 local vars
    pushad

    cmp dword [stack_pointer],2 ;the add function works only when there are at least 2 args on stack
    jl pow_underflow

    mov dword [ebp-20],0 ; counter =0
    mov dword [ebp-24],0 ; remaining from prev link shl =0

    my_pop
    mov [ebp-4],eax ;ebp-4 = x
    mov [ebp-12],eax; save the head on ebp-12 for later delete

    my_pop
    mov [ebp-8],eax ; ebp-8 = y
    mov [ebp-16],eax; save the head on ebp-16 for later delete

    mov ebx,0    ;check if y <=200
    mov byte bl,[eax]
    cmp dword [eax+1],0
    jne illegal_input
    cmp ebx,0xC8
    jg illegal_input

    ;start the real pow function:

    mov [ebp-8],ebx ;put in y the real value
    mov dword [head],0
    mov byte [isFirstLink],0
    ;if the shl bigger than 8, we just add zeros
    sub_term:
    mov eax,[ebp-8]
    sub eax,8
    jb complex_mult

    mov [ebp-8],eax ;save the new value on y

    mov ecx,0 ;add zeros to the number
    push ecx
    inc dword [ebp-20]
    
    cmp eax,0
    je simple_mult

    jmp sub_term
    
    complex_mult:

        .next_link:
        mov eax,[ebp-4] ;eax =currlink
        mov ebx,0 ;ebx = currlink.data
        mov bl,[eax]

        mov ecx,[ebp-8]
        shl ebx,cl ;shl ebx with cl (cl<8)
        mov edx,ebx
        and ebx,0x000000FF
        or ebx,[ebp-24] ;add to ebx the prev link remainning of the shl
        push ebx
        inc dword [ebp-20]
        
        and edx,0x0000FF00 ;save the remaining of the current link in edx
        shr edx,8
        mov [ebp-24],edx

        mov eax,[eax+1]
        mov [ebp-4],eax ;currlink = currlink.next

        cmp dword [ebp-4],0 ;if next != null continue
        jne .next_link

        cmp dword [ebp-24],0 ; if there is remaining add it to the number
        je create_new_number

        push dword [ebp-24]
        inc dword [ebp-20]
        jmp create_new_number



    simple_mult:
        ; here we only chain x in the end of the zeros, case where y divides by 8
        cont_chain:
            mov eax,[ebp-4]
            mov ebx,0
            mov byte bl,[eax]
            push ebx
            inc dword [ebp-20] ;counter++
            mov ebx,[eax+1]
            mov [ebp-4],ebx
            cmp dword [ebp-4],0 
            jne cont_chain



    create_new_number:                          ;the values of the link are placed in the stack on the right order, all we have to do is to pop them
        cmp dword [ebp-20],0                        ;out and create the linked list.
        je push_number

        call make_link
        add esp,4
        dec dword [ebp-20]

        cmp byte [isFirstLink],0                    ;if it is the first link , head =eax
        jne not_first_link                          ;else, chain the previous head on the tail of the new head.
        mov [head],eax
        mov byte [isFirstLink],1
        jmp create_new_number
        not_first_link:
        mov ebx,[head]
        mov [eax+1],ebx
        mov [head],eax
        jmp create_new_number




    push_number:
        push dword [ebp-12]         ;free x
        call free
        add esp,4
    
        push dword [ebp-16]         ;free y
        call free
        add esp,4

        mov eax,[head]              ;push the new number
        my_push eax

    jmp end_pow

    illegal_input:
        push error_3 ;print an error
        push formatString
        call printf
        add esp,8

        mov eax,[ebp-8] ;push the arguments back to the stack
        my_push eax
        mov eax,[ebp-4]
        my_push eax
        jmp end_pow


    pow_underflow:
        push error_2
        push formatString
        call printf
        add esp,8
        jmp end_pow

    end_pow:
    inc dword [numOfOps]
    popad
    add esp,24
    functionend
    ret
;duplicates the top number in the stack
duplicate:
        functionstart
        pushad
        sub esp,8

        mov dword [ebp-8],0 ; counter = 0
        my_pop ;try to pop an item to duplicate
        cmp eax,0
        je .end

        mov [ebp-4],eax ; save the pointer on the stack
        my_push eax ;push it back to the operand stack

        .next_link:
            mov eax,[ebp-4] ;take the head of the list into eax
            mov ebx,0
            mov byte bl,[eax] ;move the data into ebx
            push ebx ; put the data on the stack for later use
            inc dword [ebp-8]
            mov eax,[eax+1] 
            mov [ebp-4],eax ; save the next link in ebp-4
            cmp dword [ebp-4],0
            jnz .next_link


        mov dword [head],0
        ;there is at least one link in the addition, lets make it
        call make_link
        add esp,4

        mov [head],eax 
        .dup_term:
        dec dword [ebp-8]
        cmp dword [ebp-8],0
        je .dup_done ;if finish create all the links push it to the stack operand
        call make_link ;use the data we saved for later use
        add esp,4
        mov edx,[head]
        mov [eax+1],edx ;chain the new link after the current link
        mov [head],eax
        jmp .dup_term

        .dup_done:
        mov eax,[head]
        my_push eax
        cmp eax,0 ;check if the push succes, if not free the link we created
        jnz .end
        push dword [head]
        call free_link
        add esp,4


    .end:
        inc dword [numOfOps]
        add esp,8
        popad
        functionend
        ret
;pop two args from the stack and push back the sum of them
unsigned_addition:
    functionstart
    pushad
    sub esp,20
    
     
    cmp dword [stack_pointer],2 ;the add function works only when there are at least 2 args on stack
    jl add_underflow

    mov dword [ebp-12],0;counter = 0
    mov edx,0 ;carry on edx
    
    my_pop
    mov [ebp-4],eax ;ebp-4 = first link
    mov [ebp -16],eax;save the head for later free
    my_pop
    mov [ebp-8],eax ; ebp-8 = second link
    mov [ebp-20],eax ; save the head for later free

    both_not_null:
    mov eax,[ebp-4] ; eax = curr first link pointer
    mov ecx,[eax+1]
    mov [ebp-4],ecx ; ebp-4 = firstlink.next
    mov ecx,0
    mov byte cl,[eax]
    mov eax,ecx ; eax = curr first link.data

    mov ebx,[ebp-8] ; ebx = curr second link pointer
    mov ecx,[ebx+1]
    mov [ebp-8],ecx ; ebp-4 = secondlink.next
    mov ecx,0
    mov byte cl,[ebx]
    mov ebx,ecx ; eax = curr second link.data
   

    add edx,0xFFFFFFFF                  ;The compare f*** with the flags, therfore i used the edx register as a flag for carry use, after each
    adc al,bl                           ;calculation I update the edx register with 1 when carry and 0 otherwise. before each adc I trigerd the carry flag
                                        ; by adding 0xFFFFFFFF do edx, if it is 0 the carry flag will keep 0' otherwise it will swtiched to 1.    


    mov edx,0 ;save the carry on edx
    adc edx,0

    push eax ; set the next link value on the stack
    inc dword [ebp-12]

    next_iteration_terms:
    cmp dword [ebp-4],0 ;first link is null
    jz first_is_null
    
    cmp dword [ebp-8],0 ;second link is null
    jnz both_not_null
    jmp second_is_null

    first_is_null:
    cmp dword [ebp-8],0 ;second link is null
    jz both_is_null

    mov ebx,[ebp-8] ; ebx = curr second link pointer
    mov ecx,[ebx+1]
    mov [ebp-8],ecx ; ebp-4 = secondlink.next
    mov ecx,0
    mov byte cl,[ebx]
    mov ebx,ecx ; eax = curr second link.data

    add edx,0xFFFFFFFF   ;same reason as above
    adc bl,0

    mov edx,0 ;save the carry on edx
    adc edx,0


    push ebx ; set the next link value on the stack
    inc dword [ebp-12]
    jmp next_iteration_terms


    second_is_null:

    mov eax,[ebp-4] ; eax = curr first link pointer
    mov ecx,[eax+1]
    mov [ebp-4],ecx ; ebp-4 = firstlink.next
    mov ecx,0
    mov byte cl,[eax]


    mov eax,ecx ; eax = curr first link.data

    add edx,0xFFFFFFFF ;same reason as above
    adc al,0

    mov edx,0 ;save the carry on edx
    adc edx,0


    push eax ; set the next link value on the stack
    inc dword [ebp-12]
    jmp next_iteration_terms


    both_is_null:
        ;cmp byte [ebp-24],1;if there is now carry the addition is complete
        cmp dl,1
        jne make_out
        mov eax,1 ;else add the carry to the linked list
        push eax
        inc dword [ebp-12]

    make_out:
        mov dword [head],0
        ;there is at least one link in the addition, lets make it
        call make_link
        add esp,4

        mov [head],eax
        .term:
        dec dword [ebp-12]
        cmp dword [ebp-12],0
        
        je .done
        call make_link
        add esp,4
        mov edx,[head]
        mov [eax+1],edx ;chain the new link after the current link
        mov [head],eax
        jmp .term

    .done:
        mov eax,[head]
        my_push eax
        
        push dword [ebp-16] ;free both old numbers
        call free_link
        add esp,4

        push dword [ebp-20]
        call free_link
        add esp,4

    jmp end_add
    add_underflow:
        push error_2
        push formatString
        call printf
        add esp,8
        jmp end_add

    end_add:
    inc dword [numOfOps]
    add esp,20    
    popad
    functionend
    ret
;make a linked list of the number and pushes it to the stack
add_number:
        functionstart
        pushad
        sub esp,12

    ;find the length of the number
        mov dword [ebp-12],0 ;flag for leading zeros
        mov dword [counter],0
        mov byte [isFirstLink],0
        mov eax,0
    find_len: ;calculate the size of the number ignoring leading zeros
        cmp byte [inputbuffer+eax], 0
        je found_len
        cmp byte [inputbuffer+eax], '0'
        jnz first_non_zero
        cmp dword [ebp-12],0
        jnz reg_number
        inc dword [counter]
        jmp reg_number
        first_non_zero:
        mov dword [ebp-12],1
        reg_number:
        inc eax
        jmp find_len
    found_len:
        ;check if the number is even or odd
        sub eax,[counter]
        jnz save_eax_reg ;if there is only zeros the sub will give us zero
        mov eax,1
        mov dword [counter],0
        save_eax_reg:
        mov [ebp-4],eax ;size in [epb-4]
        mov edx,0
        mov ecx,2
        div ecx
        cmp edx,1
        jne not_odd
        
        ;if odd calc the first number sepreatly
        mov edx,[counter]
        mov ebx,[inputbuffer+edx]
        and ebx, 0x000000FF ;takes the first char in the word
        inc dword [counter]

        push ebx
        call calc_value
        add esp,4

        push eax
        call make_link
        add esp,4

        mov [head],eax
        mov byte [isFirstLink],1

        dec dword [ebp-4]


    not_odd:
        mov ecx,[ebp-4]
    create_links:
        cmp ecx,0
        je full_link
        
        mov edx,[counter]
        mov ebx,[inputbuffer+edx]
        and ebx, 0x000000FF ;takes the first char in the word
        inc dword [counter]
        push ebx
        call calc_value
        add esp,4

        mov edx,eax
        shl edx,4
        mov [ebp-8],edx

        mov edx,[counter]
        mov ebx,[inputbuffer+edx]
        and ebx, 0x000000FF ;takes the first char in the word
        inc dword [counter]
        push ebx
        call calc_value
        add esp,4

        or dword eax,[ebp-8]

        push eax
        call make_link
        add esp,4

        ;check if first node
        cmp byte [isFirstLink],0
        je firstlink

        ;not first link:chain
        mov edx,[head]
        mov [eax+1],edx
        mov [head],eax
        jmp link_added

        firstlink:
            mov [head],eax
            mov byte [isFirstLink],1

        link_added:
            sub dword [ebp-4],2
            mov ecx,[ebp-4]
            jmp create_links

        full_link:

        mov eax,[head]

        first_push:
        my_push eax
        cmp eax,0; if the push failed - eax =0
        jne end_push

        push dword [head] ;
        call free_link
        add esp,4

    end_push:
        ;inc dword [numOfOps]

        add esp,12
        popad
        functionend
        ret
;the function recieves an ascii char and replace it by its hex value
calc_value:
    functionstart

    mov eax,[ebp+8]
    cmp dword eax,'9'
    jg is_letter

    sub eax,'0'
    jmp finish

    is_letter:
    sub eax,'A'
    add eax,10

    finish:
    functionend
    ret
; the functions recives a value and returns a pointer to a link with the data
make_link:
    functionstart

    push link_size
    call malloc
    end_malloc:
    add esp,4
    mov ebx,[ebp+8]
    mov byte [eax],bl
    mov ebx,0
    mov dword [eax+1],ebx

    functionend
    ret

;the function cleans the stack 
empty_stack:

            functionstart
            pushad                  ; Save some more caller state
        .next:

            cmp dword [stack_pointer],0
            je empty
            my_pop
            push eax
            call free
            add esp,4
            jmp .next

        empty:
            popad                   ; Restore caller state (registers)
            mov     eax,0   ; place returned value where caller can see it
            pop     ebp             ; Restore caller state
            ret                     ; Back to caller
;the function takes an argumant out of the stack and print it on the screen
pop_and_print:
        functionstart
        pushad
        sub esp,12

        my_pop

        cmp dword eax,0 ; check if the pop function failed
        je pop_error
        mov [ebp-4],eax ;currlink
        mov [ebp-8],eax ;head
        mov dword [ebp-12],0 ;counter=0

        
    .term: 
        mov eax,[ebp-4]   
        mov ebx,0
        mov bl,[eax] ;get the first byte with the link value to ebx

        push ebx
        push formatpadHex

        inc dword [ebp-12] ;set on the stack each call to printf in reverse order
        
        mov eax,[ebp-4]
        cmp dword [eax+1],0
        je end_print_func ;if it is the last link,end the function

        mov eax,[eax+1] ; else: currlink = currlink.next
        mov [ebp-4],eax
        jmp .term


    end_print_func:
        add esp,4
        push formatHex ;the firs number is without padding

        print_list:
            call printf
            add esp,8
            dec dword [ebp-12]
            cmp dword [ebp-12],0
            jne print_list ; do each of the prints sepratly

        push newline
        call printf
        add esp,4

        push dword [ebp-8]
        call free_link
        add esp,4
    done:
    pop_error:

        inc dword [numOfOps]
        add esp,12
        popad
        functionend
        ret
;the function gets a pointer to a linked list and free its links
free_link:
        functionstart
        pushad
        sub esp,4

        mov eax,[ebp+8]
        mov [ebp-4],eax ;put the head on a local var

    free_next:
        mov eax,[ebp-4];eax = currlink
        mov ebx,[eax+1];ebx = currlink.next
        mov [ebp-4],ebx;save the next link on the local var

        push eax
        call free
        add esp,4 ; free the current link

        cmp dword [ebp-4],0 ;check if there is a next link
        jne free_next
        

        add esp,4
        popad
        functionend
        ret

;the function recieve a number and print it on the stderr file
print_number:
            functionstart
            sub     esp, 8          ; Leave space for two local var on stack
            pushad                  ; Save some more caller state
            
            mov eax,[ebp+8] ;eax = currlink
            mov [ebp-4],eax
            mov dword [ebp-8],0 ;counter = 0
        .next_link:
            mov eax,[ebp-4] ;eax = currlink
            mov ebx,[eax+1]
            mov [ebp-4],ebx ;currlink = currlink.next

            mov ebx,0   ;extraxct the value of the link
            mov byte bl,[eax]
            push ebx    ;keep it on the stack for later print
            push formatpadHex
            push dword [stderr]
            inc dword [ebp-8] ; counter ++
            cmp dword [ebp-4],0
            jne .next_link

            ;swtich the format of the first number for cosmetic reasons
            add esp,8
            push formatHex
            push dword [stderr]

        print_loop:
            call fprintf  ;print the links in reverse order
            add esp,12
            dec dword [ebp-8]
            jnz print_loop

            push newline
            push dword [stderr]
            call fprintf
            add esp,8


            popad                   ; Restore caller state (registers)
            mov     eax, [ebp-4]    ; place returned value where caller can see it
            add     esp, 8          ; Restore caller state
            pop     ebp             ; Restore caller state
            ret                     ; Back to caller

end:
    ;functionend
    functionend

