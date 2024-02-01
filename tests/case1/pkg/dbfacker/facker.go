package dbfacker

import (
	"context"
	"database/sql"
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/go-faker/faker/v4"
	"gorm.io/gorm"
)

type DBFacker struct {
	GormDB *gorm.DB
	dbSQL  *sql.DB
	dbName string
}

type TableRowCountInfo struct {
	Name     string
	RowCount int64
}

func New(db *gorm.DB, dbName string) DBFacker {
	d := DBFacker{
		GormDB: db,
		dbName: dbName,
	}
	var err error
	d.dbSQL, err = db.DB()
	if err != nil {
		panic(err)
	}
	return d
}

func (f *DBFacker) AutoMigration() error {
	if err := f.GormDB.AutoMigrate(&User{}); err != nil {
		return err
	}
	if err := f.GormDB.AutoMigrate(&UserAddress{}); err != nil {
		return err
	}
	return nil
}

// func (f *DBFacker) DropAllTables() error {
// 	if err := f.GormDB.Migrator().DropTable(&User{}); err != nil {
// 		return err
// 	}
// 	if err := f.GormDB.Migrator().DropTable(&UserAddress{}); err != nil {
// 		return err
// 	}
// 	return nil
// }

func (f *DBFacker) EnableCDC() error {
	// Check if CDC is already enabled for users table
	var usersCDCEnabled int
	err := f.dbSQL.QueryRow("SELECT COUNT(*) FROM sys.tables WHERE name = 'dbo_users_CT'").Scan(&usersCDCEnabled)
	if err != nil {
		return err
	}
	if usersCDCEnabled == 0 {
		sql := fmt.Sprintf(`USE %s;
			EXEC sys.sp_cdc_enable_db;
			EXEC sys.sp_cdc_enable_table
				@source_schema = N'dbo',
				@source_name   = N'users',
				@role_name     = NULL,
				@supports_net_changes = 1;`, f.dbName)
		_, err = f.dbSQL.Exec(sql)
		if err != nil {
			return err
		}
		fmt.Printf("Users table EnableCDC: %s\n", sql)
	} else {
		fmt.Println("Users table CDC already enabled")
	}

	// Check if CDC is already enabled for user_addresses table
	var userAddressesCDCEnabled int
	err = f.dbSQL.QueryRow("SELECT COUNT(*) FROM sys.tables WHERE name = 'dbo_user_addresses_CT'").Scan(&userAddressesCDCEnabled)
	if err != nil {
		return err
	}
	if userAddressesCDCEnabled == 0 {
		sql := fmt.Sprintf(`USE %s;
			EXEC sys.sp_cdc_enable_db;
			EXEC sys.sp_cdc_enable_table
				@source_schema = N'dbo',
				@source_name   = N'user_addresses',
				@role_name     = NULL,
				@supports_net_changes = 1;`, f.dbName)
		_, err = f.dbSQL.Exec(sql)
		if err != nil {
			return err
		}
		fmt.Printf("UserAddresses table EnableCDC: %s\n", sql)
	} else {
		fmt.Println("UserAddresses table CDC already enabled")
	}

	return nil
}

func (f *DBFacker) DisableTableConstraint() error {
	sql := fmt.Sprintf(`USE %s;
		ALTER TABLE users NOCHECK CONSTRAINT ALL;
		ALTER TABLE user_addresses NOCHECK CONSTRAINT ALL;`, f.dbName)
	_, err := f.dbSQL.Exec(sql)
	return err
}

// func (f *DBFacker) EnableIdentityInsert() error {
// 	sql := fmt.Sprintf(`USE %s;
// 		SET IDENTITY_INSERT users ON;
// 		SET IDENTITY_INSERT user_addresses ON;`, f.dbName)
// 	_, err := f.dbSQL.Exec(sql)
// 	return err
// }

func (f *DBFacker) newFakeUserData(addrNum int) (User, error) {
	user := User{}
	if err := faker.FakeData(&user); err != nil {
		return User{}, fmt.Errorf("failed to create fake user: %w", err)
	}
	type fakerAddress struct {
		RealAddress faker.RealAddress `faker:"real_address"`
	}

	user.Address = []UserAddress{}
	for i := 0; i < addrNum; i++ {
		addr1 := fakerAddress{}
		if err := faker.FakeData(&addr1); err != nil {
			return User{}, fmt.Errorf("failed fake realAdress: %w", err)
		}
		user.Address = append(user.Address, UserAddress{
			Address:    addr1.RealAddress.Address,
			City:       addr1.RealAddress.City,
			State:      addr1.RealAddress.State,
			PostalCode: addr1.RealAddress.PostalCode,
		})
	}
	return user, nil
}

func (f *DBFacker) InsertFakeData(num int) error {
	if num <= 0 {
		return nil
	}

	// batch insert of 50 records
	batchSize := 50
	if num < batchSize {
		batchSize = num
	}

	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	for i := 0; i < num/batchSize; i++ {
		users := []User{}
		for j := 0; j < batchSize; j++ {
			user, err := f.newFakeUserData(r.Intn(3) + 1) // create 1~3 addresses
			if err != nil {
				return err
			}
			users = append(users, user)
		}
		if err := f.GormDB.CreateInBatches(users, batchSize).Error; err != nil {
			return err
		}
	}
	return nil
}

