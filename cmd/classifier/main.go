package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

func main() {
	// 1. Initialize converters
	executor := DefaultExecutor{}
	converters := []Converter{
		NewLibreOfficeConverter(executor),
		NewFFmpegConverter(executor),
	}

	// 2. Fail fast if markitdown is missing
	binary, err := exec.LookPath("markitdown")
	if err != nil {
		fmt.Println("Error: markitdown not found in PATH")
		os.Exit(1)
	}

	// 3. Initialize Global Config
	InitConfig()
	defer AppConfig.Cleanup()

	// 4. Build the centralized capabilities map
	extMap := make(map[string]Converter)
	for _, c := range converters {
		for _, ext := range c.Extensions() {
			if existing, ok := extMap[ext]; ok {
				fmt.Printf("Error: Converter overlap detected for extension %s between %s and %s\n", ext, existing.Name(), c.Name())
				os.Exit(1)
			}
			extMap[ext] = c
		}
	}

	// 5. Handle Input
	args := os.Args[1:]
	if len(args) < 1 {
		fmt.Println("Usage: classifier <input_file> [markitdown_args...]")
		os.Exit(1)
	}

	inputPath := args[0]
	info, err := os.Stat(inputPath)
	if err != nil {
		fmt.Printf("Error: Cannot access input file '%s': %v\n", inputPath, err)
		os.Exit(1)
	}

	if info.IsDir() {
		fmt.Printf("Error: '%s' is a directory. This tool only processes individual files.\n", inputPath)
		os.Exit(1)
	}

	// 6. Conversion Logic
	finalPath := inputPath
	ext := strings.ToLower(filepath.Ext(inputPath))

	if c, ok := extMap[ext]; ok {
		fmt.Printf("Routing %s to %s converter...\n", filepath.Base(inputPath), c.Name())
		newPath, err := c.Convert(inputPath)
		if err != nil {
			if errors.Is(err, ErrDepsMissing) {
				fmt.Printf("  -> [SKIP] %s dependencies missing. Falling back to native MarkItDown.\n", c.Name())
			} else {
				fmt.Printf("  -> [ERROR] Conversion failed: %v\n", err)
				os.Exit(1)
			}
		} else {
			fmt.Printf("  -> [SUCCESS] Converted intermediate file: %s\n", filepath.Base(newPath))
			finalPath = newPath
		}
	}

	// 7. Execute MarkItDown
	fmt.Println("Handing off to MarkItDown...")
	markitdownArgs := []string{"markitdown", finalPath}
	if len(args) > 1 {
		markitdownArgs = append(markitdownArgs, args[1:]...)
	}

	err = syscall.Exec(binary, markitdownArgs, os.Environ())
	if err != nil {
		fmt.Printf("Failed to execute markitdown: %v\n", err)
		os.Exit(1)
	}
}
