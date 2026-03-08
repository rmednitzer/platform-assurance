.PHONY: render validate

render:
	python3 scripts/render_controls.py

validate: render
	python3 scripts/validate_repo.py
