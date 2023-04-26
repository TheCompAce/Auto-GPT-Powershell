conda create -n Bark python=3.8
CALL activate_bark.bat
pip install git+https://github.com/suno-ai/bark.git
pip install ipython
pip install soundfile
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
conda deactivate
Echo Completed.