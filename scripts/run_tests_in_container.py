"""Execute pytest inside the container."""

import os
import sys

import testinfra


def test_run():
    host = testinfra.get_host(f"docker://slurmctl")
    python_full = os.environ.get("PYTHON")
    python_short = ".".join([str(sys.version_info.major), str(sys.version_info.minor)])
    print(host.check_output(f"pyenv global {python_full}"))
    print(host.check_output(f"python{python_short} setup.py build"))
    print(host.check_output(f"python{python_short} setup.py install"))
    print(host.check_output("./scripts/configure.sh"))
    print(host.check_output(f"python{python_short} -m pip uninstall --yes pytest"))
    print(host.check_output(f"python{python_short} -m pip install pytest"))
    print(host.check_output("pytest -v"))
