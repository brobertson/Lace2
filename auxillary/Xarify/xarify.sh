#!/bin/bash
path=$1
if [ ! -d "${path}" ] ; then
    echo "$path is not a directory";
    exit 1
else
if [ $1 = '.' ] ; then
	path=$(pwd)
fi
cd $path > /dev/null
fullpath=$(pwd)
cd - > /dev/null
dirname=$(basename $fullpath)
#echo "$dirname is a directory" 
fi
innerPath=$fullpath/${dirname}-PNG-500
if [ ! -d "${innerPath}" ] ; then
    echo "$path has no inner directory ${innerPath}";
    exit 1
fi

#### Texts #####

for dir in $(ls $innerPath) 
do
	if [[ $dir =~ "selected_hocr" ]] ; then 
		echo $dir
		shortend_dir_name="${dir::-21}"
		echo $shortend_dir_name
		sep="_"
		rundate=${shortend_dir_name%%"$sep"*}
		#add seconds as a new standard
		rundate=$rundate-00
    		classifier=${shortend_dir_name#*"$sep"}
		echo "rundate: $rundate"
		echo "classifier: $classifier"
		TEXTOUT=$(mktemp -d /tmp/$dirname.XXXXXXXXXX) || { echo "Failed to create temp file"; exit 1; }
		cd $TEXTOUT > /dev/null
		#build zippable directory in $TEXTOUT
		xsltproc --stringparam identifier ${dirname} --stringparam rundate ${rundate} --stringparam classifier ${classifier}  --output $TEXTOUT/meta.xml $XARIFY_HOME/make_meta_texts.xsl $XARIFY_HOME/laceTexts.xml   || { echo "Failed to generate meta.xml file. exiting ..."; cd -; rm -rf $OUT; exit 1; }
		xsltproc --stringparam identifier ${dirname} --stringparam rundate ${rundate}  --output $TEXTOUT/repo.xml $XARIFY_HOME/make_repo_texts.xsl $XARIFY_HOME/laceTexts.xml   || { echo "Failed to generate repo.xml file. exiting ..."; cd -; rm -rf $OUT; exit 1; }
		xsltproc --stringparam identifier ${dirname} --stringparam rundate ${rundate}  --output $TEXTOUT/expath-pkg.xml $XARIFY_HOME/make_expath_texts.xsl $XARIFY_HOME/laceTexts.xml   || { echo "Failed to generate expath-pkg.xml file. exiting ..."; cd -; rm -rf $OUT; exit 1; }
		cat $TEXTOUT/expath-pkg.xml
		ln -s $innerPath/$dir/*html ./
		ln -s $XARIFY_HOME/StaticFilesForTextXar/* ./
		rm -f $fullpath/$dirname-$rundate-$classifier-texts.xar
		zip -q -r $fullpath/$dirname-$rundate-$classifier-texts.xar *
		cd - > /dev/null
		rm -rf $TEXTOUT
	fi
done

#### Images ###########

#we now have the name for the file
#let's build a temp file with links to the necessary
#image file, and then zip from that and delete it
OUT=$(mktemp -d /tmp/$dirname.XXXXXXXXXX) || { echo "Failed to create temp file"; exit 1; }
#echo "using temp dir: $OUT"
cd $OUT > /dev/null
cp $innerPath/*png ./
parallel ocropus-nlbin {} ::: *png
rename -f 's/.bin.png/.png/' *png
rm *nrm.png
parallel optipng {} ::: *png
#ln -s $innerPath/*selected_hocr_output* ./

xsltproc --stringparam identifier ${dirname} --output  ./meta.xml $XARIFY_HOME/make_meta_images.xsl $XARIFY_HOME/laceTexts.xml    || { echo "Failed to generate meta.xml file. exiting ..."; cd -; rm -rf $OUT; exit 1; }
xsltproc --stringparam identifier ${dirname} --output ./expath-pkg.xml $XARIFY_HOME/make_expath_images.xsl $XARIFY_HOME/laceTexts.xml || { echo "Failed to generate expath file. exiting ..."; cd -; rm -rf $OUT; exit 1; }
xsltproc --stringparam identifier ${dirname}  --output ./repo.xml $XARIFY_HOME/make_repo_images.xsl $XARIFY_HOME/laceTexts.xml || { echo "Failed to generate repo.xml file. exiting ..."; cd -; rm -rf $OUT; exit 1; }
ln -s $XARIFY_HOME/StaticFilesForImageXar/* ./
rm -f $fullpath/$dirname-images.xar
zip -q -r $fullpath/$dirname-images.xar * 
size=$(ls -l  $fullpath/$dirname-images.xar | cut -d " " -f5)
echo "xar is $size bytes"
unzip -l $fullpath/$dirname-images.xar
if [ $size -gt 2147483647 ] ; then 
	echo "xar is too large to upload into exist. Exiting."
	rm $fullpath/$dirname-images.xar
        rm -rf $OUT
fi
cd - > /dev/null
#rm -rf $OUT
echo "$fullpath/$dirname-images.xar"

