package main

import (
	"errors"
	"strings"
	"testing"
)



func TestLibreOfficeTranspiler_DepsMissing(t *testing.T) {
	mockExec := &MockExecutor{
		LookPathFunc: func(file string) (string, error) {
			return "", errors.New("command not found")
		},
	}
	transpiler := NewLibreOfficeTranspiler(mockExec)

	_, err := transpiler.Transpile("test.doc", testScratchDir)
	
	if !errors.Is(err, ErrDepsMissing) {
		t.Errorf("Expected ErrDepsMissing, got: %v", err)
	}
	if len(mockExec.Commands) != 0 {
		t.Errorf("Expected 0 commands run, got %d", len(mockExec.Commands))
	}
}

func TestLibreOfficeTranspiler_Success(t *testing.T) {
	mockExec := &MockExecutor{}
	transpiler := NewLibreOfficeTranspiler(mockExec)

	// Since we mock success, we don't care that the temp output file won't exist
	_, err := transpiler.Transpile("test.doc", testScratchDir)
	
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	
	if len(mockExec.Commands) != 1 {
		t.Fatalf("Expected exactly 1 command to run, got %d", len(mockExec.Commands))
	}

	cmd := mockExec.Commands[0]
	// Verify the exact string we are passing to the OS
	if !strings.HasPrefix(cmd, "soffice --headless --convert-to docx --outdir") || !strings.HasSuffix(cmd, "test.doc") {
		t.Errorf("Command formatted incorrectly: %s", cmd)
	}
}

func TestLibreOfficeTranspiler_RunError(t *testing.T) {
	mockExec := &MockExecutor{
		RunFunc: func(name string, arg ...string) ([]byte, error) {
			return []byte("segfault"), errors.New("exit status 1")
		},
	}
	transpiler := NewLibreOfficeTranspiler(mockExec)

	_, err := transpiler.Transpile("test.doc", testScratchDir)
	
	if err == nil {
		t.Fatal("Expected an error from soffice crash, got nil")
	}
	if errors.Is(err, ErrDepsMissing) {
		t.Fatal("Expected a generic execution error, but got ErrDepsMissing")
	}
}
