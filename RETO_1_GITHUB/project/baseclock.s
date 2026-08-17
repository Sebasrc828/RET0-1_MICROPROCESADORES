.syntax unified
.global baseclock
.global SysTick_Handler

.text

// Se define la ubicación de los registros para configurar el clock
.equ SYST_CSR, 0xE000E010 
.equ SYST_RVR, 0xE000E014
.equ SYST_CVR, 0xE000E018 

.thumb_func

baseclock:
        
        // Se asegura que el contador esté detenido (primer bit del registro en 0)
        MOV R0, 0x01
        LDR R1, =SYST_CSR
        LDR R2, [R1]
        BIC R3, R2, R0
        STR R3, [R1]
        
        // Se define el tiempo de conteo del reloj para SYST_RVR
        LDR R0, =0x3E7F //~1ms //0x270F ~ 10ms //=0x1869FF ~ 100ms
        LDR R1, =SYST_RVR
        STR R0, [R1]
        
        // Se revisa el valor actual del contador con R0 y se asegura un inicio en 0 ms
        LDR R0, =SYST_CVR
        MOV R1, #0
        STR R1, [R0]

        // Se definen los 3 primeros bits de CSR en 1 para asegurar el uso del reloj
        // del microprocesador como referencia, la excepción SysTick
        // para poder usar la función "SysTick" y se inicializa el contador
        LDR R0, =SYST_CSR
        MOV R1, #0x07
        STR R1, [R0]

        BX LR
