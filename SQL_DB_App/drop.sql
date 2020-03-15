-- =======================================================================================================
-- Deletes the whole scehma created by CreateSchema.sql
-- Author: Andrej Jurco
-- =======================================================================================================

USE CyclingTeamManager
GO

BEGIN TRANSACTION DropSchema

DROP TABLE contract
DROP TABLE results
DROP TABLE start_list
DROP TABLE stage
DROP TABLE Cyclist
DROP TABLE Team
DROP TABLE race

GO

--ROLLBACK TRANSACTION

commit transaction

