"""Execute pytest inside the container."""

import os

import testinfra


def test_run():
    host = testinfra.get_host(f"docker://slurmctl")
    python = f'python{os.environ.get("PYTHON")}'
    print(host.check_output(f"{python} setup.py build"))
    print(host.check_output(f"{python} setup.py install"))
    print(host.check_output("./scripts/configure.sh"))
    print(host.check_output(f"{python} -m pip uninstall --yes pytest"))
    print(host.check_output(f"{python} -m pip install pytest"))
    print(host.check_output("pytest -v"))
