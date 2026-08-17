# 09 — Instrucciones clave de ARM Thumb-2

Esta hoja está pensada para defender modificaciones y rastreos de ejecución.

## `LDR`

### Carga desde memoria

```asm
LDR R1, [R0, #0x14]
```

Significa:

```text
R1 ← MEM[R0 + 0x14]
```

Si:

```text
R0 = 0x40020C00
```

entonces:

```text
R0 + 0x14 = 0x40020C14
```

que corresponde a `GPIOD_ODR`.

### Carga de una constante/dirección

```asm
LDR R0, =GPIOD_BASE
```

carga en R0 la dirección asociada a la constante ensamblada.

---

## `STR`

```asm
STR R3, [R0, #0x14]
```

significa:

```text
MEM[R0 + 0x14] ← R3
```

Se usa para escribir registros periféricos o variables RAM.

---

## `MOV`

```asm
MOV R2, #1
```

carga:

```text
R2 = 0x00000001
```

Para construir máscaras mayores:

```asm
LSL R2, R2, #3
```

produce:

```text
0x01 << 3 = 0x08
```

---

## `ORR`

```asm
ORR R3, R1, R2
```

equivale a:

```text
R3 = R1 OR R2
```

Uso:

- habilitar bits;
- encender LEDs;
- combinar máscaras.

---

## `BIC`

```asm
BIC R3, R1, R4
```

equivale a:

```text
R3 = R1 AND NOT R4
```

Uso:

- apagar LEDs;
- limpiar bits de configuración.

---

## `AND / ANDS`

```asm
ANDS R3, R1, R8
```

equivale a:

```text
R3 = R1 AND R8
```

Además actualiza las banderas del procesador.

Para el botón:

```text
R8 = 0x1
```

por lo que solo se conserva PA0.

---

## `EOR`

```asm
EOR R1, R1, R8
```

equivale a:

```text
R1 = R1 XOR R8
```

Se usa para invertir el estado del LED.

---

## `LSL`

```asm
LSL R8, R8, R3
```

si:

```text
R8 = 1
R3 = POSICION
```

entonces:

```text
R8 = 1 << POSICION
```

Ejemplos:

```text
POSICION = 0 → 0x01
POSICION = 1 → 0x02
POSICION = 2 → 0x04
POSICION = 3 → 0x08
POSICION = 4 → 0x10
```

---

## `CMP`

```asm
CMP R1, R5
```

realiza una comparación usando una resta conceptual:

```text
R1 - R5
```

y actualiza las banderas.

Después:

```asm
BNE tiempo
```

significa:

```text
Branch if Not Equal
```

es decir, repetir mientras no sean iguales.

---

## `BL`

```asm
BL GPIOconf
```

hace una llamada y guarda la dirección de retorno en `LR`.

La rutina retorna con:

```asm
BX LR
```

---

## `B`

```asm
B loop
```

realiza un salto incondicional.

---

## `BEQ`

```asm
BEQ RESULTADO
```

salta cuando la comparación anterior produjo igualdad (`Z = 1`).

---

## `BNE`

```asm
BNE loop
```

salta cuando la comparación anterior produjo desigualdad (`Z = 0`).

---

## `BX LR`

Retorna a la dirección almacenada en `LR`.

Es la salida normal de las funciones llamadas usando `BL`.

---

# 2. Ejemplo de rastreo

Supongamos:

```text
GPIOD_ODR = 0x00000002
R2 = 0x00000004
```

Se ejecuta:

```asm
ORR R3, R1, R2
```

Resultado:

```text
0x02 OR 0x04
= 0x06
```

Entonces:

```asm
STR R3, [R0, #0x14]
```

escribe:

```text
GPIOD_ODR = 0x00000006
```

Si luego se ejecuta:

```asm
BIC R3, R1, R4
```

con:

```text
R1 = 0x06
R4 = 0x02
```

entonces:

```text
0x06 AND NOT 0x02
= 0x04
```

Resultado:

```text
GPIOD_ODR = 0x04
```

Este es exactamente el razonamiento que se debe aplicar durante un rastreo en vivo.
