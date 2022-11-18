mydate=$(date '+%Y-%m-%d')
base=/glade/scratch/$USER/br_autotest/br_$mydate
d_here="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cat > crontab.txt <<EOF
01 00 * * 1,2,3,4,5,6  $d_here/step1.sh
20 00 * * 1,2,3,4,5,6  /opt/pbs/bin/qsub ${d_here}/job_make_ctest.scr
00 01 * * 1,2,3,4,5    sh $d_here/step3.sh 3denvar_OIE120km_WarmStart 1DA    &> $d_here/out.3.1
25 01 * * 1,2,3,4,5    sh $d_here/step3.sh 3denvar_O30kmIE60km_WarmStart 1DA &> $d_here/out.3.2
00 12 * * 2,3,5        sh $d_here/step3.sh 3denvar_OIE120km_WarmStart all 20180501T00 &> $d_here/out.3.3
#00 23 * * 2,3,4,5     $d_here/step4.sh &> $d_here/out.4
#
#crontab $d_here/crontab.txt
EOF

cat > job_make_ctest.scr <<EOF
#!/bin/bash
#PBS -A NMMM0015
#PBS -l walltime=00:40:00
#PBS -l select=1:ncpus=16:mpiprocs=16
#PBS -N make_ctest
#PBS -q premium
#PBS -o p2.log 
#PBS -e p2.err
##PBS -j oe
$d_here/step2.sh
EOF
