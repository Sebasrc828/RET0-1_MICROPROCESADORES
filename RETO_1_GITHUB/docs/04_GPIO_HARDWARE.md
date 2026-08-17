# 04 — GPIO y hardware

## 1. Mapa lógico

```mermaid
flowchart LR
    BTN[Pulsador] --> PA0[GPIOA PA0 / IDR0]
    PA0 --> CPU[Cortex-M4]
    CPU --> ODR[GPIOD ODR]
    ODR --> L[Banco de LEDs]
```

## 2. GPIOA — pulsador

Base:

```text
0x40020000
```

Registro de modo:

```text
MODER = 0x40020000
```

Entrada:

```text
PA0 MODER[1:0] = 00
```

Lectura:

```text
IDR = 0x40020010
```

Máscara:

```text
0x00000001
```

El programa ejecuta:

```text
IDR & 0x00000001
```

para aislar PA0.

---

## 3. GPIOD — LEDs

Base:

```text
0x40020C00
```

Modo:

```text
MODER = 0x40020C00
```

Salida:

```text
ODR = 0x40020C14
```

La rutina `GPIOconf` prepara:

```text
0x00015555
```

para los pares de bits que corresponden a PD0–PD8.

---

## 4. Secuencia de máscaras

La idea de las rutinas es trabajar con máscaras de un solo bit.

Ejemplo:

```text
0000 0001 = 0x01
0000 0010 = 0x02
0000 0100 = 0x04
0000 1000 = 0x08
...
```

Desplazamiento:

```asm
LSL Rn, Rn, #1
```

equivale a:

```text
Rn = Rn << 1
```

Cada desplazamiento mueve la posición de la máscara al siguiente bit.

---

## 5. Encendido

`GPIOH` utiliza:

```asm
ORR R3, R1, R2
```

Esta operación:

```text
ODR_new = ODR_old | LED_mask
```

pone en 1 el bit seleccionado.

---

## 6. Apagado

`GPIOL` utiliza:

```asm
BIC R3, R1, R4
```

Equivalente:

```text
ODR_new = ODR_old & ~LED_mask
```

Así se limpia el LED anterior sin tener que escribir cero en todos los demás bits.

---

## 7. Toggle

El resultado utiliza:

```asm
EOR R1, R1, R8
```

Si:

```text
LED = 1
mask = 1
```

entonces:

```text
1 XOR 1 = 0
```

Si:

```text
LED = 0
mask = 1
```

entonces:

```text
0 XOR 1 = 1
```

Esto sirve para implementar el parpadeo.

---

## 8. Observación sobre ocho LEDs

El código configura **PD0–PD8**, nueve pines:

```text
PD0
PD1
PD2
PD3
PD4
PD5
PD6
PD7
PD8
```

Aunque, el reto se describe como un barrido de ocho LEDs.

Además, las máscaras de `GPIOH` y `GPIOL` comienzan con desplazamientos antes de la operación, por lo que la primera máscara efectiva no coincide simplemente con PD0.

Esto debe verificarse con el montaje físico antes de la entrega final.

### Recomendación de sustentación

Si el hardware realmente tiene ocho LEDs, llevar una tabla física exacta:

| LED físico | Pin MCU | Bit ODR |
|---|---|---:|
| LED 1 | confirmar | confirmar |
| LED 2 | confirmar | confirmar |
| LED 3 | confirmar | confirmar |
| LED 4 | confirmar | confirmar |
| LED 5 | confirmar | confirmar |
| LED 6 | confirmar | confirmar |
| LED 7 | confirmar | confirmar |
| LED 8 | confirmar | confirmar |

No hay que inventar esta asignación: debe coincidir con el cableado real.

---

## 9. Resistencias

Cada LED debe tener su resistencia limitadora de corriente que corresponde.

La resistencia no se reemplaza por software: protege el LED y limita la corriente del GPIO.

La revisión visual del montaje debe comprobar:

- orientación correcta del LED;
- resistencia en serie;
- masa/VCC según la polaridad del circuito;
- cables cortos;
- banco de LEDs alineado;
- pulsador accesible;
- ausencia de cortocircuitos entre filas de protoboard.
