cd /d "%~dp0"
CALL activate_bark.bat
python run.py %*
conda deactivate