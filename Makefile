.PHONY: test package

test:
	bash -n install.sh scripts/arma3ctl scripts/arma3-menu.sh scripts/start-server.sh scripts/bootstrap.sh tests/test_install.sh tests/test_arma3_menu.sh tests/test_remove_mod.sh tests/test_start_server.sh tests/test_arma3ctl_mod_failures.sh
	python3 -m py_compile backend/app.py scripts/lowercase_tree.py
	python3 tests/test_lowercase_tree.py
	python3 tests/test_config.py
	bash tests/test_install.sh
	bash tests/test_arma3_menu.sh
	bash tests/test_remove_mod.sh
	bash tests/test_start_server.sh
	bash tests/test_arma3ctl_mod_failures.sh
	@if command -v node >/dev/null 2>&1; then node --check frontend/app.js; fi

package:
	tar -czf ../arma3-control.tar.gz --exclude='.venv' --exclude='__pycache__' .
