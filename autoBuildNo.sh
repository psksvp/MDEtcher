if ! test -f buildNo.txt; then echo 0 > buildNo.txt; fi
echo $(($(cat buildNo.txt) + 1)) > buildNo.txt
