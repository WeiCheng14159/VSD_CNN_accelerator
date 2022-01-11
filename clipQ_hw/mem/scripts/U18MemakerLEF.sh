#!/bin/bash
sed -i 's/ME/metal/g' $1
sed -i 's/VI1/via/g' $1
sed -i 's/VI/via/g' $1
sed -i 's/NAmetalSCASESENSITIVE/NAMESCASESENSITIVE/g' $1
sed -i 's/SYMmetalTRY/SYMMETRY/g' $1
sed -i 's/ABUTmetalNT/ABUTMENT/g' $1
