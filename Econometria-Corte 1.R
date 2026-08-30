# ================================================================
# EXAMEN DE SERIES DE TIEMPO - PETRÓLEO Y SECTOR ENERGÉTICO
# Serie: WTI (CL=F), XOM, CVX
# Periodo: 01-01-2018 a 31-12-2025 (semanal)
# Nivel de significancia: alpha = 0.05
# ================================================================

# 0. PAQUETES ----------------------------------------------------
paquetes <- c("quantmod", "dplyr", "tidyr", "ggplot2", "zoo",
              "lubridate", "urca", "vars", "tseries", "FinTS",
              "lmtest", "tsDyn", "car")
instalar <- paquetes[!(paquetes %in% installed.packages()[,"Package"])]
if(length(instalar)>0) install.packages(instalar)

library(quantmod); library(dplyr); library(tidyr); library(ggplot2)
library(zoo); library(lubridate); library(urca); library(vars)
library(tseries); library(FinTS); library(lmtest)
library(car)

dir.create("resultados", showWarnings = FALSE)

# 1. DATOS ------------------------------------------------------
tickers <- c("CL=F", "XOM", "CVX")
getSymbols(tickers, src = "yahoo", from = "2018-01-01",
           to = "2026-01-01", auto.assign = TRUE, warnings = FALSE)

# Cierres ajustados
WTI <- Ad(`CL=F`)
XOM_adj <- Ad(XOM)
CVX_adj <- Ad(CVX)

datos_diarios <- merge(WTI, XOM_adj, CVX_adj)
colnames(datos_diarios) <- c("WTI", "XOM", "CVX")
datos_diarios <- na.omit(datos_diarios)

# Conversión a semanal (último día hábil)
datos_semanales <- apply.weekly(datos_diarios, last)
datos_semanales <- na.omit(datos_semanales)
colnames(datos_semanales) <- c("WTI", "XOM", "CVX")

# Log-precios y retornos
log_precios <- log(datos_semanales)
colnames(log_precios) <- c("ln_WTI", "ln_XOM", "ln_CVX")
retornos <- diff(log_precios)
retornos <- na.omit(retornos)
colnames(retornos) <- c("r_WTI", "r_XOM", "r_CVX")

# Guardar datos
write.csv(as.data.frame(datos_semanales), "resultados/01_precios_semanales.csv")
write.csv(as.data.frame(log_precios), "resultados/02_log_precios.csv")
write.csv(as.data.frame(retornos), "resultados/03_retornos.csv")

# Gráficos (se omiten en este reporte por brevedad, pero se generan)
# ... (código de gráficos similar al proporcionado, ajustando nombres)

# 2. ESTACIONARIEDAD Y COINTEGRACIÓN ----------------------------
# 2.a Pruebas ADF y KPSS (funciones auxiliares)
resultado_adf <- function(x, nombre){
  prueba <- ur.df(as.numeric(x), type = "drift", selectlags = "AIC")
  data.frame(Variable = nombre,
             Estadistico_ADF = prueba@teststat[1],
             Critico_5 = prueba@cval[1,"5pct"],
             Rechaza_H0 = prueba@teststat[1] < prueba@cval[1,"5pct"])
}
resultado_kpss <- function(x, nombre){
  prueba <- ur.kpss(as.numeric(x), type = "mu", lags = "short")
  data.frame(Variable = nombre,
             Estadistico_KPSS = prueba@teststat,
             Critico_5 = prueba@cval["5pct"],
             Rechaza_H0 = prueba@teststat > prueba@cval["5pct"])
}

ADF_niveles <- bind_rows(
  resultado_adf(log_precios$ln_WTI, "ln_WTI"),
  resultado_adf(log_precios$ln_XOM, "ln_XOM"),
  resultado_adf(log_precios$ln_CVX, "ln_CVX")
)
ADF_diferencias <- bind_rows(
  resultado_adf(retornos$r_WTI, "r_WTI"),
  resultado_adf(retornos$r_XOM, "r_XOM"),
  resultado_adf(retornos$r_CVX, "r_CVX")
)
KPSS_niveles <- bind_rows(
  resultado_kpss(log_precios$ln_WTI, "ln_WTI"),
  resultado_kpss(log_precios$ln_XOM, "ln_XOM"),
  resultado_kpss(log_precios$ln_CVX, "ln_CVX")
)
KPSS_diferencias <- bind_rows(
  resultado_kpss(retornos$r_WTI, "r_WTI"),
  resultado_kpss(retornos$r_XOM, "r_XOM"),
  resultado_kpss(retornos$r_CVX, "r_CVX")
)
write.csv(ADF_niveles, "resultados/06_ADF_niveles.csv", row.names=FALSE)
write.csv(ADF_diferencias, "resultados/07_ADF_diferencias.csv", row.names=FALSE)
write.csv(KPSS_niveles, "resultados/08_KPSS_niveles.csv", row.names=FALSE)
write.csv(KPSS_diferencias, "resultados/09_KPSS_diferencias.csv", row.names=FALSE)

