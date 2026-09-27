#!/usr/bin/env bash
# 릴스 편집 도구 설치 스크립트 (macOS)
# 사용법: bash setup_reels_tools.sh
set -euo pipefail

MODEL_NAME="ggml-large-v3-turbo-q5_0.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL_NAME}"
MODEL_DIR="$HOME/.cache/whisper"
VENV_DIR="$HOME/.pycapcut"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "이 스크립트는 macOS용입니다." >&2
  exit 1
fi

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  # Apple Silicon / Intel 기본 경로에 이미 설치돼 있으면 PATH만 잡아준다
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$p" ]] && eval "$("$p" shellenv)" && break
  done
fi
if ! command -v brew >/dev/null 2>&1; then
  cat <<'EOF'
==> Homebrew가 없습니다. 설치에 맥 비밀번호가 필요하니 아래 명령을 터미널에 직접 붙여넣으세요:

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

설치가 끝나면 화면 마지막 "Next steps"에 나오는 두 줄(eval ... shellenv)을 실행한 뒤,
이 스크립트를 다시 실행하세요: bash setup_reels_tools.sh
EOF
  exit 1
fi

# 2. yt-dlp, ffmpeg, whisper-cpp
echo "==> brew install yt-dlp ffmpeg whisper-cpp"
brew install yt-dlp ffmpeg whisper-cpp

# 3. whisper 모델
mkdir -p "$MODEL_DIR"
if [[ -s "$MODEL_DIR/$MODEL_NAME" ]]; then
  echo "==> 모델이 이미 있습니다: $MODEL_DIR/$MODEL_NAME"
else
  echo "==> 모델 다운로드 (약 550MB): $MODEL_NAME"
  curl -L --fail -C - -o "$MODEL_DIR/$MODEL_NAME.part" "$MODEL_URL"
  mv "$MODEL_DIR/$MODEL_NAME.part" "$MODEL_DIR/$MODEL_NAME"
fi

# 4. pycapcut 가상환경
PYTHON_BIN="$(command -v python3 || true)"
if [[ -z "$PYTHON_BIN" ]]; then
  brew install python
  PYTHON_BIN="$(brew --prefix)/bin/python3"
fi
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  echo "==> 가상환경 생성: $VENV_DIR"
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install --upgrade pycapcut

# 6. 버전 확인
echo
echo "==> 설치된 버전"
echo "brew        : $(brew --version | head -1)"
echo "yt-dlp      : $(yt-dlp --version)"
echo "ffmpeg      : $(ffmpeg -version | head -1)"
echo "whisper-cpp : $(brew list --versions whisper-cpp)"
echo "whisper 모델: $(ls -lh "$MODEL_DIR/$MODEL_NAME" | awk '{print $5, $9}')"
echo "python      : $("$VENV_DIR/bin/python" --version)"
echo "pycapcut    : $("$VENV_DIR/bin/python" -m pip show pycapcut | awk '/^Version/{print $2}')"
echo
echo "설치 끝!"
