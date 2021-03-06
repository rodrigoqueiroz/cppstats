#!/bin/bash

# parameters
# cmd - script-name itself
# indir - input-directory
cmd=${0}

# get the abspath of the input-directory
if [ -z ${1} ]; then
	echo '### no input directory given!'
	exit -1
fi
indir=${1}

D=`dirname "${indir}"`
B=`basename "${indir}"`
indirabs="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`/$B"


# change to script directory
if [ `dirname ${cmd}` != '.' ]; then
	cd `dirname ${cmd}` || exit -1
fi


# check the preconditions
bin=${PWD}
echo ${bin}
echo '### preliminaries ...'

case `uname -s` in
	Linux|linux) s2sml=src2srcml.linux; sml2s=srcml2src.linux;;
	Darwin|darwin) s2sml=src2srcml.osx; sml2s=srcml2src.osx;;
	*) echo '### program src2srcml missing'
	   echo '    see: http://www.sdml.info/projects/srcml/trunk/'
	   exit 1;;
esac

which astyle > /dev/null
if [ $? -ne 0 ]; then
	echo '### programm astyle missing!'
	echo '    see: http://astyle.sourceforge.net/'
	exit 1
fi

which xsltproc > /dev/null
if [ $? -ne 0 ]; then
	echo '### programm xsltproc missing!'
	echo '    see: http://www.xmlsoft.org/XSLT/xsltproc2.html'
	exit 1
fi

which notify-send > /dev/null
if [ $? -ne 0 ]; then
	echo '### program notify-send missing!'
	echo '    aptitude install libnotify-bin'
	exit 1
fi


# create the working directory within the sw-project
cd ${indirabs}
sourcedir=${indirabs}/source
invest=${indirabs}/_cppstats_pretty

if [ -e ${invest} ]; then
	rm -rf ${invest}
fi
mkdir ${invest}

notify-send "starting ${indirabs}"

# copy source-files
echo '### preparing sources ...'
echo '### copying all-files to one folder ...'
echo '### and renaming duplicates (only filenames) to a unique name.'
echo "formating source-file $i"
cd ${sourcedir}
find . -type f \( -name "*.h" -o -name "*.c" \) -exec cp --parents '{}' ${invest} \;

cd ${invest}

# reformat source-files and delete comments and include guards
echo '### reformat source-files'
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for f in `find . -type f \( -name "*.h" -o -name "*.c" \)`; do
	j=${invest}/${f}
	
	# translate macros that span over multiple lines to one line
	cp ${f} ${f}.bak01
	mv ${f} ${f}tmp.txt
	${bin}/move_multiple_macros.py ${f}tmp.txt ${f}
	rm -f ${f}tmp.txt

	# format source-code
	cp ${f} ${f}.bak02
	astyle --style=java ${f}
	if [ -e ${f}.orig ]; then
		rm -f ${f}.orig
	fi

	# delete comments
	cp ${f} ${f}.bak03
	${bin}/${s2sml} --language=C ${f} -o ${f}tmp.xml
	xsltproc ${bin}/delete_comments.xsl ${f}tmp.xml > ${f}tmp_out.xml
	${bin}/${sml2s} ${f}tmp_out.xml -o ${f}
	rm -f ${f}tmp.xml ${f}tmp_out.xml

	# delete empty lines
	cp ${f} ${f}.bak04
	mv ${f} ${f}tmp.txt
	${bin}/delete_emptylines.sed ${f}tmp.txt > ${f}
	rm -f ${f}tmp.txt
done
IFS=$SAVEIFS

notify-send "finished ${indirabs}"
