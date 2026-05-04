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
	// 1. Initialize transpilers
	executor := DefaultExecutor{}
	transpilers := []Transpiler{
		NewLibreOfficeTranspiler(executor),
		NewFFmpegTranspiler(executor),
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
	extMap := make(map[string]Transpiler)
	for _, t := range transpilers {
		for _, ext := range t.Extensions() {
			if existing, ok := extMap[ext]; ok {
				fmt.Printf("Error: Transpiler overlap detected for extension %s between %s and %s\n", ext, existing.Name(), t.Name())
				os.Exit(1)
			}
			extMap[ext] = t
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

	// 6. Transpilation Logic
	finalPath := inputPath
	ext := strings.ToLower(filepath.Ext(inputPath))

	if t, ok := extMap[ext]; ok {
		fmt.Printf("Routing %s to %s transpiler...\n", filepath.Base(inputPath), t.Name())
		newPath, err := t.Transpile(inputPath)
		if err != nil {
			if errors.Is(err, ErrDepsMissing) {
				fmt.Printf("  -> [SKIP] %s dependencies missing. Falling back to native MarkItDown.\n", t.Name())
			} else {
				fmt.Printf("  -> [ERROR] Transpilation failed: %v\n", err)
				os.Exit(1)
			}
		} else {
			fmt.Printf("  -> [SUCCESS] Transpiled intermediate file: %s\n", filepath.Base(newPath))
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
