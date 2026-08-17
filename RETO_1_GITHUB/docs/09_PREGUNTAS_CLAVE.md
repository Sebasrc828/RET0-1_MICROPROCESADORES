# 10 — Preguntas clave del proceso de desarrollo

En este documento se resumen las dudas y preguntas planteadas durante la construcción del
proyecto, agrupadas por tema, junto con el punto clave que cada una resolvió. No
sustituye a los documentos técnicos anteriores - es un mapa de **cómo** se llegó a
las decisiones que ahí se explican, útil como bitácora de aprendizaje y como apoyo
rápido de cara a la sustentación.

---

## 1. Configuración del reloj (SysTick)

**Preguntas:** cómo terminar la configuración de `SYST_CSR` tras asegurar el 0
inicial; cómo guardar un valor de recarga que no cabe en un inmediato de 8 bits
(`0x1869FF`); por qué el `CSR` se escribe primero en 0 y después en su valor final.

**Punto clave:** la secuencia de inicialización de SysTick tiene un orden
obligatorio - apagar (`CSR=0`) → cargar `RVR` → limpiar `CVR` → encender con la
configuración final (`CSR=0x07`). Cargar un inmediato grande necesita `LDR Rd,
=valor` (vía literal pool) en vez de `MOV`/`MOVS`, que solo admite 8 bits en Thumb.

## 2. Organización del proyecto en múltiples archivos

