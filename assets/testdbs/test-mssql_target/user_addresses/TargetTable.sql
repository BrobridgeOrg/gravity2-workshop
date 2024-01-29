USE #:DB_NAME:#;
GO

create table [dbo].[#:TABLE_NAME:#] (
  [id] bigint NOT NULL,
  [created_at] datetimeoffset(7)  NULL,
  [updated_at] datetimeoffset(7)  NULL,
  [address] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  [city] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  [state] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  [postal_code] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  [user_id] bigint  NULL,
  PRIMARY KEY (id)
);
GO

ALTER TABLE [dbo].[#:TABLE_NAME:#] SET (LOCK_ESCALATION = TABLE)
