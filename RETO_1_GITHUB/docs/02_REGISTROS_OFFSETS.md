# 02 — Registros, direcciones base, offsets y máscaras

## 1. Regla de dirección efectiva

Para los periféricos STM32 se utiliza:

```text
Dirección efectiva = Dirección base + Offset
```

Ejemplo:

```text
RCC_BASE = 0x40023800
Offset   = 0x30

RCC_AHB1ENR = 0x40023800 + 0x30
            = 0x40023830
```

---

## 2. Tabla principal

| Periférico | Registro | Base | Offset | Dirección | Uso |
|---|---|---:|---:|---:|---|
| RCC | AHB1ENR | `0x40023800` | `0x30` | `0x40023830` | Clock de GPIOA/GPIOD |
| GPIOA | MODER | `0x40020000` | `0x00` | `0x40020000` | PA0 entrada |
| GPIOA | IDR | `0x40020000` | `0x10` | `0x40020010` | Leer botón |
| GPIOD | MODER | `0x40020C00` | `0x00` | `0x40020C00` | Configurar salidas |
| GPIOD | ODR | `0x40020C00` | `0x14` | `0x40020C14` | LEDs |
| SysTick | CSR | `—` | `—` | `0xE000E010` | Control/estado |
| SysTick | RVR | `—` | `—` | `0xE000E014` | Recarga |
| SysTick | CVR | `—` | `—` | `0xE000E018` | Valor actual |

---

## 3. RCC_AHB1ENR

Código:

```asm
LDR R0, =RCC_BASE
LDR R1, [R0, #RCC_AHB1ENR_OFFSET]
MOV R2, 0x01
...
ORR R3, R1, R2
STR R3, [R0, #RCC_AHB1ENR_OFFSET]
```

### GPIOA

```text
GPIOAEN = bit 0
máscara = 0x00000001
```

### GPIOD

```asm
MOV R2, 0x01
LSL R2, R2, #3
```

Resultado:

```text
0x01 << 3 = 0x08
```

Por eso:

```text
GPIOAEN | GPIODEN
0x01    | 0x08
= 0x09
```

Esta operación conserva los demás bits de `AHB1ENR`.

---

## 4. GPIOA_MODER

Dirección:

```text
0x40020000
```

PA0 usa los bits:

```text
MODER[1:0]
```

Modo entrada:

```text
00
```

La rutina utiliza:

```asm
MOV R2, #1
BIC R3, R1, R2
```

Esto elimina el bit 0.

Con reset del registro en cero, el par `[1:0]` queda `00`.

> Esta operación no necesita escribir todo el registro desde cero porque `BIC` sirve para conservar los bits no afectados.

---

## 5. GPIOA_IDR

Dirección:

```text
0x40020010
```

Lectura:

```asm
LDR R1, [R0, #GPIOx_IDR_OFFSET]
MOV R8, #1
ANDS R3, R1, R8
```

Matemáticamente:

```text
R3 = IDR AND 0x00000001
```

Solo queda:

```text
0 → botón no activo
1 → botón activo
```

según la polaridad física del montaje.

---

## 6. GPIOD_MODER

Dirección:

```text
0x40020C00
```

Cada pin usa dos bits.

Para configurar PD0–PD8 como salida se necesita:

```text
PD0 → 01
PD1 → 01
PD2 → 01
...
PD8 → 01
```

La máscara construida por `GPIOconf` es:

```text
bit 0
bit 2
bit 4
bit 6
bit 8
bit 10
bit 12
bit 14
bit 16
```

Resultado:

```text
0x00015555
```

En binario:

```text
0000 0000 0000 0001 0101 0101 0101 0101
```

El segundo bit de cada par permanece en cero.

---

## 7. GPIOD_ODR

Dirección:

```text
0x40020C14
```

`ODR` controla la salida digital.

### Apagar un LED

```asm
BIC R3, R1, R4
```

Equivale a:

```text
ODR_nuevo = ODR_actual AND NOT máscara
```

### Encender un LED

```asm
ORR R3, R1, R2
```

Equivale a:

```text
ODR_nuevo = ODR_actual OR máscara
```

### Toggle

En `RESULTADO`:

```asm
EOR R1, R1, R8
```

Equivale a:

```text
ODR_nuevo = ODR_actual XOR máscara
```

---

## 8. SysTick_CSR

Dirección:

```text
0xE000E010
```

Se escribe:

```asm
MOV R1, #0x07
STR R1, [R0]
```

Bits:

```text
bit 0 ENABLE    = 1
bit 1 TICKINT   = 1
bit 2 CLKSOURCE = 1
```

Interpretación:

- SysTick habilitado.
- Interrupción habilitada.
- Fuente de reloj del procesador seleccionada.

---

## 9. SysTick_RVR

Dirección:

```text
0xE000E014
```

Valor:

```text
0x3E7F = 15999
```

El contador recarga desde 15999 hasta 0.

Con 16 MHz:

```text
(15999 + 1) / 16 000 000
= 1 ms
```

---

## 10. SysTick_CVR

Dirección:

```text
0xE000E018
```

Se escribe:

```asm
MOV R1, #0
STR R1, [R0]
```

Esto fuerza el contador actual a cero antes de habilitar SysTick.

---

## 11. Tabla de valores de referencia

| Registro | Valor/máscara | Justificación |
|---|---:|---|
| `RCC_AHB1ENR` | `...0009` | habilita GPIOA y GPIOD |
| `GPIOA_MODER` | PA0 `[1:0]=00` | entrada |
| `GPIOD_MODER` | `0x00015555` | PD0–PD8 en `01` |
| `SysTick_RVR` | `0x00003E7F` | 1 ms a 16 MHz |
| `SysTick_CVR` | `0x00000000` | inicio conocido |
| `SysTick_CSR` | `0x00000007` | enable + interrupt + processor clock |
| `IDR` máscara | `0x00000001` | PA0 |
| LED toggle | `1 << POSICION` | selecciona un bit |

El valor exacto de `RCC_AHB1ENR` debe entenderse como:

```text
RCC_AHB1ENR_final = RCC_AHB1ENR_previo OR 0x00000009
```

No hay que afirmar que la instrucción siempre escribe `0x00000009` independientemente del estado previo.
