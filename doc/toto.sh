#!/bin/bash
FILES=*
cd doc/_site
for dir in $(find pages/flutter-sound/api -type d)
do
        rel=`realpath --relative-to=$dir .`
        #echo $dir $rel
        for f in $FILES
        do
                echo  $rel/$f ' -> ' $dir
                ln -s $rel/$f $dir
        done
done
cd ../..