**Preguntas:** cómo incluir `baseclock` desde `start.s` (error *"can't open
baseclock for reading"*); cómo evitar los errores de *"symbol already defined"* al
tener `baseclock.s` agregado al proyecto y también incluido con `.include`.

**Punto clave:** diferencia entre **`.include`** (pega el texto del archivo antes
de ensamblar - solo debe usarse si el archivo NO está agregado por separado al
proyecto) y **`.extern`/`.global`** (declara que un símbolo se resuelve en tiempo
de enlazado - es el método correcto cuando cada archivo se ensambla de forma
independiente, como terminó estructurado este proyecto).

## 3. SysTick_Handler y CMSIS

**Preguntas:** si `SysTick_Handler` es una función que ya existe; por qué el
nombre debe coincidir exactamente; qué relación tiene con la tabla de vectores.

**Punto clave:** con CMSIS, `SysTick_Handler` existe como símbolo **weak** en el
archivo de arranque, ya enlazado en la tabla de vectores. Basta con declarar una
función con el mismo nombre exacto (mayúsculas incluidas) para que el enlazador la
sustituya automáticamente - no es necesario tocar la tabla de vectores a mano.

## 4. Variables en RAM (`.bss` vs. dirección fija)

**Preguntas:** cómo declarar una variable tipo contador que persista en RAM; qué
hace cada línea de una declaración en `.bss` (`.section`, `.align`, la etiqueta, el
`.word`); por qué usar una dirección fija (`0x20000000`) en vez de dejar que el
enlazador la ubique.

**Punto clave:** ambas vías son válidas. `.bss` delega la ubicación al enlazador y
se inicializa en 0 automáticamente en el arranque; una dirección fija exige
inicializarla manualmente en el código (de lo contrario conserva valores
residuales de ejecuciones o usos previos de esa zona de RAM), pero da control
total y facilita la inspección directa en la ventana de memoria del depurador.

## 5. Depuración de errores de ensamblado y de lógica

**Preguntas:** el error `T32_OFFSET_IMM`; por qué el contador no se reiniciaba; por
qué el LED no cambiaba de estado o parpadeaba demasiado rápido; por qué el `MODER`
de un puerto no cambiaba al escribirlo.

**Puntos clave:**
- `T32_OFFSET_IMM` aparece al usar una etiqueta directamente como offset inmediato
  en vez de cargarla primero con `LDR Rd, =etiqueta`.
- Encender y apagar un pin en la misma rutina dentro de un handler nunca produce
  parpadeo visible: se necesita **invertir el estado** (`EOR`) para que persista
  hasta la siguiente interrupción.
- Un registro periférico que no cambia al escribirlo casi siempre indica que su
  bus (`RCC_AHB1ENR`/`RCC_APB2ENR` según el periférico) no está habilitado - la
  escritura se ejecuta pero se ignora porque el periférico está sin reloj.
  También fue el origen aparente de una discrepancia que en realidad era estar
  inspeccionando la dirección de memoria de otro puerto GPIO por error.

## 6. Cálculo de temporización real

**Preguntas:** por qué el parpadeo calculado para 100 ms resultaba visiblemente
más rápido de lo esperado.

**Punto clave:** el valor de `SYST_RVR` depende directamente de la frecuencia real
del reloj del procesador, no de una asumida. Verificar la fuente de reloj activa
(bits `SWS` de `RCC_CFGR`) confirmó que el sistema seguía en **HSI (16 MHz)** y no
en el PLL a 168 MHz que se había sospechado inicialmente, validando el cálculo
original de `0x1869FF` para 100 ms.

## 7. Banderas de estado y instrucciones aritméticas

**Preguntas:** qué hace la `S` de `ADDS`; si `CMP` ya actualiza las banderas, para
qué sirve entonces `ADDS`; si `ADD` (sin `S`) también guarda el resultado.

**Punto clave:** el guardado del resultado en el registro destino y la
actualización de banderas son dos efectos independientes de la instrucción. `ADD`
y `ADDS` guardan el resultado exactamente igual; la `S` solo decide si también se
actualizan `N`, `Z`, `C`, `V` - banderas que en este código terminan siendo
irrelevantes para el flujo porque el `CMP` posterior las vuelve a fijar.

## 8. Matriz de LEDs 1088AS

**Preguntas:** qué pines usar en el STM32 para la matriz; cómo interpretar la
numeración física de pines del 1088AS frente a filas/columnas reales; cómo agrupar
los pines para simplificar el software.

**Punto clave:** el pinout físico de un 1088AS no es universal entre unidades —
necesita verificarse contra el esquema específico del componente (o por
continuidad con multímetro) antes de asumir una tabla genérica. Agrupar los pines
de control en bits consecutivos de un mismo registro `ODR` sirve para construir y
escribir el patrón completo de una sola vez, en vez de manipular bits sueltos.

## 9. Botón K-UP / interrupciones externas vs. polling

**Preguntas:** qué GPIO corresponde a los botones K-UP/K0/K1 de la placa; para qué
sirven `RCC_APB2ENR` y `SYSCFG_EXTICR`; por qué no basta con habilitar `AHB1` para
usar una interrupción externa; si es obligatorio pasar por `SYSCFG`.

**Punto clave:** habilitar el reloj de un puerto GPIO (`AHB1ENR`) solo sirve para
leer/escribir el pin - es un periférico distinto del enrutador de interrupciones
externas (`SYSCFG`, en el bus `APB2`), que decide qué puerto alimenta cada línea
`EXTI`. Ambos relojes son obligatorios y no intercambiables si se quiere usar
interrupción; la alternativa sin `SYSCFG`/`EXTI`/`NVIC` es hacer **polling** directo
del registro `IDR`, que es el enfoque finalmente adoptado dentro de
`SysTick_Handler` para mantener el proyecto en un solo mecanismo de interrupción.

## 10. Lógica final del juego

**Pregunta:** cómo detener la animación al presionar el botón y diferenciar un
parpadeo lento (resultado "ganador", LEDs 4 o 5) de uno rápido (cualquier otro).

**Punto clave:** se introdujeron dos variables adicionales en RAM - la posición
actualmente encendida y una bandera de estado del juego - actualizadas dentro de
las mismas rutinas de barrido ya existentes. Al detectar la pulsación, el `loop`
principal deja de invocar el barrido y pasa a un bloque que compara la posición
congelada contra el criterio de victoria para decidir el umbral de parpadeo
dentro del handler de tiempo ya existente.
