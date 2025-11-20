USE Northwind;
GO

-- 1. LIMPIEZA: Si la tabla ya existe, la borramos para evitar errores al re-ejecutar.
IF OBJECT_ID('dbo.OutlierAnalysis_Aggregated', 'U') IS NOT NULL
    DROP TABLE dbo.OutlierAnalysis_Aggregated;
GO

-- 2. ESTRUCTURA: Creamos la tabla definiendo el esquema para los datos agregados.
CREATE TABLE [dbo].[OutlierAnalysis_Aggregated] (
    OrderID INT,
    CustomerID NCHAR(5),
    EmployeeID INT,
    OrderDate DATETIME, -- Incluimos la fecha para análisis temporal
    Freight MONEY,
    SubtotalValue MONEY,    -- Suma de todos los productos del pedido
    TotalOrderValue MONEY,  -- Subtotal + Freight
    TotalItems INT,         -- Cantidad total de productos en el pedido
    AvgDiscount REAL        -- Promedio de descuento aplicado en el pedido
);
GO

-- 3. INSERCIÓN: Usamos la lógica GROUP BY para llenar la tabla.
INSERT INTO [dbo].[OutlierAnalysis_Aggregated]
(OrderID, CustomerID, EmployeeID, OrderDate, Freight, SubtotalValue, TotalOrderValue, TotalItems, AvgDiscount)
SELECT
    O.OrderID,
    O.CustomerID,
    O.EmployeeID,
    O.OrderDate, -- Usamos la fecha del encabezado
    O.Freight,
    -- 1. Calculamos el subtotal del pedido
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS SubtotalValue,
    -- 2. Calculamos el valor total (Subtotal + Flete)
    SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) + O.Freight AS TotalOrderValue,
    -- 3. Contamos la cantidad total de artículos
    SUM(OD.Quantity) AS TotalItems,
    -- 4. Calculamos el promedio de descuento aplicado en las líneas del pedido
    AVG(OD.Discount) AS AvgDiscount
FROM
    [Northwind].[dbo].[Orders] AS O
INNER JOIN
    [Northwind].[dbo].[Order Details] AS OD
    ON O.OrderID = OD.OrderID
GROUP BY
    -- Agrupamos solo por las columnas de la tabla Orders y el Freight
    O.OrderID,
    O.CustomerID,
    O.EmployeeID,
    O.OrderDate,
    O.Freight
ORDER BY
    TotalOrderValue DESC;
GO

-- 4. VERIFICACIÓN: Mostramos los 10 pedidos más caros.
SELECT TOP 1000 * FROM [dbo].[OutlierAnalysis_Aggregated] ORDER BY TotalOrderValue DESC;