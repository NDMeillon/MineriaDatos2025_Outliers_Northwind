USE Northwind;
GO

-- 1. LIMPIEZA: Si la tabla ya existe, la borramos para evitar errores al re-ejecutar.
IF OBJECT_ID('dbo.OutlierAnalysis', 'U') IS NOT NULL
    DROP TABLE dbo.OutlierAnalysis;
GO

-- 2. ESTRUCTURA: Creamos la tabla definiendo los tipos de datos correctos.
CREATE TABLE [dbo].[OutlierAnalysis] (
    OrderID INT,
    CustomerID NCHAR(5),
    EmployeeID INT,
    Freight MONEY,
    ProductID INT,
    DetailUnitPrice MONEY,
    Quantity SMALLINT,
    Discount REAL,
    LineValue MONEY,        -- Valor calculado de la línea
    SubtotalValue MONEY,    -- Suma de todos los productos del pedido
    TotalOrderValue MONEY   -- Subtotal + Freight
);
GO

-- 3. INSERCIÓN: Usamos tu lógica (CTE) para llenar la tabla.
-- Nota: Usamos OVER(PARTITION BY) en lugar de GROUP BY para mantener el detalle.
INSERT INTO [dbo].[OutlierAnalysis]
(OrderID, CustomerID, EmployeeID, Freight, ProductID, DetailUnitPrice, Quantity, Discount, LineValue, SubtotalValue, TotalOrderValue)
SELECT 
    OC.OrderID,
    OC.CustomerID,
    OC.EmployeeID,
    OC.Freight,
    OC.ProductID,
    OC.DetailUnitPrice,
    OC.Quantity,
    OC.Discount,
    OC.LineValue,
    -- Calculamos la suma de LineValue particionada por OrderID (El total del pedido)
    SUM(OC.LineValue) OVER(PARTITION BY OC.OrderID) AS SubtotalValue,
    -- Sumamos ese subtotal más el costo de envío
    (SUM(OC.LineValue) OVER(PARTITION BY OC.OrderID) + OC.Freight) AS TotalOrderValue
FROM 
    (
        -- Tu lógica original (CTE convertida en subconsulta)
        SELECT
            OD.OrderID,
            O.CustomerID,
            O.EmployeeID,
            O.Freight,
            OD.ProductID,
            OD.UnitPrice AS DetailUnitPrice,
            OD.Quantity,
            OD.Discount,
            (OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS LineValue
        FROM
            [Northwind].[dbo].[Order Details] AS OD
        INNER JOIN
            [Northwind].[dbo].[Orders] AS O
            ON OD.OrderID = O.OrderID
    ) AS OC
ORDER BY 
    TotalOrderValue DESC;
GO

-- 4. VERIFICACIÓN: Mostramos los primeros 10 resultados para confirmar.
SELECT TOP 2000 * FROM [dbo].[OutlierAnalysis] ORDER BY TotalOrderValue DESC;