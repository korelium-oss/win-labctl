# Install common Python libraries for data science and analysis
Write-Output "Upgrading pip..."
python -m pip install --upgrade pip

$libraries = @(
    "numpy",
    "pandas",
    "matplotlib",
    "seaborn",
    "scikit-learn",
    "scipy",
    "xgboost",
    "basepy",
    "colorama",
    "nltk",
    "wordcloud",
    "PAL",
    "keras",
    "tensorflow",
    "emnist",
    "opencv-python",
    "future",
    "itertools",
    "math",
    "random"
)

Write-Output "Installing Python libraries: $($libraries -join ', ')..."
foreach ($lib in $libraries) {
    Write-Output "Installing $lib..."
    python -m pip install $lib
}

Write-Output "Python library installation complete."
