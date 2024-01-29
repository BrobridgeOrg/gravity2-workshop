USE #:DB_NAME:#;
  GO

EXEC sys.sp_cdc_disable_table
  @source_schema = N'dbo',
  @source_name   = N'#:TABLE_NAME:#',
  @capture_instance  = N'dbo_#:TABLE_NAME:#';
  GO

drop table [dbo].[#:TABLE_NAME:#];
