cd /d "%~dp0"
CALL activate_stablelm.bat
python run.py %*
conda deactivate