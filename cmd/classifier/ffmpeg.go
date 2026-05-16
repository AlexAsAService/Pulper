package main

import (
	"fmt"
	"path/filepath"
	"strings"
)

type FFmpegConverter struct {
	state    DepState
	executor Executor
}

func NewFFmpegConverter(exec Executor) *FFmpegConverter {
	if exec == nil {
		exec = DefaultExecutor{}
	}
	return &FFmpegConverter{state: StateUnknown, executor: exec}
}

func (c *FFmpegConverter) Name() string {
	return "FFmpeg"
}

func (c *FFmpegConverter) Extensions() []string {
	return []string{".wav", ".mp3", ".m4a", ".flac", ".ogg"}
}

func (c *FFmpegConverter) checkDeps() {
	if _, err := c.executor.LookPath("ffmpeg"); err == nil {
		c.state = StateInstalled
	} else {
		c.state = StateMissing
	}
}

func (c *FFmpegConverter) Convert(inputPath string) (string, error) {
	if c.state == StateUnknown {
		c.checkDeps()
	}
	if c.state == StateMissing {
		return "", ErrDepsMissing
	}

	baseName := filepath.Base(inputPath)
	ext := filepath.Ext(baseName)
	nameWithoutExt := strings.TrimSuffix(baseName, ext)
	convertedFile := filepath.Join(AppConfig.ScratchDir, nameWithoutExt+".wav")
	// CLI Arguments:
	// -y: Overwrite output files without asking for confirmation.
	// -i [input]: Specifies the input file.
	// -acodec pcm_s16le: Sets the audio codec to uncompressed 16-bit PCM (standard for STT).
	// -ar 16000: Sets the audio sample rate to 16kHz (optimal for Whisper/speech models).
	// -ac 1: Downmixes the audio to 1 channel (mono).
	if out, err := c.executor.Run("ffmpeg", "-y", "-i", inputPath, "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", convertedFile); err != nil {
		return "", fmt.Errorf("ffmpeg failed: %w\nOutput: %s", err, string(out))
	}

	return convertedFile, nil
}
