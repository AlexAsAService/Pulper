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

	args := os.Args[1:]
	if len(args) < 1 {
		fmt.Println("Usage: classifier <input_dir_or_file> [markitdown_args...]")
		os.Exit(1)
	}

	inputTarget := args[0]
	fmt.Printf("Analyzing input target: %s\n", inputTarget)

	info, err := os.Stat(inputTarget)
	if err != nil {
		fmt.Printf("Error accessing input target: %v\n", err)
		os.Exit(1)
	}

	// 5. Walk the directory (or process single file)
	var filesToProcess []string
	if info.IsDir() {
		err = filepath.Walk(inputTarget, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if !info.IsDir() {
				filesToProcess = append(filesToProcess, path)
			}
			return nil
		})
		if err != nil {
			fmt.Printf("Error walking directory: %v\n", err)
			os.Exit(1)
		}
	} else {
		filesToProcess = append(filesToProcess, inputTarget)
	}

	// 6. The "Chute" logic for batch processing
	var markitdownInputs []string
	for _, inputPath := range filesToProcess {
		ext := strings.ToLower(filepath.Ext(inputPath))
		
		if t, ok := extMap[ext]; ok {
			fmt.Printf("Routing %s to %s transpiler...\n", filepath.Base(inputPath), t.Name())
			newPath, err := t.Transpile(inputPath)
			if err != nil {
				if errors.Is(err, ErrDepsMissing) {
					fmt.Printf("  -> [SKIP] %s dependencies missing. Falling back to native MarkItDown.\n", t.Name())
					markitdownInputs = append(markitdownInputs, inputPath)
				} else {
					fmt.Printf("  -> [ERROR] Transpilation failed: %v\n", err)
					os.Exit(1)
				}
			} else {
				fmt.Printf("  -> [SUCCESS] Transpiled intermediate file: %s\n", filepath.Base(newPath))
				markitdownInputs = append(markitdownInputs, newPath)
			}
		} else {
			// No transpiler needed
			markitdownInputs = append(markitdownInputs, inputPath)
		}
	}

	// 7. Execute MarkItDown
	fmt.Println("Handing off to MarkItDown...")
	
	markitdownArgs := []string{"markitdown"}
	markitdownArgs = append(markitdownArgs, markitdownInputs...)
	if len(args) > 1 {
		markitdownArgs = append(markitdownArgs, args[1:]...)
	}

	err = syscall.Exec(binary, markitdownArgs, os.Environ())
	if err != nil {
		fmt.Printf("Failed to execute markitdown: %v\n", err)
		os.Exit(1)
	}
}
