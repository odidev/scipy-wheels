# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
# See env_vars.sh for extra environment variables
source gfortran-install/gfortran_utils.sh

function build_wheel {
    if [ -z "$IS_OSX" ]; then
        unset FFLAGS
        export LDFLAGS="-shared -Wl,-strip-all"
        #build_libs $PLAT
	if [ "aarch64" != "$PLAT" ]; then
            build_libs $PLAT;
	else
            yum update -y;
            #yum install -y atlas-devel lapack-devel gcc-gfortran gmp-devel mpfr-devel suitesparse-devel swig libmpc-devel wget;
            #yum install -y atlas-devel lapack-devel gmp-devel mpfr-devel suitesparse-devel swig libmpc-devel wget;
            #build_libs $PLAT;
            pip --version;
            pip install numpy
            #pip install https://files.pythonhosted.org/packages/0e/7a/10d4e79e0d141522736f41875e167041230c357351a512d2d8dcaeeb615d/numpy_mkp2020-1.14.5-cp37-cp37m-manylinux2014_aarch64.whl;
            #wget https://download-ib01.fedoraproject.org/pub/epel/7/aarch64/Packages/c/ccache-3.3.4-1.el7.aarch64.rpm;
            #rpm -Uvh ccache-3.3.4-1.el7.aarch64.rpm;
            #wget https://perso.univ-rennes1.fr/edouard.canot/f90cache/f90cache-0.99c.tar.gz;
            #tar -xzf f90cache-0.99c.tar.gz;
            #cd f90cache-0.99c;
            #./configure --prefix=/usr/local;
            #make -j32 && make install;
            #cd /usr/bin/;
            #sudo ln -s gfortran /usr/local/bin/gfortran;
            #sudo ln -s ccache /usr/local/bin/gcc;
            #sudo ln -s ccache /usr/local/bin/cc;
            #sudo ln -s ccache /usr/local/bin/c++;
            #sudo ln -s ccache /usr/local/bin/g++;
            #sudo ln -s ccache /usr/local/bin/aarch64-linux-gnu-g++;
            #sudo ln -s ccache /usr/local/bin/aarch64-linux-gnu-gcc;
        fi
        # Work round build dependencies spec in pyproject.toml
        build_bdist_wheel $@
    else
        export FFLAGS="$FFLAGS -fPIC"
        build_osx_wheel $@
    fi
}

function build_libs {
    PYTHON_EXE=`which python`
    $PYTHON_EXE -c"import platform; print('platform.uname().machine', platform.uname().machine)"
    basedir=$($PYTHON_EXE scipy/tools/openblas_support.py)
    $use_sudo cp -r $basedir/lib/* /usr/local/lib
    $use_sudo cp $basedir/include/* /usr/local/include
}

function set_arch {
    local arch=$1
    export CC="clang $arch"
    export CXX="clang++ $arch"
    export CFLAGS="$arch"
    export FFLAGS="$arch"
    export FARCH="$arch"
    export LDFLAGS="$arch"
}

function build_wheel_with_patch {
    # Patch numpy distutils to fix OpenBLAS build
    (cd .. && ./patch_numpy.sh)
    bdist_wheel_cmd $@
}

function build_osx_wheel {
    # Build 64-bit wheel
    # Standard gfortran won't build dual arch objects.
    local repo_dir=${1:-$REPO_DIR}
    local py_ld_flags="-Wall -undefined dynamic_lookup -bundle"

    install_gfortran
    # 64-bit wheel
    local arch="-m64"
    set_arch $arch
    build_libs x86_64
    # Build wheel
    export LDSHARED="$CC $py_ld_flags"
    export LDFLAGS="$arch $py_ld_flags"
    # Work round build dependencies spec in pyproject.toml
    # See e.g.
    # https://travis-ci.org/matthew-brett/scipy-wheels/jobs/387794282
    build_wheel_cmd "build_wheel_with_patch" "$repo_dir"
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    # OSX tests seem to time out pretty often
    apt update -y
    apt remove --purge g77 -y
    apt install libatlas-base-dev libblas-dev liblapack-dev -y
    apt autoremove -y
    
    if [ -z "$IS_OSX" ]; then
        local testmode="full"
    else
        local testmode="fast"
    fi
    # Check bundled license file
    python ../check_installed_package.py
    # Run tests
    python ../run_scipy_tests.py $testmode -- -n8 -rfEX
    # Show BLAS / LAPACK used
    python -c 'import scipy; scipy.show_config()'
}

function install_run {
    # Override multibuild test running command, to preinstall packages
    # that have to be installed before TEST_DEPENDS.
    pip install $(pip_opts) setuptools_scm

    # Copypaste from multibuild/common_utils.sh:install_run
    install_wheel
    mkdir tmp_for_test
    (cd tmp_for_test && run_tests)
}
