"""Execute pytest inside the container."""

import os

import testinfra

version_map = {
    "3.6": "3.6.15",
    "3.7": "3.7.12",
    "3.8": "3.8.12",
    "3.9": "3.9.9",
    "3.10": "3.10.0",
}


def test_run():
    host = testinfra.get_host(f"docker://slurmctl")
    python = f'python{os.environ.get("PYTHON")}'
    host.run(f'pyenv global {version_map[os.environ.get("PYTHON")]}')
    print(host.check_output(f"{python} setup.py build"))
    print(host.check_output(f"{python} setup.py install"))
    print(host.check_output("./scripts/configure.sh"))
    print(host.check_output(f"{python} -m pip uninstall --yes pytest"))
    print(host.check_output(f"{python} -m pip install pytest"))
    print(host.check_output("pytest -v"))
