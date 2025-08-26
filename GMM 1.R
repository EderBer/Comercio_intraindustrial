# Instala paquetes necesarios solo si no los tienes
if (!require("plm")) install.packages("plm")
if (!require("data.table")) install.packages("data.table")
if (!require("corrplot")) install.packages("corrplot")
if (!require("car")) install.packages("car")
if (!require("psych")) install.packages("psych")
if (!require("readxl")) install.packages("readxl")

# Cargar librerías
library(plm)
library(data.table)
library(corrplot)
library(car)
library(psych)
library(readxl)

# ========================
# Cargar base de datos
# ========================
data <- read_excel("C:\\Users\\EDER3\\OneDrive\\NACHO\\Investigacion China - COLOMBIA\\Modelo\\Datos modelo.xlsx")

# ========================
# CAMBIAR SOLO ESTA LÍNEA
# ========================
selected_vars <- c("socio", "año", "IGL_total", "AbsPC", "dist",
                   "LDEP", "contig", "Dcrisis", "IED", "avg_price","Grado_apertura")

# ========================
# Preprocesamiento general
# ========================
data <- data[, selected_vars]
data <- na.omit(data)

# Crear variables transformadas automáticamente si existen
#if ("gdp_o" %in% names(data)) data$log_gdp_o <- log(data$gdp_o)
#if ("gdp_d" %in% names(data)) data$log_gdp_d <- log(data$gdp_d)
#if ("IED"   %in% names(data)) data$log_IED   <- log(data$IED + 1)

# Reordenar por panel
if (all(c("socio", "año") %in% names(data))) {
  data <- data[order(data$socio, data$año), ]
  pdata <- pdata.frame(data, index = c("socio", "año"))
} else {
  stop("Las variables 'socio' y 'año' son necesarias para definir el panel.")
}

# ========================
# Matriz de correlación
# ========================
numeric_data <- data[sapply(data, is.numeric)]
cor_matrix <- cor(numeric_data, use = "complete.obs")
print(round(cor_matrix, 3))

# Visualización
corrplot(cor_matrix, method = "color", type = "upper",
         addCoef.col = "black", tl.cex = 0.9, number.cex = 0.7, diag = FALSE)

# ========================
# Modelo System GMM
# ========================

regresores <- c(
  "lag(IGL_total, 1)",  # Modelo dinámico
  "AbsPC",
  "dist",
  "Grado_apertura",
  "LDEP",
  "contig",
  "Dcrisis",
  "IED",
  "avg_price"
)

# Fórmula para System GMM
formula_gmm <- as.formula(paste(
  "IGL_total ~", paste(regresores, collapse = " + "), 
  "| lag(IGL_total, 2:4)"  # Instrumentos para la variable rezagada
))

modelo_gmm <- pgmm(
  formula = formula_gmm,
  data = pdata,
  effect = "individual",
  model = "twosteps",
  transformation = "ld"
)

# ========================
# Resultados y diagnósticos
# ========================
summary(modelo_gmm)
print("Test de Hansen (Sargan):")
print(modelo_gmm$sargan)

print("Test de autocorrelación:")
print(mtest(modelo_gmm, order = 1))
print(mtest(modelo_gmm, order = 2))

