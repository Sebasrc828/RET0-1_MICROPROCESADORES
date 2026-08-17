        .syntax unified
        .global _start
        .global GPIOconf
        .text        
        
        .equ TEMP, 0x20000004 // Se declara un espacio de memoria a usar temporalmente

        .thumb_func
        


// En esta parte se configuran en este caso los bits del 0 al 17 del pin PD0 al PD8 como salidas
GPIOconf:

        // Primero se inicializa la bandera
        MOV R4, #1

        // Se Limpia el valor en R2 correspondiente al valor en TEMP
        MOV R5, #0
        LDR R2, =TEMP        
        STR R5, [R2]
        
        // Se recorre el número de puertos a activar como salidas
        GPIOsave:

        LDR R2, =TEMP
        LDR R3, [R2]      
        ORR R6, R3, R4 // como las salidas deben de tener el primer bit en 1 y el segundo en 0,
        LSL R4, R4, #2 //  se coloca un 1 cada 2 bits (los bits pares).  
        STR R6, [R2]

        // Se incrementa el contador
        ADD R5, R5, #1

        // Si el contador es igual al número de puertos de salida deseados, salir del bucle
        CMP R5, #9
        BNE GPIOsave
        
        // Los pines por defecto son entradas, por lo que cualquier pin
        // no configurado se lee como entrada (es recomendable igual verificar
        // o asegurar para pines usados como entrada).

        // Se limpia el registro de memoria usado ya que en el registro 6
        // justo al salir de la función, queda guardado el valor que debe de llevar el MODER
        MOV R5, #0
        STR R5, [R2]

        BX LR