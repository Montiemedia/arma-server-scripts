.PHONY: test package

test:
	bash -n scripts/arma3ctl scripts/start-server.sh scripts/bootstrap.sh tests/test_start_server.sh
	python3 -m py_compile backend/app.py scripts/lowercase_tree.py
	python3 tests/test_lowercase_tree.py
	python3 tests/test_config.py
	bash tests/test_start_server.sh
	@if command -v node >/dev/null 2>&1; then node --check frontend/app.js; fi

package:
	tar -czf ../arma3-control.tar.gz --exclude='.venv' --exclude='__pycache__' .
