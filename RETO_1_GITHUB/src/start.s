/*********************************************************************
*                    SEGGER Microcontroller GmbH                     *
*                        The Embedded Experts                        *
**********************************************************************
*                                                                    *
*            (c) 2014 - 2024 SEGGER Microcontroller GmbH             *
*                                                                    *
*       www.segger.com     Support: support@segger.com               *
*                                                                    *
**********************************************************************
*                                                                    *
* All rights reserved.                                               *
*                                                                    *
* Redistribution and use in source and binary forms, with or         *
* without modification, are permitted provided that the following    *
* condition is met:                                                  *
*                                                                    *
* - Redistributions of source code must retain the above copyright   *
*   notice, this condition and the following disclaimer.             *
*                                                                    *
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND             *
* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,        *
* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF           *
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE           *
* DISCLAIMED. IN NO EVENT SHALL SEGGER Microcontroller BE LIABLE FOR *
* ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR           *
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT  *
* OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;    *
* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF      *
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT          *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE  *
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH   *
* DAMAGE.                                                            *
*                                                                    *
*********************************************************************/

/*********************************************************************
*
*       _start
*
*  Function description
*  Defines entry point for an STM32F4xx assembly code only
*  application.
*
*  Additional information
*    Please note, as this is an assembly code only project, the C/C++
*    runtime library has not been initialised. So do not attempt to call
*    any C/C++ library functions because they probably won't work.
*/

        .syntax unified
        .global _start
        .global SysTick_Handler
        .text
        
        // Aqui se define la dirección de memoria para habilitar los puertos GPIO
        .equ RCC_BASE, 0x40023800
        .equ RCC_AHB1ENR_OFFSET, 0x30
        
        // Aqui se define la dirección de memoria del GPIO a usar con los diferentes
        // offsets para activar y usar los pines.
        .equ GPIOA_BASE, 0x40020000
        .equ GPIOD_BASE, 0x40020C00
        .equ GPIOx_MODER_OFFSET, 0x00
        .equ GPIOx_ODR_OFFSET, 0x14 
        .equ GPIOx_IDR_OFFSET, 0x10
        
        // Aqui se define la dirección de memoria del contador para el temporizador
        .equ CONTADOR, 0x20000000
        .equ VERIFICAR, 0X20000004

        // Aqui se define la dirección de memoria para guardar la posición del led y el estado del juego
        // (si se oprimió el botón o si sigue en el loop).
        .equ POSICION, 0x20000008
        .equ JUEGO, 0x2000000C 

        .thumb_func

