package main

import (
	"errors"
	"os/exec"
)

// Executor defines an interface for system command execution to allow mocking in tests.
type Executor interface {
	LookPath(file string) (string, error)
	Run(name string, arg ...string) ([]byte, error)
}

// DefaultExecutor implements Executor using the os/exec package.
type DefaultExecutor struct{}

func (d DefaultExecutor) LookPath(file string) (string, error) {
	return exec.LookPath(file)
}

func (d DefaultExecutor) Run(name string, arg ...string) ([]byte, error) {
	return exec.Command(name, arg...).CombinedOutput()
}

// ErrDepsMissing is returned when a transpiler is asked to run but lacks required system tools.
var ErrDepsMissing = errors.New("required dependencies are not installed")

// DepState represents the cached state of a transpiler's required system dependencies.
type DepState int

const (
	StateUnknown DepState = iota
	StateInstalled
	StateMissing
)

// Transpiler defines the interface for any capability that can transform a file.
type Transpiler interface {
	// Extensions returns a list of file extensions this transpiler handles (e.g., []string{".doc", ".rtf"}).
	Extensions() []string
	// Transpile performs the conversion. It checks dependencies lazily on first run.
	// It returns the path to the newly transpiled file, which is then passed to MarkItDown.
	Transpile(inputPath string) (string, error)
	// Name returns the name of the transpiler (for logging).
	Name() string
}