func (f *DBFacker) DeleteUserAndAddress(num int) error {
	if num <= 0 {
		return nil
	}

	var users []User
	if err := f.GormDB.Order("id desc").Limit(num).Find(&users).Error; err != nil {
		return err
	}

	for _, user := range users {
		// Delete UserAddress records related to the user
		if err := f.GormDB.Where("user_id = ?", user.ID).Delete(UserAddress{}).Error; err != nil {
			return err
		}

		// Delete the user
		if err := f.GormDB.Delete(&user).Error; err != nil {
			return err
		}
	}
	return nil
}

func (f *DBFacker) UpdateUserAndAddress(num int) error {
	if num <= 0 {
		return nil
	}

	var users []User
	if err := f.GormDB.Order("id asc").Limit(num).Find(&users).Error; err != nil {
		return err
	}

	for _, user := range users {
		// Update the user
		user.Username = faker.Username()
		user.Password = faker.Password()
		user.Email = faker.Email()
		if err := f.GormDB.Save(&user).Error; err != nil {
			return err
		}

		// Update UserAddress records related to the user
		var addresses []UserAddress
		if err := f.GormDB.Where("user_id = ?", user.ID).Find(&addresses).Error; err != nil {
			return err
		}

		type fakerAddress struct {
			RealAddress faker.RealAddress `faker:"real_address"`
		}
		for _, address := range addresses {
			addr1 := fakerAddress{}
			if err := faker.FakeData(&addr1); err != nil {
				return fmt.Errorf("failed fake realAdress: %w", err)
			}
			address.Address = addr1.RealAddress.Address
			address.City = addr1.RealAddress.City
			address.State = addr1.RealAddress.State
			address.PostalCode = addr1.RealAddress.PostalCode
			if err := f.GormDB.Save(&address).Error; err != nil {
				return err
			}
		}
	}
	return nil
}

func (f *DBFacker) DeleteAllRecords() error {
	sql := fmt.Sprintf(`USE %s;
		DELETE FROM "user_addresses";
		DELETE FROM "users";`, f.dbName)
	_, err := f.dbSQL.Exec(sql)
	return err
}

func (f *DBFacker) QueryTablesRowCount() ([]TableRowCountInfo, error) {
	tablesRowCount := make([]TableRowCountInfo, 0)
	var usersCount int64
	if err := f.GormDB.Model(&User{}).Count(&usersCount).Error; err != nil {
		return tablesRowCount, err
	}
	tablesRowCount = append(tablesRowCount, TableRowCountInfo{
		Name:     "users",
		RowCount: usersCount,
	})
	var userAddressesCount int64
	if err := f.GormDB.Model(&UserAddress{}).Count(&userAddressesCount).Error; err != nil {
		return tablesRowCount, err
	}
	tablesRowCount = append(tablesRowCount, TableRowCountInfo{
		Name:     "user_addresses",
		RowCount: userAddressesCount,
	})
	return tablesRowCount, nil
}

func (f *DBFacker) QueryMSSQLTablePrimaryKey(ctx context.Context) (map[string]string, error) {
	type primaryKey struct {
		TableName string
		KeyName   string
	}

	pks := make([]primaryKey, 0)
	result := f.GormDB.WithContext(ctx).Raw(`
        SELECT
            KU.TABLE_NAME as TableName,
            KU.COLUMN_NAME as KeyName
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
        INNER JOIN
            INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS KU
              ON TC.CONSTRAINT_TYPE = 'PRIMARY KEY' AND
                 TC.CONSTRAINT_NAME = KU.CONSTRAINT_NAME AND
                 KU.table_name = TC.table_name
        WHERE TC.TABLE_CATALOG = ?`, f.dbName).Scan(&pks)

	if result.Error != nil {
		return nil, fmt.Errorf("get primary keys error: %w", result.Error)
	}

	sysTables := map[string]struct{}{
		"systranschemas":   {},
		"change_tables":    {},
		"ddl_history":      {},
		"lsn_time_mapping": {},
		"captured_columns": {},
		"index_columns":    {},
	}

	userTablePKs := make(map[string]string)
	for _, pk := range pks {
		if _, isSysTable := sysTables[pk.TableName]; !isSysTable {
			userTablePKs[pk.TableName] = pk.KeyName
		}
	}

	return userTablePKs, nil
}

func (f *DBFacker) QueryMSSQLTableNameList(ctx context.Context) ([]string, error) {
	tables := make([]string, 0)
	result := f.GormDB.WithContext(ctx).Raw("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = ?", f.dbName).Scan(&tables)
	if result.Error != nil {
		return nil, fmt.Errorf("get table list error: %w", result.Error)
	}

	sysTables := map[string]struct{}{
		"systranschemas":   {},
		"change_tables":    {},
		"ddl_history":      {},
		"lsn_time_mapping": {},
		"captured_columns": {},
		"index_columns":    {},
	}

	userTables := make([]string, 0, len(tables))
	for _, table := range tables {
		if _, isSysTable := sysTables[table]; !isSysTable {
			if strings.HasSuffix(table, "_CT") {
				continue
			}
			userTables = append(userTables, table)
		}
	}

	return userTables, nil
}
