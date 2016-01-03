for file in *.bd
do
  out=`echo "$file" | awk '{print substr($0, 1, length($0)-2) "out"}'`
  echo "$out"
  touch "$out"
done
