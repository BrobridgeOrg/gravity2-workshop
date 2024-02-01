# 說明

使用 fakedb 的 範例程式

```go
// 建立 source database 'TestDB' tables
s.T().Logf("setup source fake data ...start")
srcFakeDB := dbfacker.New(s.srcGormDB, s.srcDBName)
s.srcFakeDB = &srcFakeDB
err = srcFakeDB.AutoMigration()
assert.Nil(s.T(), err, "create tables error")
s.T().Log("soruce auto migration ...done")
err = srcFakeDB.EnableCDC()
assert.Nil(s.T(), err, "enable cdc of all tables error")
s.T().Log("enable cdc of all tables ...done")

// 建立 target database 'TargetTestDB' tables
tgtFakeDB := dbfacker.New(s.tgtGormDB, s.tgtDBName)
s.tgtFakeDB = &tgtFakeDB
err = tgtFakeDB.AutoMigration()
assert.Nil(s.T(), err, "create target tables error")
s.T().Log("setup target tables ...done")
// gravity job 的限級，需要把 target table constraint disable
err = tgtFakeDB.DisableTableConstraint()
assert.Nil(s.T(), err, "disable target table constraint error")
s.T().Log("disable target table constraint ...done")
```
