package main

// Config holds global configuration settings for the classifier engine.
type Config struct {
	// ScratchDir is a centralized, temporary directory where all intermediate
	// transpiled files are stored before being handed off to MarkItDown.
	ScratchDir string
}
