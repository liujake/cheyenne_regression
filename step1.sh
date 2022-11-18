#
# - step1.sh [ branch layout, check out bundle, ecbuild ]
#
mydate=$(date '+%Y-%m-%d')
base=/glade/scratch/$USER/br_autotest/br_$mydate
d_here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[[ $# -ge 1 ]] && base=/glade/scratch/$USER/br_autotest/br_$1
echo $base
mkdir -p $base; cd $base

ecbuild_option=""
if [[ ! -d mpas-bundle ]]; then
    echo " ! -d mpas-bundle "
    git clone  https://github.com/JCSDA-internal/mpas-bundle.git
fi
source  ./mpas-bundle/env-setup/gnu-openmpi-cheyenne.sh
[[ $# -ge 1 ]] && cp -rp ${d_here}/CMakeLists.txt  ./mpas-bundle/.

mkdir -p build
cd build
ecbuild  $ecbuild_option  ../mpas-bundle  &> za
