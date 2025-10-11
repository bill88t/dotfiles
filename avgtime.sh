runs=100
total=0

for ((i=1; i<=runs; i++)); do
    start=$(date +%s.%N)
    "$@" > /dev/null 2>&1
    end=$(date +%s.%N)
    elapsed=$(echo "$end - $start" | bc)
    total=$(echo "$total + $elapsed" | bc)
done

avg=$(echo "scale=6; $total / $runs" | bc)
echo "Average time over $runs runs: ${avg}s"
