# 08 — Auditoría frente a la rúbrica

## 1. Sustentación oral y defensa técnica — 35 pts

### Fortalezas

- Arquitectura modular identificable.
- Direcciones y offsets definidos explícitamente.
- Uso real de máscaras.
- SysTick calculable matemáticamente.
- Variables de estado ubicadas en RAM.
- El `.map` sirve para rastrear funciones y direcciones.
- Se puede explicar el propósito de cada instrucción lógica principal.

### Puntos que requieren especial cuidado

- No afirmar que `baseclock.s` configura RCC: configura SysTick.
- No afirmar que se usa `COUNTFLAG`: no se consulta.
- No llamar "debounce clásico" al muestreo de 100 ms.
- No afirmar que existen rutinas independientes de acierto y fallo.
- No ocultar la discrepancia entre ocho LEDs y PD0–PD8.

---

## 2. Dominio de registros y ensamblador — 15 pts

### Implementado correctamente

- Acceso memory-mapped.
- RCC usando lectura-modificación-escritura.
- GPIO usando `MODER`, `IDR`, `ODR`.
- SysTick usando `CSR`, `RVR`, `CVR`.
- Máscaras usando desplazamientos.
- `ORR`, `BIC`, `AND/ANDS`, `EOR`.
- Código Thumb-2.

### Observación

La rúbrica menciona "SysTick en modo polling monitoreando banderas".

El proyecto actual usa:

```text
SysTick interrupt → handler → contadores RAM → polling
```

No:

```text
main → lectura COUNTFLAG
```

Si este detalle se evalúa literalmente, puede ser un punto de discusión durante la sustentación.

---

## 3. Funcionalidad y lógica — 15 pts

### Implementado

- Barrido temporal.
- Lectura del botón.
- Estado `JUEGO`.
- Modo resultado.
- Parpadeo usando `EOR`.
- Reinicio del contador de posición.

### Riesgos

1. La rutina de barrido debe verificarse físicamente para confirmar que los ocho LEDs corresponden exactamente a las máscaras utilizadas.
2. El código configura nueve pines de GPIOD.
3. El "debounce" es muestreo periódico de 100 ms.
4. El resultado no tiene dos ramas semánticas independientes de acierto/fallo.

---

## 4. Prolijidad y diseño visual — 10 pts

Este punto no puede demostrarse completamente usando el código.

Hay que verificar físicamente:

- [ ] 8 LEDs alineados.
- [ ] Resistencias limitadoras.
- [ ] Pulsador accesible.
- [ ] Cableado corto y organizado.
- [ ] Sin cables cruzando la zona visual de los LEDs.
- [ ] Sin conexiones flojas.
- [ ] Alimentación y GND claramente distribuidos.

---

## 5. Documentación técnica — 20 pts

Este paquete incluye:

- [x] desarrollo matemático de SysTick;
- [x] tabla de registros;
- [x] dirección base;
- [x] offset;
- [x] dirección efectiva;
- [x] valor hexadecimal;
- [x] explicación de máscaras;
- [x] diagrama de arquitectura;
- [x] diagrama de flujo;
- [x] diagrama lógico del hardware;
- [x] asignación lógica de pines;
- [x] análisis del `.map`;
- [x] guía de sustentación.

La asignación física exacta de cada LED debe completarse con el montaje real.

---

## 6. Estructura y control de versiones — 5 pts

El paquete está organizado en:

```text
src/
docs/
project/
```

Para obtener la maxima valoración en GitHub se recomienda que el repositorio final tenga varios commits significativos.

### Ejemplo de historial recomendado

```text
1. Initial project import
2. Add bare-metal GPIO and SysTick implementation
3. Add modular LED/button logic
4. Add technical documentation and diagrams
5. Final verification and cleanup
```

No hacer cinco commits artificiales el mismo minuto únicamente para aparentar desarrollo. Cada commit debe representar una modificación real y coherente.

---

# 7. Checklist final antes de entregar

## Código

- [ ] Compila sin errores.
- [ ] El proyecto abre correctamente en SEGGER Embedded Studio.
- [ ] El botón corresponde realmente a PA0.
- [ ] Los LEDs corresponden a los bits documentados.
- [ ] Las resistencias están instaladas.
- [ ] El barrido es visualmente uniforme.
- [ ] La pulsación congela el juego.
- [ ] El resultado parpadea.
- [ ] El reinicio funciona.

## Documentación

- [ ] README revisado.
- [ ] Tabla de registros revisada.
- [ ] SysTick revisado.
- [ ] Diagrama de flujo revisado.
- [ ] Diagrama de hardware revisado.
- [ ] Tabla física LED ↔ pin completada.
- [ ] `.map` disponible.
- [ ] Comentarios del código coherentes con la implementación.

## Sustentación

- [ ] Saber calcular `0x3E7F`.
- [ ] Saber explicar `0x15555`.
- [ ] Saber obtener `0x40023830`.
- [ ] Saber obtener `0x40020C14`.
- [ ] Saber explicar `BIC`.
- [ ] Saber explicar `ORR`.
- [ ] Saber explicar `EOR`.
- [ ] Saber explicar `LSL`.
- [ ] Saber explicar `ANDS`.
- [ ] Saber ubicar `SysTick_Handler`.
- [ ] Saber ubicar `CONTADOR`.
- [ ] Saber explicar el flujo desde reset hasta `_start`.
- [ ] Saber explicar por qué el sistema es bare-metal.
- [ ] Saber explicar la diferencia entre interrupción SysTick y polling de los contadores.
