# -*- coding: utf-8 -*-
"""
Created on Mon Jun 16 22:11:04 2025

@author: EDER3
"""
import pandas as pd
import os

# Ruta base de los archivos BACI
base_path = r"C:\Users\EDER3\OneDrive\NACHO\Investigacion China - COLOMBIA\BACI_HS02_V202501"

# Años a procesar
anios = list(range(2002, 2024))

# Código BACI de Colombia
codigo_colombia = 170

# Países objetivo (Mexico, Peru, Chile, Brasil, Ecuador, USA, China)
paises_objetivo = [8,  24,  32, 533,  36,  40,  44,  48,  50,  52,  56,  84, 204,  68,  70,
 76, 100, 120, 124, 152, 156, 188, 191, 192, 196, 203, 208, 214, 218, 818,
 222, 233, 246, 251, 268, 276, 300, 320, 340, 348, 352, 699, 360, 364, 372,
 376, 380, 388, 392, 400, 398, 404, 414, 428, 422, 440, 442, 458, 470, 484,
 504, 528, 554, 558, 566, 579, 586, 591, 600, 604, 608, 616, 620, 634, 410,
 642, 643, 682, 686, 688, 702, 703, 705, 710, 724, 144, 752, 757, 764, 780,
 788, 842, 804, 784, 826, 858, 862, 704]
#paises_objetivo = [8, 24, 32]

# Lista para almacenar resultados anuales
df_lista = []

for anio in anios:
    file_path = os.path.join(base_path, f"BACI_HS02_Y{anio}_V202501.csv")
    print(f"Cargando: {file_path}")
    
    df = pd.read_csv(file_path, header=None, names=["t", "i", "j", "k", "v", "q"])
    
    # Filtrar comercio entre Colombia y los países objetivo
    df_filtrado = df[
        (
            (df["i"] == codigo_colombia) & (df["j"].isin(paises_objetivo))
        ) | (
            (df["j"] == codigo_colombia) & (df["i"].isin(paises_objetivo))
        )
    ].copy()

    # Crear columna 'pais' y 'sentido'
    df_filtrado["pais"] = df_filtrado.apply(
        lambda row: row["j"] if row["i"] == codigo_colombia else row["i"], axis=1
    )
    df_filtrado["sentido"] = df_filtrado.apply(
        lambda row: "exporta" if row["i"] == codigo_colombia else "importa", axis=1
    )

    # Filtrar productos con comercio en doble vía
    comercio_doblevia = df_filtrado.groupby(["t", "pais", "k"])["sentido"].nunique().reset_index()
    comercio_doblevia = comercio_doblevia[comercio_doblevia["sentido"] == 2][["t", "pais", "k"]]

    df_doblevia = df_filtrado.merge(comercio_doblevia, on=["t", "pais", "k"], how="inner")
    
    df_lista.append(df_doblevia)

# Consolidar todo
df_bilateral_doblevia = pd.concat(df_lista, ignore_index=True)

# Pivotear para obtener exportaciones (X) e importaciones (M)
pivot_v = df_bilateral_doblevia.pivot_table(
    index=["t", "pais", "k"],
    columns="sentido",
    values="v",
    aggfunc="sum",
    fill_value=0
).reset_index()

pivot_q = df_bilateral_doblevia.pivot_table(
    index=["t", "pais", "k"],
    columns="sentido",
    values="q",
    aggfunc="sum",
    fill_value=0
).reset_index()

# Renombrar y combinar
pivot_v.columns.name = pivot_q.columns.name = None
pivot = pivot_v.rename(columns={"exporta": "X", "importa": "M"})
pivot["q_exporta"] = pivot_q["exporta"]
pivot["q_importa"] = pivot_q["importa"]

# Calcular precios unitarios
pivot["uv_x"] = pivot["X"] / pivot["q_exporta"].replace(0, pd.NA)
pivot["uv_m"] = pivot["M"] / pivot["q_importa"].replace(0, pd.NA)
pivot["ratio_uv"] = pivot["uv_x"] / pivot["uv_m"]

# Clasificar tipo de comercio: H, VBC, VAC
def clasificar_tipo(row):
    if pd.isna(row["ratio_uv"]) or row["uv_m"] == 0:
        return "NA"
    elif 0.85 <= row["ratio_uv"] <= 1.15:
        return "H"
    elif row["ratio_uv"] > 1.15:
        return "VAC"
    elif row["ratio_uv"] < 0.85:
        return "VBC"
    else:
        return "NA"

pivot["T_comercio"] = pivot.apply(clasificar_tipo, axis=1)

# Calcular IGL por producto
pivot["IGL_producto"] = 1 - abs(pivot["X"] - pivot["M"]) / (pivot["X"] + pivot["M"])
pivot = pivot[(pivot["X"] + pivot["M"]) > 0]
pivot["comercio"] = pivot["X"] + pivot["M"]

# Calcular IGL global y por tipo
comercio_total = pivot.groupby(["t", "pais"])["comercio"].sum().reset_index(name="comercio_total")
pivot = pivot.merge(comercio_total, on=["t", "pais"], how="left")
pivot["ponderador"] = pivot["comercio"] / pivot["comercio_total"]

def calcular_igl(df, tipo=None):
    if tipo:
        df = df[df["T_comercio"] == tipo]
    resultado = df.groupby(["t", "pais"]).apply(
        lambda d: (d["ponderador"] * d["IGL_producto"]).sum()
    ).reset_index(name=f"IGL_{tipo if tipo else 'total'}")
    return resultado

# Calcular IGLs
igl_total = calcular_igl(pivot)
igl_H = calcular_igl(pivot, "H")
igl_VBC = calcular_igl(pivot, "VBC")
igl_VAC = calcular_igl(pivot, "VAC")

# Unir resultados
igl_final = igl_total.merge(igl_H, on=["t", "pais"], how="left") \
                     .merge(igl_VBC, on=["t", "pais"], how="left") \
                     .merge(igl_VAC, on=["t", "pais"], how="left")

# Ordenar por país y año
igl_final = igl_final.sort_values(by=["pais", "t"]).reset_index(drop=True)

#print("IGL final:")
#print(igl_final)

# Exportar a:
# igl_final.to_csv("IGL_colombia_todos_los_paises_2002_2023.csv", index=False)

