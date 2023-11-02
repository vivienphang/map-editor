package maps

import "net/http"

type CustomError struct {
	Code int
	Message string
}

func (e *CustomError) Error() string {
	return e.Message
}

func (e *CustomError) ErrCode() int {
	return e.Code
}

func InvalidUUIDError() (*CustomError) {
	err := CustomError{}
	err.Code = http.StatusNotAcceptable
	err.Message = "Invalid UUID format"
	return &err
}

func NotFoundError() (*CustomError) {
	err := CustomError{}
	err.Code = http.StatusNotFound
	err.Message = "UUID not found"
	return &err
}

func InternalServerError() (*CustomError) {
	err := CustomError{}
	err.Code = http.StatusInternalServerError
	err.Message = "Internal Server Error, try again"
	return &err
}

func BadRequestError() (*CustomError) {
	err := CustomError{}
	err.Code = http.StatusBadRequest
	err.Message = "Bad Request Body, try again"
	return &err
}

func MapCreationError() (*CustomError) {
	err := CustomError{}
	err.Code = http.StatusBadRequest
	err.Message = "Error creating map, try again"
	return &err
}

func MapUpdateError() (*CustomError) {
	err := CustomError{}
	err.Code = http.StatusInternalServerError
	err.Message = "Error updating map, try again"
	return &err
}

func MapDeletionError() (*CustomError) {
	err := CustomError{}
	err.Code = http.StatusInternalServerError
	err.Message = "Error deleting map, try again"
	return &err
}