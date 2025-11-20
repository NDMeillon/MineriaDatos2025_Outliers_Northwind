USE Northwind;
GO

EXEC sp_execute_external_script
    @language = N'Python',
    @script = N'
import pandas as pd
import matplotlib.pyplot as plt

# 1. Cargar los datos
data = InputData.copy()

# Las columnas ya son FLOAT o INT gracias a la conversión en SQL.
# CustomerID es usado para el índice del gráfico.

# 2. Generar el Gráfico de Dispersión
plt.figure(figsize=(12, 8))

# El tamaño del punto será proporcional a los ingresos (ya convertidos a FLOAT)
s_sizes = data["Total_de_Ingresos"] / data["Total_de_Ingresos"].mean() * 50

plt.scatter(data["Numero_de_Ordenes"],
            data["Total_de_Ingresos"],
            s=s_sizes,
            alpha=0.7,
            color="darkblue",
            edgecolors="black")

# 3. Anotar cada punto con el CustomerID
for i, row in data.iterrows():
    plt.annotate(
        row["CustomerID"],
        (row["Numero_de_Ordenes"] + 0.5, row["Total_de_Ingresos"] - 500), 
        fontsize=9,
        color="black",
        weight="bold"
    )

plt.title("Top 10 Clientes: Relación entre Frecuencia de Órdenes e Ingresos")
plt.xlabel("Número de Órdenes (Frecuencia)")
plt.ylabel("Total de Ingresos ($)")
plt.grid(True, linestyle="--", alpha=0.6)
plt.tight_layout()

# 4. Guardar el gráfico
plot_path = r"C:\temp\Top10_Customer_Scatter_Plot.png"
plt.savefig(plot_path)

# 5. Devolver mensaje de éxito
OutputData = pd.DataFrame([f"Gráfico de dispersión exportado a {plot_path}"], columns=["Mensaje"])
',
    @input_data_1 = N'
        SELECT TOP 10
            CustomerID,
            -- Convertimos COUNT() a INT
            CAST(COUNT(OrderID) AS INT) AS Numero_de_Ordenes,
            -- Convertimos SUM(MONEY) a FLOAT
            CAST(SUM(TotalOrderValue) AS FLOAT) AS Total_de_Ingresos
        FROM
            [Northwind].[dbo].[OutlierAnalysis_Aggregated]
        GROUP BY
            CustomerID
        ORDER BY
            Total_de_Ingresos DESC
        ',
    @input_data_1_name = N'InputData'
WITH RESULT SETS
(
    (
        Mensaje NVARCHAR(MAX)
    )
);