_start:
        
        //Se configura el reloj interno del microprocesador STM32F407vetex
        BL baseclock
        
        // Se verifica que el contador en base al clock tenga como valor inicial 0.
        LDR R0, =CONTADOR
        MOV R1, #0
        STR R1, [R0]

        LDR R0, =VERIFICAR
        MOV R1, #0
        STR R1, [R0]

        // Se verifica que  no haya información "basura" en estos espacios de memoria
        LDR R0, =POSICION
        MOV R1, #0
        STR R1, [R0]

        LDR R0, =JUEGO
        MOV R1, #0
        STR R1, [R0]

        //Se habilita GPIOAEN (bit 0) del registro RCC_AHB1ENR
        LDR R0, =RCC_BASE
        LDR R1, [R0, #RCC_AHB1ENR_OFFSET]
        MOV R2, 0x01
        ORR R3, R1, R2
        STR R3, [R0, #RCC_AHB1ENR_OFFSET]

        // Se habilita el pin GPIOA 0 como entrada
        LDR R0, =GPIOA_BASE
        LDR R1, [R0, #GPIOx_MODER_OFFSET]
        MOV R2, #1
        BIC R3, R1, R2
        STR R3, [R0, #GPIOx_MODER_OFFSET]

        
        //PINES DE LEDS: 1:1 = 9,13 - 1:2 = 9,3 - 1:3 = 9,4 
        //               1:4 = 9,10 - 1:5 = 9,6 - 1:6 = 9,11 
        //               1:7 = 9,15 - 1:8 = 9,16
        // Estos pines están conectados con los pines del microprocesador PD0-8

        //Se habilita GPIODEN (bit 3) del registro RCC_AHB1ENR
        LDR R0, =RCC_BASE
        LDR R1, [R0, #RCC_AHB1ENR_OFFSET]
        MOV R2, 0x01
        LSL R2, R2, #3
        ORR R3, R1, R2
        STR R3, [R0, #RCC_AHB1ENR_OFFSET]

        //Habilitar los pines GPIOD 0 - 8 (Bits #0 hasta #17) como OUTPUT (par de bit = 01)

        LDR R0, =GPIOD_BASE
        LDR R1, [R0, #GPIOx_MODER_OFFSET]
        BL GPIOconf
        ORR R6, R6, R1
        STR R6, [R0, #GPIOx_MODER_OFFSET]
        
        //Estado inicial de los LEDs en el GPIOD (0 - 8) apagado
        MOV R2, #1
        MOV R4, #0
        
        APAGADO:
                LDR R0, =GPIOD_BASE
                LDR R1, [R0, #GPIOx_ODR_OFFSET]
                BIC R3, R1, R2 
                LSL R2, R2, #1
                STR R3, [R0, #GPIOx_ODR_OFFSET]

                ADD R4, R4, #1
                CMP R4, #8
                BNE APAGADO

        // Se declaran las banderas y contadores (que no se usarán para un tiempo específico) a
        // usar dentro del loop.
        MOV R2, #1
        MOV R4, #1
        MOV R7, #0

loop:
        
        // Se revisa si hay que cambiar a modo resultado o seguir en modo loop
        LDR R0, =JUEGO
        LDR R1, [R0]
        CMP R1, #1
        BEQ RESULTADO

        // Se enciende y apagan 1 por 1 los leds de la matríz a modo de secuencia.
        BL GPIOH
        BL GPIOL
        
        // Contador a base del clock para ejecutar lectura del botón cada x ms.
        tiempo1:
                LDR R0, =VERIFICAR
                LDR R1, [R0]
                MOV R5, #100
                CMP R1, R5
                BNE tiempo1

        // Aqui se lee el estado del botón
        BL Botón

        // Se vuelve a poner en cero el contador para el botón
        LDR R0, =VERIFICAR
        MOV R1, #0
        STR R1, [R0]

        // Contador a base del clock para ejecutar la secuencia de la matríz de leds cada x ms.
        tiempo:

                LDR R0, =CONTADOR
                LDR R1, [R0]
                MOV R5, #50
                CMP R1, R5
                BNE tiempo

                // Se vuelve a poner en cero el contador para la secuencia de la matríz de leds.
                MOV R1, #0
                STR R1, [R0]

        b       loop


.thumb_func

// Función para incrementa el contador en base al clock (cada 1ms adiciona un 1 al contador).
SysTick_Handler:

        LDR R0, =CONTADOR
        LDR R1, [R0]
        ADD R1, R1, #1
        STR R1, [R0]
        
        LDR R0, =VERIFICAR
        LDR R1, [R0]
        ADD R1, R1, #1
        STR R1, [R0]

        BX LR

// Función para permite el encendido de un solo led de la matríz
GPIOH:
        LDR R0, =GPIOD_BASE
        LDR R1, [R0, #GPIOx_ODR_OFFSET]
        LSL R2, R2, #1
        ORR R3, R1, R2
        STR R3, [R0, #GPIOx_ODR_OFFSET]
        
        BX LR      

// Función para permite el apagado de un solo led de la matríz.
GPIOL:
        LDR R0, =GPIOD_BASE
        LDR R1, [R0, #GPIOx_ODR_OFFSET]
        BIC R3, R1, R4 
        LSL R4, R4, #1
        STR R3, [R0, #GPIOx_ODR_OFFSET]
        
        //Contador que permite saber cuándo reiniciar las banderas y este mismo contador.
        ADD R7, R7, #1

        // Se guarda la posición actual del led
        LDR R0, =POSICION
        STR R7, [R0]

        CMP R7, #9
        BEQ reinicio

        BX LR

// Función de reinicio de banderas, posición del led, contador y que apaga el último led.
reinicio:
        
        LDR R0, =GPIOD_BASE
        LDR R1, [R0, #GPIOx_ODR_OFFSET]
        BIC R3, R1, R4 
        STR R3, [R0, #GPIOx_ODR_OFFSET]

        MOV R2, #1
        MOV R4, #1
        MOV R7, #0

        LDR R0, =POSICION
        MOV R1, #0
        STR R1, [R0]

        BX LR

// Función para lee el botón
Botón:
        
        // Se revisa si el botón fue oprimido, si no sigue el loop
        LDR R0, =GPIOA_BASE
        LDR R1, [R0, #GPIOx_IDR_OFFSET]
        MOV R8, #1
        ANDS R3, R1, R8
        
        // Se vuelve a poner en cero el contador para el botón
        LDR R0, =VERIFICAR
        MOV R1, #0
        STR R1, [R0]

        // Se vuelve a poner en cero el contador para la secuencia de la matríz de leds.
        LDR R0, =CONTADOR
        MOV R1, #0
        STR R1, [R0]


        CMP R3, #1
        BNE loop
        
        // Se actualiza el estado del juego.
        LDR R0, =JUEGO
        MOV R1, #1
        STR R1, [R0]

        BX LR

RESULTADO:

        // Decide velocidad de parpadeo según la posición congelada
        LDR R0, =POSICION
        LDR R1, [R0]
        CMP R1, #4
        BEQ lento
        CMP R1, #5
        BEQ lento

        MOV R5, #300              // parpadeo RÁPIDO: cada 5 ticks
        B   espera_blink

lento:
        MOV R5, #50              // parpadeo LENTO: cada 10 ticks (~1 segundo si tick=100ms)


espera_blink:
        LDR R0, =CONTADOR
        LDR R1, [R0]
        CMP R1, R5
        BNE RESULTADO

        // Invierte (toggle) el LED que quedó encendido
        LDR R0, =GPIOD_BASE
        LDR R1, [R0, #GPIOx_ODR_OFFSET]
        LDR R8, =POSICION
        LDR R3, [R8]
        MOV R8, #1
        LSL R8, R8, R3
        EOR R1, R1, R8
        STR R1, [R0, #GPIOx_ODR_OFFSET]

        // Reinicia el contador de tiempo para el próximo parpadeo
        LDR R0, =CONTADOR
        MOV R1, #0
        STR R1, [R0]

        B   loop      