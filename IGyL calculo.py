# -*- coding: utf-8 -*-
"""
Created on Tue Apr 29 14:05:03 2025

@author: EDER3
"""
import pandas as pd
import os

# Ruta a la carpeta con los archivos 
carpeta_datos = r"C:\Users\EDER3\OneDrive\NACHO\Investigacion China - COLOMBIA\BACI_HS02_V202501"

# Lista de años
años = list(range(2002, 2024))

# Lista para guardar resultados
resultados = []
#comercio_CC = pd.DataFrame()

for anio in años:
    archivo = os.path.join(carpeta_datos, f'BACI_HS02_Y{anio}_V202501.csv')

    # Cargar el archivo del año
    df = pd.read_csv(archivo)
    

    # Filtrar comercio entre Colombia (170) y China (156)
    df_col_chi2 = df[((df['i'] == 170) & (df['j'] == 156)) | ((df['i'] == 156) & (df['j'] == 170))]

    # Concatenar al DataFrame global
    #comercio_CC = pd.concat([comercio_CC, df_col_chi2], ignore_index=True)

       # Excluir ferroaleaciones y electronica con k=720260 y 852520 respectivamente
    #df_col_chi2 = df_col_chi1[df_col_chi1['k'] != 852520] #Para un producto
    #df_col_chi2 = df_col_chi[~df_col_chi['k'].isin([852520, 720260])] # Para varios productos
    
    # Exportaciones de Colombia a China
    exp = df_col_chi2[(df_col_chi2['i'] == 170) & (df_col_chi2['j'] == 156)][['k', 'v']].rename(columns={'v': 'X_k'})

    # Importaciones de Colombia desde China
    imp = df_col_chi2[(df_col_chi2['i'] == 156) & (df_col_chi2['j'] == 170)][['k', 'v']].rename(columns={'v': 'M_k'})

    # Unir exportaciones e importaciones por código arancelario
    df_gl = pd.merge(exp, imp, on='k', how='inner')

    # Calcular el índice GL por producto
    df_gl['GL_k'] = (df_gl['X_k'] + df_gl['M_k'] - abs(df_gl['X_k'] - df_gl['M_k'])) / (df_gl['X_k'] + df_gl['M_k'])

    # Calcular promedio ponderado del GL
    df_gl['peso'] = df_gl['X_k'] + df_gl['M_k']
    gl_ponderado = (df_gl['GL_k'] * df_gl['peso']).sum() / df_gl['peso'].sum()

    # Agregar resultado a la lista
    resultados.append({'Año': anio, 'IGyL': round(gl_ponderado, 4)})

# Convertir resultados en DataFrame para visualización adecuada
df_resultados = pd.DataFrame(resultados)

# Mostrar resultados
print(df_resultados)

# guardar en CSV
# df_resultados.to_csv('IGyL_resultados.csv', index=False)
