# Examen Parcial de Econometría de Series de Tiempo
## Modelos VAR y VEC con Aplicación Financiera

**Estudiante:** Kevin Chaparro  
**Asignatura:** Econometría   
**Semestre:** 2026-II  
**Fecha de entrega:** 03/09/2026

---

## Descripción del proyecto

Este repositorio contiene el desarrollo completo del examen práctico de la asignatura **Econometría**, en el cual se analiza la relación de corto y largo plazo entre el precio del petróleo crudo WTI (CL=F) y las acciones de ExxonMobil (XOM) y Chevron (CVX) durante el período **01-01-2018 a 31-12-2025** con frecuencia semanal.

El análisis sigue una metodología estándar en econometría financiera:
1. Obtención y tratamiento de datos.
2. Pruebas de raíz unitaria (ADF y KPSS).
3. Test de cointegración de Johansen.
4. Estimación de un modelo VAR (pues no se encontró cointegración).
5. Diagnóstico de residuales (autocorrelación, estabilidad, heterocedasticidad).
6. Análisis de causalidad de Granger, funciones impulso‑respuesta y descomposición de la varianza.

---

## Estructura del repositorio

```text
examen_series_tiempo/
│
├── codigo/
│   └── examen_script.R
│
├── datos/
│   ├── 01_precios_semanales.csv
│   ├── 02_log_precios.csv
│   └── 03_retornos.csv
│
├── resultados/
│   ├── 06_ADF_niveles.csv
│   ├── 07_ADF_diferencias.csv
│   ├── 08_KPSS_niveles.csv
│   ├── 09_KPSS_diferencias.csv
│   ├── 15_VAR_estimado.txt
│   ├── 17_Portmanteau.txt
│   ├── 21_ARCH_multivariado.txt
│   ├── 22_Granger_WTI.txt
│   ├── 25_IRF_WTI.png
│   ├── 28_FEVD.png
│   ├── 29_estadisticos_descriptivos.csv
│   ├── 30_correlaciones.csv
│   ├── FEVD_r_WTI_4_8_12.csv
│   ├── FEVD_r_XOM_4_8_12.csv
│   └── FEVD_r_CVX_4_8_12.csv
│
├── informe/
│   └── informe_examen.pdf
│
└── README.md
```

### Archivos principales

- **`codigo/examen_script.R`** → Script completo en R (ejecutable).
- **`datos/`** → Datos generados durante el análisis.
- **`resultados/`** → Tablas, gráficos y resultados numéricos.
- **`informe/informe_examen.pdf`** → Informe final en PDF con todas las tablas y gráficos.
- **`README.md`** → Documento de presentación y descripción del proyecto.

---

## Requisitos para ejecutar el código

- **R** (versión ≥ 4.0)
- **RStudio** (recomendado)
- Paquetes necesarios (se instalan automáticamente con el script):
  - `quantmod`, `dplyr`, `tidyr`, `ggplot2`, `zoo`, `lubridate`, `urca`, `vars`, `tseries`, `FinTS`, `lmtest`, `car`

---

## Instrucciones de ejecución

1. Clona este repositorio o descarga los archivos.
2. Abre el archivo `codigo/examen_script.R` en RStudio.
3. Ejecuta el script completo (seleccionando todo y presionando **Ctrl+Enter** o haciendo clic en **Source**).
4. El script:
   - Descargará automáticamente los datos desde Yahoo Finance.
   - Generará las series semanales, log‑precios y retornos.
   - Realizará todas las pruebas y estimaciones.
   - Guardará todos los resultados en la carpeta `resultados/`.
   - Generará gráficos en formato PNG.

**Nota:** Si algún paquete no se instala automáticamente, instálelo manualmente con `install.packages("nombre_del_paquete")`.

---

## Resumen de resultados obtenidos

### 1. Datos y estadísticos descriptivos

- **Frecuencia:** semanal (último día hábil de cada semana).
- **Número de observaciones:** 416 semanas.

| Variable | Media (%) | Desv. Est. (%) | Mínimo (%) | Máximo (%) | Mediana (%) |
|----------|-----------|----------------|------------|------------|-------------|
| r_WTI    | -0.016    | 5.88           | -34.69     | 27.58      | 0.48        |
| r_XOM    | 0.166     | 4.22           | -22.40     | 15.47      | 0.41        |
| r_CVX    | 0.125     | 4.26           | -33.98     | 15.44      | 0.39        |

**Matriz de correlaciones:**

|         | r_WTI | r_XOM | r_CVX |
|---------|-------|-------|-------|
| r_WTI   | 1.000 | 0.607 | 0.565 |
| r_XOM   | 0.607 | 1.000 | 0.839 |
| r_CVX   | 0.565 | 0.839 | 1.000 |

---

### 2. Estacionariedad y cointegración

**Pruebas ADF y KPSS (resumen):**

- En **niveles (log‑precios)**:  
  ADF **no rechaza** raíz unitaria (estadísticos > valor crítico).  
  KPSS **rechaza** estacionariedad (estadísticos > valor crítico).  
  → Las series son **I(1)**.

- En **primeras diferencias (retornos)**:  
  ADF **rechaza** raíz unitaria (estadísticos < valor crítico).  
  KPSS **no rechaza** estacionariedad (estadísticos < valor crítico).  
  → Los retornos son **I(0)**.

**Test de Johansen (con 4 rezagos):**

| Prueba       | Rango estimado |
|--------------|----------------|
| Traza        | r = 0          |
| Máximo autovalor | r = 0      |

