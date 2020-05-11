USE [master]
GO
SET NOCOUNT ON;
DECLARE @BackupFilePath nvarchar(2000) = N'<insert_backup_file_path_here>';

BACKUP DATABASE [AA] TO DISK=@BackupFilePath WITH COPY_ONLY, STATS=10;
RESTORE VERIFYONLY FROM DISK=@BackupFilePath;
GO
