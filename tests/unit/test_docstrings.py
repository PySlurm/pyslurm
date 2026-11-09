import doctest
import unittest
from pyslurm.utils import helpers

_FLAGS = doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE

_MODULES = [helpers]


def _make_doctest_method(obj):
    def test_method(self):
        finder = doctest.DocTestFinder()
        runner = doctest.DocTestRunner(optionflags=_FLAGS)
        for dt in finder.find(obj, obj.__name__):
            runner.run(dt)
        failed, _ = runner.summarize()
        assert failed == 0
    test_method.__name__ = f"test_{obj.__name__}"
    return test_method


def _build_suite(module):
    attrs = {}
    for name in dir(module):
        obj = getattr(module, name, None)
        if callable(obj) and ">>>" in (getattr(obj, "__doc__", None) or ""):
            attrs[f"test_{name}"] = _make_doctest_method(obj)
    return type(
        f"Docstrings_{module.__name__.split('.')[-1]}",
        (unittest.TestCase,),
        attrs,
    )


for _mod in _MODULES:
    _cls = _build_suite(_mod)
    globals()[_cls.__name__] = _cls
