"""
run_scipy_tests.py TEST_MODE [-- PYTEST_ARGS..]

Run scipy tests allowing for pytest and nosetests
"""

import sys
import argparse


def main():
    p = argparse.ArgumentParser(usage=__doc__.strip())
    p.add_argument('test_mode', metavar='TEST_MODE')
    p.add_argument('pytest_args', metavar='PYTEST_ARGS', nargs='*')
    args = p.parse_args()

    import scipy
    pytest_args = args.pytest_args
    pytest_args += ['--durations=20']
    print("Scipy: {} {}".format(scipy.__version__, scipy.__path__))
    ret = scipy.test('fast', extra_argv=args.pytest_args)

    
    
    
    #import scipy.special
    #import scipy.stats
    #
    #pytest_args = args.pytest_args
    #pytest_args += ['--durations=20']
    #ret = scipy.special.test(args.test_mode, extra_argv=pytest_args, verbose=2)
    #ret = scipy.stats.test(args.test_mode, extra_argv=pytest_args, verbose=2)
    #import scipy.weave
    #ret = scipy.weave.test(args.test_mode, extra_argv=pytest_args, verbose=2)
    
    
    
    
    
    
    
    if hasattr(ret, 'wasSuccessful'):
        # Nosetests version
        ret = ret.wasSuccessful()

    sys.exit(not ret)


if __name__ == "__main__":
    main()

