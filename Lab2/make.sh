#!/bin/bash

export CDS_AUTO_64BIT=ALL
path_to_ncsim=$(which ncsim)
path_to_ncsim_suffix="bin/ncsim"
echo "===beginning cds.lib =========================================================="
echo "#### START OF GENERATED cds.lib #### "				 >cds.lib
find worklib/ -type f  -name "*.*" -delete
mkdir -p ./worklib

echo "define worklib ./worklib"                                  >>cds.lib

echo "include ${path_to_ncsim%${path_to_ncsim_suffix}}inca/files/cds.lib"		>>cds.lib
echo "####   END OF GENERATED cds.lib #### "				>>cds.lib
cat ./cds.lib

echo "=====end cds.lib =============================================================="
echo "=====beginnig hdl.var ========================================================="
echo "#### START OF GENERATED hdl.var #### "				>hdl.var
echo "define WORK worklib"						>>hdl.var
echo "include ${path_to_ncsim%${path_to_ncsim_suffix}}inca/files/hdl.var"		>>hdl.var
echo "DEFINE XMVHDLOPTS -nowarn NCEXDEP"                                >>hdl.var
echo "DEFINE XMVLOGOPTS -nowarn NCEXDEP"                                >>hdl.var
echo "DEFINE XMELABOPTS -nowarn CUFEPC  -nowarn NCEXDEP"                >>hdl.var
echo "####   END OF GENERATED hdl.var #### "				>>hdl.var
cat ./hdl.var
echo "=======end hdl.var ============================================================"

ncvhdl  -work worklib -cdslib ./cds.lib -logfile ncvhdl.log -errormax 15 -update -status -SMARTORDER -v93 -file ./files_vhdl.txt

xmelab  -v93 -work worklib -cdslib ./cds.lib -logfile ./ncelab.log -errormax 15 -nowarn CUVWSP -nowarn MEMODR worklib.test:lab -STATUS -NOTIMINGCHECKS -access +RWC -NOSPECIFY -coverage all

xmsim  -gui -cdslib ./cds.lib -logfile ./ncsim.log -errormax 15 -status worklib.test:lab