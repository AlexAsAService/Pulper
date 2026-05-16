package main

import (
	"fmt"
	"path/filepath"
	"strings"
)

type LibreOfficeConverter struct {
	state    DepState
	executor Executor
}

func NewLibreOfficeConverter(exec Executor) *LibreOfficeConverter {
	if exec == nil {
		exec = DefaultExecutor{}
	}
	return &LibreOfficeConverter{state: StateUnknown, executor: exec}
}

func (c *LibreOfficeConverter) Name() string {
	return "LibreOffice"
}

func (c *LibreOfficeConverter) Extensions() []string {
	return []string{".doc", ".odt", ".rtf", ".xls", ".ods", ".ppt", ".odp"}
}

func (c *LibreOfficeConverter) checkDeps() {
	if _, err := c.executor.LookPath("soffice"); err == nil {
		c.state = StateInstalled
	} else {
		c.state = StateMissing
	}
}

func (c *LibreOfficeConverter) Convert(inputPath string) (string, error) {
	if c.state == StateUnknown {
		c.checkDeps()
	}
	if c.state == StateMissing {
		return "", ErrDepsMissing
	}

	targetExt := c.getTargetExt(inputPath)

	// CLI Arguments:
	// --headless: Runs LibreOffice without a graphical user interface (required for background/container processing).
	// --convert-to [ext]: Tells LibreOffice to convert the input document to the specified output format.
	// --outdir [dir]: LibreOffice requires an output directory rather than a specific output filename. It places the converted file here.
	if out, err := c.executor.Run("soffice", "--headless", "--convert-to", targetExt, "--outdir", AppConfig.ScratchDir, inputPath); err != nil {
		return "", fmt.Errorf("soffice failed: %w\nOutput: %s", err, string(out))
	}

	baseName := filepath.Base(inputPath)
	ext := filepath.Ext(baseName)
	nameWithoutExt := strings.TrimSuffix(baseName, ext)
	convertedFile := filepath.Join(AppConfig.ScratchDir, nameWithoutExt+"."+targetExt)

	return convertedFile, nil
}

func (c *LibreOfficeConverter) getTargetExt(inputPath string) string {
	ext := strings.ToLower(filepath.Ext(inputPath))
	switch ext {
	case ".doc", ".odt", ".rtf":
		return "docx"
	case ".xls", ".ods":
		return "xlsx"
	case ".ppt", ".odp":
		return "pptx"
	}
	return "pdf" // Fallback
}
