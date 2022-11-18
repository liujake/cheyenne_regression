
# step3.sh [ use MPASWorkflow to test 1FC/1DA, all-DA 30-60-km dual 3denvar ]
# --
# usage:
# ./step3   case                         suffix   finalCyclePoint
#           3denvar_OIE120km_WarmStart    1DA   
#           3denvar_OIE120km_WarmStart    all   20180501T00
#           3denvar_O30kmIE60km_WarmStart 1DA   


mydate=$(date '+%Y-%m-%d')
case="3denvar_OIE120km_WarmStart"
suf=$mydate
finalCyclePoint=20180415T00
[[ $# -ge 1 ]] && echo $1 && case=$1  # override, optional
[[ $# -ge 2 ]] && echo $2 && suf=${mydate}_$2  # override, optional
[[ $# -ge 3 ]] && echo $3 && finalCyclePoint=$3  # override, optional
c1=$( echo $case | cut -d_ -f1 )
c2=$( echo $case | cut -d_ -f2 )


export PATH=$PATH:/opt/pbs/bin
base=/glade/scratch/$USER/br_autotest/br_$mydate
cd $base
cwd=`pwd`

flow=MPAS-Workflow_${suf}_$case
compiler="gnu-openmpi"
build="$cwd/build"
fconf="$cwd/$flow/config/scenario.csh"
fexp="$cwd/$flow/scenarios/${case}.yaml"
frc="$cwd/$flow/include/tasks.rc"
fenv="$cwd/$flow/config/environmentJEDI.csh"
faccount="$cwd/$flow/scenarios/base/job.yaml

[[ ! -d $flow ]] && git clone https://github.com/NCAR/MPAS-Workflow.git $flow

echo "flow = $flow"
echo "build= $build"
echo "suf  = $suf"
echo "case = $case"
echo "compiler = $compiler"
echo "fconf= $fconf"
echo "fexp = $fexp"
echo "frc  = $frc"
echo "fenv = $fenv"

#---- test .org exist ---- 
#
s="fconf fexp frc fenv" 
for i in $s; do
  j=$( eval echo \$${i} )
  if [[ ! -f ${j}.org ]]; then
     echo "non-exist: ${j}.org"
     cp ${j}  ${j}.org
  else
     cp ${j}.org  ${j}
  fi
done

sed -i "s#NMMM0043#NMMM0015#g" faccount
sed -i "s# scenario =.*# scenario = $case#g" $fconf
grep -v -e "-m =" $frc > zb
mv zb $frc
sed -i "s#setenv BuildCompiler.*#setenv BuildCompiler '$compiler'#g" $fenv

grep -i -v -e workflow -e InitializationType $fexp > zb
cat >> zb <<EOF
builds:
  commonBuild:  $build
experiment:
  ExpSuffix: '_$suf'
  ParentDirectorySuffix:  br_autotest/br_$mydate
#  ParentDirectorySuffix:  pandac
workflow:
  InitializationType: WarmStart
  initialCyclePoint: 20180414T18
  finalCyclePoint:   $finalCyclePoint
EOF
mv zb $fexp


#-- problem here for source

cd $flow
source /glade/u/home/${USER}/sftp/cheyenne.sh
./drive.csh  &> ../out.cron_4_flow_$suf


#-- check existence and completion

cd /glade/scratch/$USER/br_autotest/br_$mydate
cd ${USER}*${c1}*${c2}*
pwd
FDA="CyclingDA/2018041500/run/mem001/jedi.log"

a=0
tmax=720
until [[ -f $FDA ]] ; do
  echo "a = $a  wt for DA+FC completion"
  sleep 1m
  a=$(( a+1 ))
  if [ $a -ge $tmax ]; then
    echo "exceeds amax = $tmax; break until condition "
    break
  fi
done
conda deactivate


# FDA exist, then wait 3m for file to be completely written
sleep 10m
n=$( grep 'with status = 0'  $FDA | wc | awk '{print $1}' )
if [ $n -ne 1 ]; then
  mail -s "Fail: $mydate cron $case $suf $finalCyclePoint  "  $USER@ucar.edu
  exit
fi

time=$( grep 'OOPS_STATS Run end' $FDA | cut -d: -f2 | awk '{print $1}' )
cat >> $base/s.report <<EOF
case        = $case
suf         = $suf
1st_DA time = $time
EOF
cat $base/s.report | mail -s "$mydate cron $case $suf $finalCyclePoint  time "  $USER@ucar.edu
