# 07 — Guía de sustentación oral y Q&A

## 1. Preguntas fundamentales

### ¿Qué procesador estás utilizando?

STM32F407VE con núcleo ARM Cortex-M4, arquitectura ARMv7E-M y ejecución Thumb-2.

### ¿Qué significa bare-metal?

Que la aplicación interactúa directamente con los registros del microcontrolador usando direcciones de memoria, sin utilizar HAL o bibliotecas de abstracción para realizar la configuración principal.

### ¿Cómo habilitas GPIOA?

Se accede a:

```text
RCC_AHB1ENR = 0x40023830
```

y se activa:

```text
bit 0 = GPIOAEN
```

con una operación `ORR`.

### ¿Cómo habilitas GPIOD?

Se activa:

```text
bit 3 = GPIODEN
```

La máscara es:

```text
1 << 3 = 0x08
```

### ¿Qué valor combinado utilizas?

```text
0x01 | 0x08 = 0x09
```

---

## 2. Preguntas sobre MODER

### ¿Por qué cada GPIO utiliza dos bits?

Porque `MODER` asigna un campo de dos bits por pin.

```text
00 Input
01 Output
10 Alternate Function
11 Analog
```

### ¿Por qué `0x15555`?

Porque coloca un `1` en el bit bajo de cada par:

```text
01 01 01 01 01 01 01 01 01
```

para PD0–PD8.

### ¿Qué hace BIC?

`BIC Rd, Rn, Rm` equivale a:

```text
Rd = Rn AND NOT Rm
```

Es apropiado cuando se desea limpiar bits sin alterar los demás.

---

## 3. Preguntas sobre SysTick

### ¿Por qué 0x3E7F?

```text
0x3E7F = 15999
15999 + 1 = 16000
16000 / 16 MHz = 1 ms
```

### ¿Qué hace CSR = 0x07?

```text
bit 0 = ENABLE
bit 1 = TICKINT
bit 2 = CLKSOURCE
```

Los tres están en uno.

### ¿Por qué escribes cero en CVR?

Para iniciar el conteo desde un estado conocido antes de habilitar SysTick.

### ¿Cada cuánto ocurre la interrupción?

Aproximadamente cada:

```text
1 ms
```

---

## 4. Preguntas sobre interrupciones

### ¿SysTick se usa por polling?

Respuesta exacta:

> El evento temporal lo genera SysTick usando interrupción. El handler incrementa contadores en RAM. Después, el programa principal hace polling sobre esos contadores. No se consulta directamente COUNTFLAG.

### ¿Dónde está el vector?

En la tabla de vectores ubicada desde:

```text
0x08000000
```

El handler enlazado aparece en el `.map` en:

```text
0x080002B7
```

---

## 5. Preguntas sobre el botón

### ¿Cómo detectas PA0?

Se lee:

```text
GPIOA_IDR = 0x40020010
```

y se aplica:

```text
AND 0x00000001
```

### ¿Qué pasa si el botón no está presionado?

La rutina no activa `JUEGO` y retorna al flujo normal.

### ¿Cómo haces debounce?

Respuesta técnicamente precisa:

> No hay un debounce clásico por confirmación de múltiples muestras. El botón se muestrea cada 100 ms, lo cual actúa como un filtro temporal de rebotes rápidos.

---

## 6. Preguntas sobre máscaras

### ¿Por qué usas ORR para encender?

Porque:

```text
x OR 1 = 1
```

sin modificar los bits donde la máscara tiene cero.

### ¿Por qué BIC para apagar?

Porque:

```text
x AND NOT 1 = 0
```

y los bits no seleccionados permanecen iguales.

### ¿Por qué EOR para parpadear?

Porque:

```text
0 XOR 1 = 1
1 XOR 1 = 0
```

Cada operación invierte el bit seleccionado.

---

## 7. Modificación en vivo

### Cambiar velocidad del barrido

Actualmente:

```asm
MOV R5, #50
```

Modificar a:

```asm
MOV R5, #100
```

produce:

```text
100 × 1 ms = 100 ms
```

### Cambiar muestreo del botón

Actualmente:

