import subprocess
import sys
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

scripts = [
    "import_dimensions.py",
    "import_eurocontrol.py",
    "import_weather.py",
    # "import_opdi.py",  # TODO [Sebastian]
]

for script in scripts:
    print(f"\n{'='*50}")
    print(f"Starte {script}...")
    print(f"{'='*50}")
    
    result = subprocess.run([sys.executable, script], check=True)
    
    print(f"{script} erfolgreich abgeschlossen.")

print("\nAlle Imports abgeschlossen.")