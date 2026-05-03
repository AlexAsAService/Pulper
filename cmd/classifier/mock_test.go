package main

import "strings"

const testScratchDir = "/tmp"

// MockExecutor implements Executor for testing
type MockExecutor struct {
	LookPathFunc func(file string) (string, error)
	RunFunc      func(name string, arg ...string) ([]byte, error)
	Commands     []string
}

func (m *MockExecutor) LookPath(file string) (string, error) {
	if m.LookPathFunc != nil {
		return m.LookPathFunc(file)
	}
	return "/usr/bin/" + file, nil // Default: always found
}

func (m *MockExecutor) Run(name string, arg ...string) ([]byte, error) {
	cmdStr := name + " " + strings.Join(arg, " ")
	m.Commands = append(m.Commands, cmdStr)
	
	if m.RunFunc != nil {
		return m.RunFunc(name, arg...)
	}
	return []byte("mock success"), nil
}