```asm
MOV R5, #100
```

en `tiempo1`.

Cambiar a:

```asm
MOV R5, #200
```

produce:

```text
200 ms
```

entre muestras.

### Cambiar SysTick a 10 ms

Con 16 MHz:

```text
N = 0.010 × 16 000 000
  = 160000
```

Entonces:

```text
RVR = 160000 - 1
    = 159999
    = 0x0270FF
```

Por eso:

```asm
LDR R0, =0x0270FF
```

### Cambiar SysTick a 100 ms

```text
N = 0.100 × 16 000 000
  = 1 600 000
```

```text
RVR = 1 599 999
    = 0x1869FF
```

---

## 8. Preguntas de rastreo

### ¿Qué pasa con R2 en GPIOH?

`R2` contiene una máscara de un bit y se desplaza:

```asm
LSL R2, R2, #1
```

antes de hacer `ORR`.

### ¿Qué pasa con R4 en GPIOL?

Representa la máscara del LED que se va a apagar y también se desplaza una posición.

### ¿Qué representa R7?

Es un contador/índice utilizado para registrar la posición del barrido.

### ¿Qué representa POSICION?

Es la copia de R7 almacenada en RAM para que el modo resultado pueda conocer la posición en la que se detectó el botón.

---

## 9. Pregunta difícil: ¿por qué no utilizaste ODR directamente con un valor fijo?

Respuesta:

> Porque las operaciones de máscara permiten modificar únicamente el bit asociado al LED sin sobrescribir el resto del puerto. Esto facilita el barrido y evita depender de escrituras completas con valores hardcodeados.

---

## 10. Pregunta difícil: ¿qué problema tendría escribir todo ODR?

Una escritura directa podría alterar otros bits del puerto si fueran utilizados por otros periféricos o señales. El uso de máscaras reduce ese riesgo.

---

## 11. Pregunta difícil: ¿por qué no utilizaste NOP?

Respuesta:

> Un retardo usando NOP depende directamente del número de instrucciones ejecutadas y de la frecuencia de CPU, también de ser menos flexible. SysTick proporciona una referencia temporal explícita y reutilizable.

---

## 12. Pregunta crítica sobre la implementación

Si el docente pregunta:

> "¿Tu código realmente implementa ocho LEDs?"

La respuesta debe partir del hardware real.

El código configura PD0–PD8, nueve pines, aunque el reto habla de ocho LEDs. Además, la rutina desplaza las máscaras antes de algunas operaciones. Por ello es necesario demostrar físicamente la correspondencia entre LED y pin.

No conviene negar esta diferencia si el montaje muestra otra cosa.

---

## 13. Pregunta crítica sobre `GPIOset.s`

Respuesta:

> `GPIOset.s` pertenece al material original, pero no está incluido en la lista de archivos fuente del proyecto enlazado y su función está incompleta. La aplicación funcional utiliza `start.s`, `baseclock.s` y `GPIOconf.s`.

---

## 14. Pregunta crítica sobre `baseclock`

No decir:

> "Aquí configuro el clock interno a 16 MHz."

La afirmación precisa es:

> "Aquí configuro SysTick usando la frecuencia de reloj del procesador disponible en el sistema. Este archivo no modifica RCC para seleccionar una fuente o cambiar la frecuencia del sistema."

---

## 15. Respuesta de 30 segundos

> El sistema está implementado en ensamblador Thumb-2 sobre un Cortex-M4 STM32F407VE. Primero se configura SysTick para generar un tick de 1 ms usando un valor de recarga de 0x3E7F con una frecuencia de 16 MHz. Luego se habilitan GPIOA y GPIOD usando RCC_AHB1ENR, se configura PA0 como entrada y se construye la máscara 0x15555 para las salidas de GPIOD. El SysTick_Handler incrementa dos contadores en RAM: uno para el barrido y otro para el muestreo del botón. El programa principal hace polling de esos contadores, controla los LEDs usando ORR/BIC y lee PA0 usando AND. Cuando detecta una pulsación, activa JUEGO y entra al modo resultado, donde usa EOR para hacer toggle del LED que corresponde.
