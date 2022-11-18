# step2.sh [ make_ctest.sh   make -j 24; ctest ]
# --

mydate=$(date '+%Y-%m-%d')
base=/glade/scratch/$USER/br_autotest/br_$mydate
[[ $# -ge 1 ]] && base=/glade/scratch/$USER/br_autotest/br_$1
mkdir -p $base; cd $base

source  ./mpas-bundle/env-setup/gnu-openmpi-cheyenne.sh
f=z.ctest.all
cd build
make -j16 &> zb
cd mpas-jedi
ctest -VV &> $f
res_test=`grep -i "tests passed" $f`


# analyze test results
# --
percent=$( echo $res_test | awk '{print $1}' | cut -d% -f1 )
echo "percent= $percent"
if [[ -f "$base/build/bin/mpasjedi_variational.x" ]]; then
  ib=0  # build sus
  if [[ $percent -eq 100 ]] ; then
    ictest=0
    s="success"
  else
    ictest=1
    s="fail"   # ctest failure  
  fi 
  else  
    ib=1  # build failure
    s="fail"
fi


# Report 
# --
cat > z.report <<EOF
  Report : $mydate
  dir    : $base
EOF

if [[ $ib -eq 0 ]] && [[ $ictest -eq 0 ]]; then
cat >> z.report <<EOF
  Build  : success
  Ctest  : success
EOF

elif [[ $ib -eq 0 ]] && [[ $ictest -eq 1 ]]; then
cat >> z.report <<EOF
  Build  : success
  Ctest  : failure
EOF

elif [[ $ib -eq 1 ]]; then
cat >> z.report <<EOF
  Build  : failure
  Ctest  : NaN
EOF

else
cat > z.report <<EOF
  Build  : Abnormal results
  Ctest  : NaN
EOF
fi

echo ""  >> z.report
grep -A20 "tests passed" $f >> z.report
note="ctest = $s"
cat z.report | mail -s "$mydate cron : $note" $USER@ucar.edu
rm -f z.report


# check hash number for git tag
# --
f="CMakeLists.txt"
cd $base/mpas-bundle
cp -rp $f $f.org
source .github/stable_mark.sh
mv $f  $base/../${f}_${mydate}_$s
cp -rp $f.org $f
