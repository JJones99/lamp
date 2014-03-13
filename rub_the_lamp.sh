#!/bin/sh

MAKENICE=0           # make under nice?
HELPFLAG=0           # show the help block (if non-zero)
PYTHIAVER=-1         # must eventually be either 6 or 8
USERREPO="GENIEMC"   # where do we get the code from GitHub?
ROOTTAG="v5-34-08"   # 
HTTPSCHECKOUT=0      # use https checkout if non-zero (otherwise ssh)
GENIEVER="GENIE_2_8" # TODO - Add a flag to choose different versions...
                     # Also TODO - Add an option to check out from HepForge
                     
ENVFILE="environment_setup.sh"

# how to use the script
help()
{
  mybr
  echo "Usage: ./rub_the_lamp.sh -<flag>"
  echo "                       -p  #   : Build Pythia 6 or 8 and link ROOT to it (required)."
  echo "                       -u name : The repository name. Default is the GENIEMC"
  echo "                       -r tag  : Which ROOT version (default = v5-34-08)."
  echo "                       -n      : Run configure, build, etc. under nice."
  echo "                       -s      : Use ssh to checkout code from GitHub."
  echo " "
  echo "Note: Currently the user repository choice affects GENIE only - the support packages"
  echo "are always checked out from the GENIEMC organization respoistory."
  echo " "
  echo "  Examples:  "
  echo "    ./rub_the_lamp.sh -p 6 -u GENIEMC                  # (GENIEMC is the default)"
  echo "    ./rub_the_lamp.sh -p 6 -u <your GitHub user name> " 
  echo "    ./rub_the_lamp.sh -p 8 -r v5-34-12"
  echo " "
  echo "Note: Advanced configuration of the support packages require inspection of that script."
  mybr
  echo " "
}

# quiet pushd
mypush() 
{ 
  pushd $1 >& /dev/null 
  if [ $? -ne 0 ]; then
    echo "Error! Directory $1 does not exist."
    exit 0
  fi
}

# quiet popd
mypop() 
{ 
  popd >& /dev/null 
}

# uniformly printed "subject" breaks
mybr()
{
  echo "----------------------------------------"
}

# bail on illegal versions of Pythia
badpythia()
{
  echo "Illegal version of Pythia! Only 6 or 8 are accepted."
  exit 0
}
#


while getopts "p:u:r:ns" options; do
  case $options in
    p) PYTHIAVER=$OPTARG;;
    u) USERREPO=$OPTARG;;
    r) ROOTTAG=$OPTARG;;
    n) MAKENICE=1;;
    s) HTTPSCHECKOUT=1;; 
  esac
done

if [ $PYTHIAVER -eq -1 ]; then
  HELPFLAG=1
fi
if [ $HELPFLAG -ne 0 ]; then
  help
  exit 0
fi
mybr
echo "Letting GENIE out of the bottle..."
echo "Selected Pythia Version is $PYTHIAVER..."
if [ $PYTHIAVER -ne 6 -a $PYTHIAVER -ne 8 ]; then
  badpythia
fi
echo "Selected ROOT tag is $ROOTTAG..."

GITCHECKOUT="http://github.com/"
if [ $HTTPSCHECKOUT -ne 0 ]; then 
  GITCHECKOUT="https://github.com/"
else
  GITCHECKOUT="git@github.com:"
fi

if [ ! -d GENIESupport ]; then
  git clone ${GITCHECKOUT}${USERREPO}/GENIESupport.git
else
  echo "GENIESupport already installed..."
fi
if [ ! -d $GENIEVER ]; then
  git clone ${GITCHECKOUT}${USERREPO}/${GENIEVER}.git
else
  echo "${GENIEVER} already installed..."
fi

if [ $MAKENICE -ne 1 ]; then
  NICE="-n"
fi

# TODO - pass other flags nicely
mypush GENIESupport
./build_support.sh -p $PYTHIAVER -r $ROOTTAG $NICE
mv $ENVFILE ..
mypop

echo "export GENIE=`pwd`/${GENIEVER}" >> $ENVFILE
echo "export PATH=`pwd`/${GENIEVER}/bin:\$PATH" >> $ENVFILE
echo "export LD_LIBRARY_PATH=`pwd`/${GENIEVER}/lib:\$LD_LIBRARY_PATH" >> $ENVFILE

source $ENVFILE
echo "Configuring GENIE environment in-shell. You will need to source $ENVFILE after the build finishes."

# mypush $GENIEVER
# ./configure --enable-debug --enable-test --enable-numi --enable-t2k --enable-rwgt \
#  --with-optimiz-level=O0 --with-log4cpp-inc=\$LOG4CPP_INC --with-log4cpp-lib=\$LOG4CPP_LIB
# gmake
# mypop
