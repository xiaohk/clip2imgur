conda activate clip2imgur
bumpversion patch
python3 -m build
python3 -m twine upload --repository clip2imgur --skip-existing dist/*