# 2.b Johansen
Y <- as.matrix(log_precios)
seleccion_J <- VARselect(Y, lag.max = 12, type = "const")
K <- as.numeric(seleccion_J$selection["AIC(n)"])
johansen_trace <- ca.jo(Y, type = "trace", ecdet = "const", K = K, spec = "transitory")
johansen_eigen <- ca.jo(Y, type = "eigen", ecdet = "const", K = K, spec = "transitory")

# Rango según traza y máximo autovalor
trace_test <- johansen_trace@teststat
trace_crit <- johansen_trace@cval[,"5pct"]
r_trace <- sum(trace_test > trace_crit)
eigen_test <- johansen_eigen@teststat
eigen_crit <- johansen_eigen@cval[,"5pct"]
r_eigen <- sum(eigen_test > eigen_crit)

cat("Rango Traza =", r_trace, "\nRango Max-Eig =", r_eigen, "\n")

# 3. MODELO (VAR o VEC) -----------------------------------------
if(r_trace == 0) {
  # VAR en retornos
  seleccion_VAR <- VARselect(retornos, lag.max = 12, type = "const")
  p <- as.numeric(seleccion_VAR$selection["SC(n)"])
  modelo <- VAR(retornos, p = p, type = "const")
  modelo_tipo <- "VAR"
} else {
  # VEC con r = r_trace
  r <- r_trace
  vecm <- cajorls(johansen_trace, r = r)
  # Convertir a VAR en niveles para diagnósticos y análisis dinámico
  modelo <- vec2var(johansen_trace, r = r)
  modelo_tipo <- "VEC"
}

# Guardar resultados de estimación
capture.output(summary(modelo), file = paste0("resultados/15_", modelo_tipo, "_estimado.txt"))
# Coeficientes (para VEC se pueden extraer de vecm$rlm y vecm$beta)

# 4. DIAGNÓSTICO -------------------------------------------------
# Autocorrelación (Portmanteau)
portmanteau <- serial.test(modelo, lags.pt = 12, type = "PT.asymptotic")
capture.output(portmanteau, file = "resultados/17_Portmanteau.txt")

# Estabilidad (raíces)
raices <- roots(modelo, modulus = TRUE)
modulos <- Mod(raices)
estable <- all(modulos < 1)
cat("Estable:", estable, "\n")

# Heterocedasticidad (ARCH multivariado)
arch_test <- arch.test(modelo, lags.multi = 5, multivariate.only = TRUE)
capture.output(arch_test, file = "resultados/21_ARCH_multivariado.txt")

# 5. ANÁLISIS DINÁMICO ------------------------------------------
# 5.a Causalidad de Granger (desde el VAR en niveles o retornos)
if(modelo_tipo == "VAR") {
  # Para VAR en retornos, causa = "r_WTI"
  causa_WTI <- causality(modelo, cause = "r_WTI")
} else {
  # Para VEC, el objeto modelo es un VAR en niveles (de vec2var)
  causa_WTI <- causality(modelo, cause = "ln_WTI")
}
capture.output(causa_WTI, file = "resultados/22_Granger_WTI.txt")

# 5.b IRF (choque en WTI, horizonte 12)
irf_WTI <- irf(modelo, impulse = if(modelo_tipo=="VAR") "r_WTI" else "ln_WTI",
               response = c(if(modelo_tipo=="VAR") "r_WTI" else "ln_WTI",
                            if(modelo_tipo=="VAR") "r_XOM" else "ln_XOM",
                            if(modelo_tipo=="VAR") "r_CVX" else "ln_CVX"),
               n.ahead = 12, ortho = TRUE, boot = TRUE, ci = 0.95, runs = 1000)
png("resultados/25_IRF_WTI.png", width=1200, height=900, res=150)
plot(irf_WTI); dev.off()

# 5.c FEVD
fevd_result <- fevd(modelo, n.ahead = 12)
png("resultados/28_FEVD.png", width=1200, height=900, res=150)
plot(fevd_result); dev.off()

# Extraer FEVD a 4, 8 y 12 semanas
FEVD_4_8_12 <- list()
for(var in names(fevd_result)){
  FEVD_4_8_12[[var]] <- fevd_result[[var]][c(4,8,12), , drop=FALSE]
}
# Guardar
for(var in names(FEVD_4_8_12)){
  write.csv(FEVD_4_8_12[[var]], paste0("resultados/FEVD_", var, "_4_8_12.csv"))
}

# 6. ESTADÍSTICOS DESCRIPTIVOS Y CORRELACIONES -----------------
estadisticos <- data.frame(
  Variable = colnames(retornos),
  Media = apply(retornos, 2, mean),
  Desviacion = apply(retornos, 2, sd),
  Minimo = apply(retornos, 2, min),
  Maximo = apply(retornos, 2, max),
  Mediana = apply(retornos, 2, median)
)
write.csv(estadisticos, "resultados/29_estadisticos_descriptivos.csv", row.names=FALSE)
correlaciones <- cor(retornos)
write.csv(correlaciones, "resultados/30_correlaciones.csv")
