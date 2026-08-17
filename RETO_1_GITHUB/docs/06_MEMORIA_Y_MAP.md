# 06 — Memoria, vector table y archivo MAP

## 1. Memoria de programa

El mapa de enlace reporta:

```text
_vectors   0x08000000–0x08000187
baseclock  0x08000188–0x080001BB
GPIOconf   0x080001BC–0x080001EB
_start     0x080001EC–0x080003AF
```

El código de la aplicación se encuentra en Flash, comenzando en:

```text
0x08000000
```

## 2. Vector table

La tabla está alineada a 512 bytes:

```asm
.balign 512
_vectors:
```

La primera entrada corresponde al stack inicial.

La segunda corresponde a `Reset_Handler`.

Posteriormente aparecen las excepciones del Cortex-M.

`SysTick_Handler` aparece en la posición que corresponde a la excepción SysTick.

El mapa muestra:

```text
SysTick_Handler = 0x080002B7
```

Esto demuestra que el handler de la aplicación fue enlazado y no quedó sustituido por el handler débil.

---

## 3. Reset

El mapa ubica:

```text
Reset_Handler = 0x08000489
```

El flujo es:

```text
vector reset
    ↓
Reset_Handler
    ↓
_start
```

El archivo de startup llama finalmente:

```asm
bl _start
```

---

## 4. RAM

El proyecto reserva el stack en:

```text
0x2001F800–0x2001FFFF
```

con tamaño:

```text
2048 bytes
```

Las variables de la aplicación se encuentran manualmente desde:

```text
0x20000000
```

| Dirección | Variable |
|---:|---|
| `0x20000000` | CONTADOR |
| `0x20000004` | VERIFICAR |
| `0x20000008` | POSICION |
| `0x2000000C` | JUEGO |

Cada una ocupa una palabra de 32 bits.

## 5. Por qué no chocan con el stack

La separación es grande:

```text
Variables → comienzo de SRAM
Stack     → extremo superior de SRAM
```

Por eso, las cuatro palabras no se solapan con el bloque de stack reservado por el linker.

## 6. Código generado

El `.map` reporta:

| Objeto | Código |
|---|---:|
| `baseclock.o` | 52 B |
| `GPIOconf.o` | 48 B |
| `start.o` | 452 B |
| `stm32f407xx_Vectors.o` | 568 B |
| `STM32F4xx_Startup.o` | 60 B |
| **Total RX** | **1180 B** |

El código de aplicación (`start`, `baseclock`, `GPIOconf`) ocupa:

```text
452 + 52 + 48 = 552 bytes
```

Los demás bytes corresponden principalmente a startup y tabla de vectores.

---

## 7. Cómo defender un rastreo de ejecución

Ejemplo: entrada a `baseclock`.

```text
PC → baseclock
R0 → dirección de CSR
R1 → contenido previo de CSR
R2 → máscara
R3 → resultado
```

Después:

```text
RVR = 0x3E7F
CVR = 0
CSR = 0x07
```

Al finalizar:

```text
SysTick queda habilitado
```

Luego el hardware genera la excepción y:

```text
PC → SysTick_Handler
```

El handler incrementa las variables RAM.

---

## 8. Regla para preguntas de memoria

Si el docente pregunta:

> "¿Dónde está CONTADOR?"

Respuesta:

```text
0x20000000
```

Si pregunta:

> "¿Qué hay en 0x20000004?"

Respuesta:

```text
VERIFICAR
```

Si pregunta:

> "¿Dónde está SysTick_Handler?"

Respuesta:

```text
0x080002B7
```

Si pregunta:

> "¿Dónde está Reset_Handler?"

Respuesta:

```text
0x08000489
```

Estos valores salen del código fuente y del `.map`, no de una estimación.
