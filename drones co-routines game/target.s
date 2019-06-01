section .text
global target_main
extern create_target
extern resume
extern scheduler

target_main:
call create_target
mov ebx,scheduler
call resume
jmp target_main

