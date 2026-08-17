        .syntax unified
        .global _start
        .global GPIOset
        .text



        .thumb_func

GPIOset:
        
        MOV R4, #0
        MOV R2, #1
        ORR R3, R1, R2