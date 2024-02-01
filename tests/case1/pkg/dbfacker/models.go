package dbfacker

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BaseModel struct {
	ID        uuid.UUID `gorm:"size:36;primary_key" faker:"-"`
	CreatedAt time.Time `faker:"-"`
	UpdatedAt time.Time `faker:"-"`
}

func (model *BaseModel) BeforeCreate(tx *gorm.DB) error {
	uuid, err := uuid.NewRandom()
	if err != nil {
		return err
	}

	tx.Statement.SetColumn("ID", uuid.String())
	return nil
}

type User struct {
	BaseModel
	Username string        `faker:"username"`
	Password string        `faker:"password"`
	Email    string        `faker:"email"`
	Address  []UserAddress `gorm:"foreignKey:UserID" faker:"-"`
}

type UserAddress struct {
	BaseModel
	Address    string
	City       string
	State      string
	PostalCode string
	UserID     string `gorm:"type:varchar(36)" faker:"-"`
}
