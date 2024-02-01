USE #:DB_NAME:#;
GO

create table [dbo].[#:TABLE_NAME:#] (
  [id] bigint NOT NULL,
  [created_at] datetimeoffset(7)  NULL,
  [updated_at] datetimeoffset(7)  NULL,
  [username] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  [password] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  [email] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
  PRIMARY KEY (id)
);
GO

ALTER TABLE [dbo].[#:TABLE_NAME:#] SET (LOCK_ESCALATION = TABLE)
