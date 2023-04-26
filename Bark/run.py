import argparse
from bark import SAMPLE_RATE, generate_audio, preload_models
from IPython.display import Audio
from scipy.io.wavfile import write as write_wav

# argument parser
parser = argparse.ArgumentParser(description="Generate audio from text.")
parser.add_argument('-p', '--prompt', required=True, help="Text prompt to generate audio from")
parser.add_argument('-f', '--file', default="audio.wav", help="Output audio file name (default: audio.wav)")
parser.add_argument('--text_use_small', action='store_true', default=False, help="Use small text model (default: False)")
parser.add_argument('--coarse_use_small', action='store_true', default=True, help="Use small coarse model (default: True)")
parser.add_argument('--fine_use_gpu', action='store_true', default=True, help="Use GPU for fine model (default: True)")
parser.add_argument('--fine_use_small', action='store_true', default=False, help="Use small fine model (default: False)")
parser.add_argument('-v', '--voice', default="", help="Voice string (default: empty)")

args = parser.parse_args()

# download and load all models
preload_models(
    text_use_small=args.text_use_small,
    coarse_use_small=args.coarse_use_small,
    fine_use_gpu=args.fine_use_gpu,
    fine_use_small=args.fine_use_small,
)

# generate audio from text
text_prompt = args.prompt
if args.voice:
    history_prompt = args.voice
    audio_array = generate_audio(text_prompt, history_prompt=history_prompt)
else:
    audio_array = generate_audio(text_prompt)

# save audio to file
write_wav(args.file, SAMPLE_RATE, audio_array)
