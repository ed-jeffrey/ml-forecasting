.PHONY: bootstrap run test clean notebook install-jupyter

# Bootstrap: set up venv & install dependencies
bootstrap:
	@echo ">> Bootstrapping virtual environment with Poetry"
	poetry install

# Run the ml training script
run:
	poetry run model_training.py

# Run tests
test:
	poetry run pytest -v

# Remove caches
clean:
	rm -rf __pycache__ .pytest_cache .mypy_cache