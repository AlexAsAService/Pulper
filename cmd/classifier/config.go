package main

import (
	"fmt"
	"os"
)

// Config holds global configuration settings for the classifier engine.
type Config struct {
	// ScratchDir is a centralized, temporary directory where all intermediate
	// transpiled files are stored before being handed off to MarkItDown.
	ScratchDir string
}

// AppConfig is the global configuration instance accessible from any file in the package.
var AppConfig *Config

// InitConfig initializes the global AppConfig. In the future, this will load from environment variables.
func InitConfig() {
	dir, err := os.MkdirTemp("", "pulper-scratch-*")
	if err != nil {
		fmt.Printf("Error creating scratch directory: %v\n", err)
		os.Exit(1)
	}
	AppConfig = &Config{
		ScratchDir: dir,
	}
}

// Cleanup removes any temporary resources created by the configuration.
// This should be called via defer in main().
func (c *Config) Cleanup() {
	if c != nil {
		if c.ScratchDir != "" {
			os.RemoveAll(c.ScratchDir)
		}
	}
}
