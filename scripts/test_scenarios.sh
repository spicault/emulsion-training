#!/bin/bash
# Run experiments from a plan file
# AUTHOR: Sébastien Picault
# Usage:
#   ./test_scenarios.sh MODEL PLAN_NAME NB_REPETITIONS ADDITIONAL_OPTIONS
# Example:
#   ./test_scenarios.sh step6 plan_exp 50 "-p initial_herd_size=20"
# where:
# - MODEL.yaml is the EMULSION model file
# - PLAN_NAME.csv is the experiment to run
# - NB_REPETITIONS is the number of stochastic repetitions for each scenario
# - ADDITIONAL_OPTIONS represent a character string with all options
#   that have to be specified *in addition* to parameters handled by the plan
#
# Results are put in subdirectories of outputs/PLAN_NAME/ (1 subdirectory per scenario_id)
#

MODEL="$1"
OUTPUT_NAME="$2"
FILENAME="$OUTPUT_NAME.csv"
NB_REPETITIONS="$3"
DEFAULT_REPET=10
ADDITIONAL_OPTIONS="$4"
PYTHON3="python" 		# adapt to your config (Python 3 executable with emulsion module installed)


# if number of repetitions not specified, use default
if [ -z "$NB_REPETITIONS" ]
then
    NB_REPETITIONS=$DEFAULT_REPET
fi

PARAMS=()
HEADER=""
OPTIONS="run $MODEL.yaml --silent -r $NB_REPETITIONS"
echo $OPTIONS
OUTPUT_DIR="outputs/$OUTPUT_NAME"

while read -r line
do
    if [ -z "$HEADER" ]
    then
	HEADER=($line)
	# take all values except the first one as parameters
	for param in "${HEADER[@]:1}"
	do
	    PARAMS+=($param)
	done
    else
	pars="$ADDITIONAL_OPTIONS"
	values=()
	List=($line)
	# take first value as scenario_id
	scenario="${List[0]}"
	outdir="$OUTPUT_DIR/$scenario"
	# take all values except the first one as parameters
	for val in "${List[@]:1}"
	do
	    values+=($val)
	done
	for i in `seq 0 $((${#PARAMS[@]} - 1))`
	do
	    pars="$pars -p ${PARAMS[$i]}=${values[$i]}"
	done
	echo "$scenario ==> $pars"
	# launch runs in parallel
	$PYTHON3 -m emulsion $OPTIONS --output-dir $outdir $pars &
    fi
done < "$FILENAME"

echo "Execution of plan $FILENAME finished."
