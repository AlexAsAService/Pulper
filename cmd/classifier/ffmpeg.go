package main

import (
	"fmt"
	"os"
)

type FFmpegTranspiler struct {
	state    DepState
	executor Executor
}

func NewFFmpegTranspiler(exec Executor) *FFmpegTranspiler {
	if exec == nil {
		exec = DefaultExecutor{}
	}
	return &FFmpegTranspiler{state: StateUnknown, executor: exec}
}

func (t *FFmpegTranspiler) Name() string {
	return "FFmpeg"
}

func (t *FFmpegTranspiler) Extensions() []string {
	return []string{".wav", ".mp3", ".m4a", ".flac", ".ogg"}
}

func (t *FFmpegTranspiler) checkDeps() {
	if _, err := t.executor.LookPath("ffmpeg"); err == nil {
		t.state = StateInstalled
	} else {
		t.state = StateMissing
	}
}

func (t *FFmpegTranspiler) Transpile(inputPath string) (string, error) {
	if t.state == StateUnknown {
		t.checkDeps()
	}
	if t.state == StateMissing {
		return "", ErrDepsMissing
	}

	// We create a unique temporary file inside the centralized ScratchDir.
	tempFile, err := os.CreateTemp(AppConfig.ScratchDir, "ffmpeg-*.wav")
	if err != nil {
		return "", fmt.Errorf("failed to create temp file: %w", err)
	}
	convertedFile := tempFile.Name()
	tempFile.Close() // FFmpeg will overwrite/write to this path

	// CLI Arguments:
	// -y: Overwrite output files without asking for confirmation.
	// -i [input]: Specifies the input file.
	// -acodec pcm_s16le: Sets the audio codec to uncompressed 16-bit PCM (standard for STT).
	// -ar 16000: Sets the audio sample rate to 16kHz (optimal for Whisper/speech models).
	// -ac 1: Downmixes the audio to 1 channel (mono).
	if out, err := t.executor.Run("ffmpeg", "-y", "-i", inputPath, "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1", convertedFile); err != nil {
		return "", fmt.Errorf("ffmpeg failed: %w\nOutput: %s", err, string(out))
	}

	return convertedFile, nil
}
