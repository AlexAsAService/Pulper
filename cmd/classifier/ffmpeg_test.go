package main

import (
	"errors"
	"strings"
	"testing"
)

func TestFFmpegTranspiler_DepsMissing(t *testing.T) {
	mockExec := &MockExecutor{
		LookPathFunc: func(file string) (string, error) {
			return "", errors.New("command not found")
		},
	}
	transpiler := NewFFmpegTranspiler(mockExec)

	_, err := transpiler.Transpile("test.wav")
	
	if !errors.Is(err, ErrDepsMissing) {
		t.Errorf("Expected ErrDepsMissing, got: %v", err)
	}
}

func TestFFmpegTranspiler_Success(t *testing.T) {
	mockExec := &MockExecutor{}
	transpiler := NewFFmpegTranspiler(mockExec)

	_, err := transpiler.Transpile("test.mp3")
	
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
	
	if len(mockExec.Commands) != 1 {
		t.Fatalf("Expected exactly 1 command to run, got %d", len(mockExec.Commands))
	}

	cmd := mockExec.Commands[0]
	// Verify ffmpeg audio normalization args
	expectedArgs := "ffmpeg -y -i test.mp3 -acodec pcm_s16le -ar 16000 -ac 1"
	if !strings.HasPrefix(cmd, expectedArgs) || !strings.HasSuffix(cmd, ".wav") {
		t.Errorf("Command formatted incorrectly: %s", cmd)
	}
}

func TestFFmpegTranspiler_RunError(t *testing.T) {
	mockExec := &MockExecutor{
		RunFunc: func(name string, arg ...string) ([]byte, error) {
			return []byte("core dumped"), errors.New("exit status 1")
		},
	}
	transpiler := NewFFmpegTranspiler(mockExec)

	_, err := transpiler.Transpile("test.mp3")
	
	if err == nil {
		t.Fatal("Expected an error from ffmpeg crash, got nil")
	}
	if errors.Is(err, ErrDepsMissing) {
		t.Fatal("Expected a generic execution error, but got ErrDepsMissing")
	}
}
