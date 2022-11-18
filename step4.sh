# step4.sh [ search valid date between 7 and 14 days, graph d2 vs d1 ]

export PATH=$PATH:/opt/pbs/bin
mydate=$(date '+%Y-%m-%d')
base=/glade/scratch/$USER/br_autotest
d_build=${base}/build
d_s="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


#d1=$(date '+%Y-%m-%d')
d1="2022-07-26"
j=7
key="${USER}_3denvar-60-iter_OIE120km_WarmStart"
while [ $j -le 14 ]; do
 d2=$(date --date="$j day  ago" +"%Y-%m-%d")
 f="$base/br_$d2/${key}_br_${d2}_all/CyclingDA/2018050100/run/mem001/jedi.log"
 if [[ -f $f ]]; then
     is=$( grep "with status =" $f | cut -d= -f2 )
     if [[ $is -eq 0 ]]; then  
         echo "found:  d2=$d2 f=$f"
         echo "j=$j,  is=$is"
         break
     fi
 else
     echo "not found:  f=$f"
 fi
 j=$(( j+1 ))
done
if [ $j -gt 14 ]; then 
  echo "failed to find any successful dir"
  exit -1
fi


T0=$d2
T1=$d1
dX0="br_$T0/${key}_br_${T0}_all"
dX1="br_$T1/${key}_br_${T1}_all"
f_an="analyze_config.py"
cd $base/br_${d1}/mpas-bundle/mpas-jedi/graphics
# source /glade/u/home/${USER}/sftp/cheyenne.sh



#---- test .org exist ---- 
#
s="f_an "
for i in $s; do
  j=$( eval echo \$${i} )
  if [[ ! -f ${j}.org ]]; then
     echo "non-exist: ${j}.org"
     cp -f ${j}  ${j}.org
  else
     cp -f ${j}.org  ${j}
  fi
done


grep -B500  '^user =' $f_an > z1
grep -A1000 '^experiments ='  $f_an | grep -v '^experiments =' > z3
grep -B500  '^experiments ='  $f_an | grep -A100 '^user =' | grep -v -e '^user =' > z2
cat >> z1 <<EOF
T0= ''
T1= ''
dX0= ''
dX1= ''
EOF
cat >> z2 <<EOF
experiments[T0] = dX0 + deterministicVerifyDir
experiments[T1] = dX1 + deterministicVerifyDir
EOF
cat z1 z2 z3 > ${f_an}
cp -f ${f_an}  ${f_an}_save


#--- Model space : forecast
sed -i -e "s#T0=.*#T0= '$T0'#g"  \
    -e "s#T1=.*#T1= '$T1'#g"     \
    -e "s#dX0=.*#dX0= '$dX0'#g"  \
    -e "s#dX1=.*#dX1= '$dX1'#g"  \
    -e "s#user =.*#user = '$USER'#g" \
    -e "s#VerificationSpace = 'obs'.*#VerificationSpace = 'model'#g" \
    -e "s#dbConf\['cntrlExpName'\] =.*#dbConf\['cntrlExpName'\] = T0#g" \
    -e "s#dbConf\['lastCycleDTime'\].*#dbConf\['lastCycleDTime'\] = dt.datetime(2018,5,1,0,0,0)#g" \
    -e "s#dbConf\['expDirectory'\] =.*#dbConf\['expDirectory'\] = os.getenv('EXP_DIR','/glade/scratch/'+user+'/br_autotest')#g" \
    analyze_config.py
# git diff

python3 SpawnAnalyzeStats.py -d mpas


#
## override
#cp -f ${f_an}_save  ${f_an}  
##--- OBS   space : omb/oma
#sed -i -e "s#T0=.*#T0= '$T0'#g"  \
#    -e "s#T1=.*#T1= '$T1'#g"     \
#    -e "s#dX0=.*#dX0= '$dX0'#g"  \
#    -e "s#dX1=.*#dX1= '$dX1'#g"  \
#    -e "s#user =.*#user = '$USER'#g" \
#    -e "s#VerificationSpace = 'obs'.*#VerificationSpace = 'obs'#g" \
#    -e "s#\(^VerificationType = 'forecast'.*\)#VerificationType = 'omb/oma'#g" \
#    -e "s#dbConf\['cntrlExpName'\] =.*#dbConf\['cntrlExpName'\] = T0#g" \
#    -e "s#dbConf\['lastCycleDTime'\].*#dbConf\['lastCycleDTime'\] = dt.datetime(2018,5,1,0,0,0)#g" \
#    -e "s#dbConf\['expDirectory'\] =.*#dbConf\['expDirectory'\] = os.getenv('EXP_DIR','/glade/scratch/'+user+'/br_autotest')#g" \
#    analyze_config.py
##git diff
#
#python3 SpawnAnalyzeStats.py 
#
#
## conda deactivate
#echo "mpas_analyses_${T0}_vs_${T1}" > file_${T0}_vs_${T1}
