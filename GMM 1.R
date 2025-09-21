# Instalar paquetes necesarios
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
data <- read_excel(ruta)

# ========================
# Variables seleccionadas
# ========================
selected_vars <- c("socio", "año", "AbsPC", "avg_price", "contig", "Dcrisis", "dist", "Grado_apertura", "IEDPIB", "LDEP", "gdp_o", "gdp_d", "DIF_KL", "IGL_total")

# ========================
# Preprocesamiento y transformación de datos
# ========================
data <- data[, selected_vars]
#data <- na.omit(data)

# Crear variables transformadas logarítmicas
if ("gdp_o" %in% names(data)) data$log_gdp_o <- log(data$gdp_o)
if ("gdp_d" %in% names(data)) data$log_gdp_d <- log(data$gdp_d)

# Reordenar por panel
if (all(c("socio", "año") %in% names(data))) {
  data <- data[order(data$socio, data$año), ]
  pdata <- pdata.frame(data, index = c("socio", "año"))
} else {
  stop("Las variables 'socio' y 'año' son necesarias para definir el panel.")
}

# Balancear el panel. Esto inserta filas con NA para los datos que faltan.
#pdata_balanced <- make.pbalanced(pdata_unbalanced)

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

# Definimos los regresores del modelo
# usamos las variables seleccionadas y transformadas.
regresores <- c(
  "AbsPC",
  "dist",
  "Grado_apertura",
  "LDEP",
  "contig",
  "Dcrisis",
  "avg_price",
  "log_gdp_o",    # Usamos la variable transformada
  "log_gdp_d",    # Usamos la variable transformada
  "IEDPIB"
)

# Fórmula para System GMM
# Se mantiene el rezago de IGL_total como variable dependiente rezagada.
# Los instrumentos se adaptan a la variable dependiente rezagada.
formula_gmm <- as.formula(paste(
  "IGL_total ~", paste(regresores, collapse = " + "),
  "| lag(IGL_total, 2) + ", # Instrumentos para la variable dependiente rezagada
  "log_gdp_o + log_gdp_d" # Ejemplo de adición de instrumentos externos si es necesario
))

modelo_gmm <- pgmm(
  formula = formula_gmm,
  data = pdata_balanced,
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