→ **No existe cointegración** entre las variables. Por tanto, se estima un **VAR en retornos**.

---

### 3. Modelo VAR estimado

Se seleccionó **1 rezago** según el criterio de BIC (SC).

**Ecuaciones estimadas:**

\[
\begin{aligned}
r_{WTI,t} &= 0.105 \cdot r_{WTI,t-1} + 0.115 \cdot r_{XOM,t-1} - 0.103 \cdot r_{CVX,t-1} - 0.0003 + \varepsilon_{1,t} \\
r_{XOM,t} &= 0.007 \cdot r_{WTI,t-1} + 0.174 \cdot r_{XOM,t-1} - 0.188 \cdot r_{CVX,t-1} + 0.0016 + \varepsilon_{2,t} \\
r_{CVX,t} &= -0.013 \cdot r_{WTI,t-1} + 0.247 \cdot r_{XOM,t-1} - 0.177 \cdot r_{CVX,t-1} + 0.0010 + \varepsilon_{3,t}
\end{aligned}
\]

**Observaciones:**
- Solo los coeficientes de \( r_{XOM,t-1} \) en la ecuación de \( r_{CVX} \) y \( r_{CVX,t-1} \) en la de \( r_{XOM} \) son significativos al 5 %.
- El modelo explica muy poca varianza (\( R^2 \) ajustado entre 0.4 % y 1 %).

---

### 4. Diagnóstico del modelo

| Prueba                   | Estadístico | p‑valor      | Conclusión                                |
|--------------------------|-------------|--------------|-------------------------------------------|
| Portmanteau (autocorr.)  | χ² = 184.24 | 4.37 × 10⁻⁷  | **Rechaza** ausencia de autocorrelación   |
| ARCH multivariado        | χ² = 1044.5 | < 2.2 × 10⁻¹⁶| **Rechaza** homocedasticidad              |
| Estabilidad (raíces)     | Máx. módulo = 0.121 | - | **Estable** (todas las raíces < 1) |

**Interpretación:**  
El modelo VAR(1) no satisface los supuestos de ruido blanco: presenta autocorrelación y heterocedasticidad. Esto sugiere que podría ser necesario incluir más rezagos o modelar la volatilidad con un modelo GARCH multivariado.

---

### 5. Causalidad de Granger

**Hipótesis nula:** \( r_{WTI} \) no causa a \( r_{XOM} \) y \( r_{CVX} \).  
- **F‑test = 0.3336**, gl = 2, 1236, **p‑valor = 0.7164**  
→ **No se rechaza** la nula. El WTI **no** predice en sentido de Granger a las acciones.

Sin embargo, se detecta **causalidad instantánea** (contemporánea) significativa (\( p < 2.2 \times 10^{-16} \)), lo que indica que los shocks en el petróleo y las acciones ocurren al mismo tiempo.

---

### 6. Funciones Impulso‑Respuesta (IRF)

Se aplicó un choque ortogonalizado de una desviación estándar en \( r_{WTI} \).  
- El efecto sobre el propio WTI es positivo y se desvanece rápidamente (después de 2‑3 semanas).  
- Sobre XOM y CVX, el efecto es positivo pero de magnitud muy pequeña (inferior a 0.01) y no persistente.  
- Los intervalos de confianza (95 %) incluyen el cero en la mayoría de los periodos, lo que sugiere que el impacto no es estadísticamente significativo.

---

### 7. Descomposición de la Varianza del Error de Pronóstico (FEVD)

A 4, 8 y 12 semanas (los valores son prácticamente constantes):

| Variable explicada | % explicado por r_WTI | % explicado por r_XOM | % explicado por r_CVX |
|---------------------|------------------------|------------------------|------------------------|
| r_WTI               | 99.80 %                | 0.04 %                 | 0.16 %                 |
| r_XOM               | 36.74 %                | 62.23 %                | 1.03 %                 |
| r_CVX               | 31.44 %                | 39.14 %                | 29.42 %                |

**Interpretación:**  
- La mayor parte de la varianza del WTI se explica por sí mismo.  
- En las acciones, el WTI explica alrededor del 31‑37 % de su variabilidad, mientras que XOM explica gran parte de la varianza de CVX (39 %) y viceversa (62 % de XOM se explica por sí misma). Esto refleja la alta correlación entre ambas petroleras.

---

## Conclusiones principales

1. **No hay cointegración** entre el WTI y las acciones de Exxon y Chevron en el período analizado.  
2. El **VAR(1) en retornos** es el modelo adecuado, aunque presenta problemas de autocorrelación y heterocedasticidad.  
3. El WTI **no causa en sentido de Granger** a las acciones, pero sí existe una relación contemporánea fuerte.  
4. Los efectos dinámicos son **débiles y no persistentes**: un choque en el petróleo apenas se transmite a las acciones.  
5. La mayor parte de la varianza de las acciones se explica por sí mismas y entre ellas, no por el petróleo.

---

## Archivos generados

- `resultados/` → contiene todas las tablas, gráficos y resultados numéricos.  
- `informe/informe_examen.pdf` → documento final con el análisis completo.  
- `codigo/examen_script.R` → script replicable.

---

## Nota final

Este trabajo fue desarrollado de manera autónoma siguiendo la metodología enseñada en clase. Todos los resultados son **reproducibles** ejecutando el script proporcionado.

---

**Contacto:** kevin.chaparro@usantotomas.edu.co  
**Repositorio:** https://github.com/KevinG47/econometria-corte1.git
