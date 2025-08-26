# Instalar y cargar los paquetes necesarios
install.packages(c("plm", "gmm", "readxl", "dplyr"))
library(plm)
library(gmm)
library(readxl)
library(dplyr)

# ======================
# 1. Cargar los datos
# ======================
data <- read_excel("C:\\Users\\EDER3\\OneDrive\\NACHO\\Investigacion China - COLOMBIA\\Modelo\\Datos modelo.xlsx")

# ======================
# 2. Seleccionar variables
# ======================
selected_vars <- c("año", "socio", "IGL_total", "gdp_o", "gdpcap_o", 
                   "gdp_d", "gdpcap_d", "IED", "LDEP", "ep_col")

data <- data %>%
  select(all_of(selected_vars)) %>%
  filter(!is.na(IGL_total))  # quitar NAs en la dependiente

# ======================
# 3. Transformar a panel
# ======================
panel_data <- pdata.frame(data, index = c("socio", "año"))

# ======================
# 4. Estimación System-GMM
# ======================
# Nota: usamos lag de la dependiente como regresor y variable instrumental

gmm_model <- pgmm(
  formula = IGL_total ~ lag(IGL_total, 1) + gdp_o + gdpcap_o + 
    gdp_d + gdpcap_d + IED + LDEP + ep_col |
    lag(IGL_total, 2:3),  # instrumentos internos
  data = panel_data,
  effect = "individual",
  model = "twosteps",
  transformation = "ld"  # diferencia en niveles + instrumentos en niveles = System GMM
)

# ======================
# 5. Resultados
# ======================
summary(gmm_model)

