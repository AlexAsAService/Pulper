package main

import (
	"fmt"
	"path/filepath"
	"strings"
)

type LibreOfficeTranspiler struct {
	state    DepState
	executor Executor
}

func NewLibreOfficeTranspiler(exec Executor) *LibreOfficeTranspiler {
	if exec == nil {
		exec = DefaultExecutor{}
	}
	return &LibreOfficeTranspiler{state: StateUnknown, executor: exec}
}

func (t *LibreOfficeTranspiler) Name() string {
	return "LibreOffice"
}

func (t *LibreOfficeTranspiler) Extensions() []string {
	return []string{".doc", ".odt", ".rtf", ".xls", ".ods", ".ppt", ".odp"}
}

func (t *LibreOfficeTranspiler) checkDeps() {
	if _, err := t.executor.LookPath("soffice"); err == nil {
		t.state = StateInstalled
	} else {
		t.state = StateMissing
	}
}

func (t *LibreOfficeTranspiler) Transpile(inputPath string) (string, error) {
	if t.state == StateUnknown {
		t.checkDeps()
	}
	if t.state == StateMissing {
		return "", ErrDepsMissing
	}

	targetExt := t.getTargetExt(inputPath)

	// CLI Arguments:
	// --headless: Runs LibreOffice without a graphical user interface (required for background/container processing).
	// --convert-to [ext]: Tells LibreOffice to convert the input document to the specified output format.
	// --outdir [dir]: LibreOffice requires an output directory rather than a specific output filename. It places the converted file here.
	if out, err := t.executor.Run("soffice", "--headless", "--convert-to", targetExt, "--outdir", AppConfig.ScratchDir, inputPath); err != nil {
		return "", fmt.Errorf("soffice failed: %w\nOutput: %s", err, string(out))
	}

	baseName := filepath.Base(inputPath)
	ext := filepath.Ext(baseName)
	nameWithoutExt := strings.TrimSuffix(baseName, ext)
	convertedFile := filepath.Join(AppConfig.ScratchDir, nameWithoutExt+"."+targetExt)

	return convertedFile, nil
}

func (t *LibreOfficeTranspiler) getTargetExt(inputPath string) string {
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
