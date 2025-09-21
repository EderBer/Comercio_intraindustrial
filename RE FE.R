# Cargar librerias
library(plm)
library(readxl)

# Cargar datos
data <- read_excel("C:/Users/EDER3/OneDrive/NACHO/Investigacion China - COLOMBIA/Modelo/Datos modelo.xlsx")

# Eliminar filas con NA en variables clave
selected_vars <- c("socio", "año", "AbsPC", "avg_price", "contig", "Dcrisis", "dist", "Grado_apertura", "IEDPIB", "LDEP", "gdp_o", "gdp_d", "DIF_KL", "IGL_total") 
data <- data[, selected_vars]
#data <- na.omit(data)

# Transformaciones
data$log_gdp_d <- log(data$gdp_d)
data$log_gdp_o <- log(data$gdp_o)

# Convertir a panel
pdata <- pdata.frame(data, index = c("socio", "año"))

# =====================
# Modelo Efectos Fijos
# =====================
modelo_fijos <- plm(
  IGL_total ~ AbsPC + dist + contig + Dcrisis + avg_price + Grado_apertura + DIF_KL + LDEP + IEDPIB + log_gdp_o + log_gdp_d,
  data = pdata,
  model = "within"
)

# =====================
# Modelo Efectos Aleatorios
# =====================
modelo_aleatorios <- plm(
  IGL_total ~ AbsPC + dist + contig + Dcrisis + avg_price + Grado_apertura + DIF_KL + LDEP + IEDPIB + log_gdp_o + log_gdp_d,
  data = pdata,
  model = "random"
)

# =====================
# Resultados
# =====================
summary(modelo_fijos)

summary(modelo_aleatorios)

# Prueba de Hausman
phtest(modelo_fijos, modelo_aleatorios)

if (phtest(modelo_fijos, modelo_aleatorios)$p.value < 0.05) {
  print("→ Rechazamos H0: usar efectos fijos")
} else {
  print("→ No rechazamos H0: usar efectos aleatorios")
}
