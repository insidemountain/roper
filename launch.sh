#! /bin/bash
PROJECT_ROOT=`pwd`
DATAFILE=${PROJECT_ROOT}/data/iris.data
GOAL="0.10"
OUTFILE="${PROJECT_ROOT}/logs/roper.out"

mkdir -p $PROJECT_ROOT/logs
gzip -f $PROJECT_ROOT/logs/roper*.{csv,json} 
ITERATION=1
AVG_GEN=2
AVG_FIT=3
AVG_CRASH=4
BEST_GEN=5
BEST_FIT=6
BEST_CRASH=7
AVG_LEN=8
BEST_LEN=9
UNSEEN=10
X0=$AVG_GEN
X1=$ITERATION
X0_AXIS_TITLE="AVERAGE GENERATION"
X1_AXIS_TITLE="TOURNEMENT ITERATION"

cat > plot.gnu << EOF
set terminal x11 background rgb 'black'
set datafile commentschars "%"
set multiplot layout 1, 2 title "ROPER on $DATAFILE"
set xlabel 'ylabel' tc rgb 'red'
set ylabel 'xlabel' tc rgb 'red'
set border lc rgb 'red'
set key tc rgb 'red'
set key autotitle columnhead
set datafile separator ","
set autoscale
set xlabel "$X0_AXIS_TITLE or $X1_AXIS_TITLE"
set ylabel "POPULATION FEATURES"
plot "logs/recent.csv" u ${X0}:${AVG_FIT} w lines, \
  "" u ${X0}:${AVG_CRASH} w lines, \
  "" u ${X0}:${BEST_FIT} w lines, \
  "" u ${X0}:${UNSEEN} w lines
plot "logs/recent.csv" u ${X1}:${AVG_GEN} w lines, \
  "" u ${X1}:${AVG_LEN} w lines, \
  "" u ${X1}:${BEST_GEN} w lines, \
  "" u ${X1}:${BEST_LEN} w lines
pause 1 
unset multiplot
reread
EOF
# "logs/recent.csv" u $AVG_GEN:$AVG_LEN w lines, \
# "logs/recent.csv" u $AVG_GEN:$BEST_LEN w lines
ERRORFILE=$PROJECT_ROOT/logs/roper.err
echo "[+] compiling roper..."
echo "[+] logging stderr to $ERRORFILE"
cargo build | tee -a $ERRORFILE || \
  (cat $ERRORFILE && exit)
echo "[+] roper has been successfully compiled"
STAMPFILE="/tmp/.roper_starting"
rm -f $STAMPFILE
touch $STAMPFILE
DISASFILE="/tmp/roper_disassembly.txt" 
[ -f "$DISASFILE" ] && mv $DISASFILE \
  $PROJECT_ROOT/logs/roper_disassembly.old.txt
function run () {
  RUST_BACKTRACE=1 cargo run -- -d $DATAFILE \
                                -o $PROJECT_ROOT/logs \
                                -g $GOAL \
                                -t 4 \ 
                                -P 3200 \
                                -D 4 \
                                -V
}
echo "[+] launching roper"
run > $OUTFILE 2>> $ERRORFILE &
roper_pid=$!
echo "[+] roper PID is $roper_pid"
cd $PROJECT_ROOT/logs
recent=""
echo -n "[+] looking for log output"
while ! [ -n "$recent" ]; do
  if ! kill -0 $roper_pid; then
    echo "ROPER instance with PID $roper_pid is dead"
    exit
  fi
  echo -n "."
  sleep 0.5
  recent=`find ./ -name "roper*csv" -anewer $STAMPFILE | tail -n1`
done
echo
ln -sf $recent recent.csv
cd ..
echo "[+] logging to $PROJECT_ROOT/logs/$recent"
sleep 1
( [ -n "$DISPLAY" ] && gnuplot plot.gnu) &
gnuplot_pid=$!
echo "[+] gnuplot PID is $gnuplot_pid"
for i in {0..70}; do echo -n "="; done; echo
tail -n 4096 -f $OUTFILE
kill $roper_pid
[ -n "$DISPLAY" ] && kill $gnuplot_pid


