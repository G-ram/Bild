for file in *.bd *.out
do
  out=`echo "$file" | awk '{print "test-" $0}'`
  echo "$out"
  mv "$file" "$out"
done
