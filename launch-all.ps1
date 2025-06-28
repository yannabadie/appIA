# launch-all.ps1
$env:FLASK_APP = "web_interface/app.py"
$env:PYTHONPATH = "."
python -m flask run --host=0.0.0.0 --port=5000
