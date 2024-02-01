IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '#:DB_NAME:#')
BEGIN
  CREATE DATABASE #:DB_NAME:#;
END;
GO

USE #:DB_NAME:#;
GO

EXEC sys.sp_cdc_enable_db;

