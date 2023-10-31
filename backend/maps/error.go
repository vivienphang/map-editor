package maps

import "net/http"

type InvalidUUIDError struct {
	Code int
	Error string
}

func NewInvalidUUIDError() (*InvalidUUIDError) {
	err := &InvalidUUIDError{}
	err.Code = http.StatusNotAcceptable
	err.Error = "Invalid UUID format"
	return err
}