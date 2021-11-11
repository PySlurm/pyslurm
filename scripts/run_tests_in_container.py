import testinfra


def test_run():
    host = testinfra.get_host(f"docker://slurmctl")
    print(host.check_output("python3.9 setup.py build"))
    print(host.check_output("python3.9 setup.py install"))
    print(host.check_output("./scripts/configure.sh"))
    print(host.check_output("pytest -v"))
