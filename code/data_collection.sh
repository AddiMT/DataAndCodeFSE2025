#!/usr/bin/bash

# region 1 ----------------------------------- functions -----------------------------------

# region 1.1 - P2mon
P2mon() {
    python3 -uc '
import sys
from pymongo import MongoClient
from bson.json_util import dumps

client = MongoClient("mongodb://da1.eecs.utk.edu/")
db = client["WoC"]
coll = db["P_metadata.V"]

projects = sys.stdin.read().splitlines()
for p in projects:
    c=coll.find({"ProjectID" : p})
    for r in c:
        json=dumps(r)
        print(json)
    c.close()'
}
# endregion 1.1

# region 1.2 - P2lcd - getting latest commit date for each project
P2lcd() {
    python3 -uc ' 
import sys
from pymongo import MongoClient
from bson.json_util import dumps

client = MongoClient("mongodb://da1.eecs.utk.edu/")
db = client["WoC"]
coll = db["P_metadata.V"]

projects = sys.stdin.read().splitlines()
for p in projects:
    c=coll.find({"ProjectID" : p},
    {"ProjectID" : 1 , "LatestCommitDate" : 1},
    no_cursor_timeout=True)
    for r in c:
        json=dumps(r)
        print(json)
    c.close()' |
    jq -r '"\(.ProjectID);\(.LatestCommitDate)"' |
    ~/lookup/lsort 300G -t\; -u |
    grep -v ";null"
}
# endregion 1.2

# region 1.3 - maxlcd - max latest commit date
maxlcd() {
    awk -F\; '{if ($2<1704110400 && $2>788961600) print}' |
    awk -F\; '
        BEGIN {
            ll="";
            max=0;}
        {l=$1;
        if (l!=ll){
            print ll";"max;
            ll=l;
            max=0}
        if (max<$2){
            max=$2;}}
        END {
            print ll";"max;}' |
    tail -n +2
}
# endregion 1.3 

# region 1.4 - maxlcd - min latest commit date
minlcd(){
    awk -F\; '{if ($2<1704110400 && $2>788961600) print}' |
    awk -F\; '
        BEGIN {
            ll="";
            min=2000000000;}
        {l=$1;
        if (l!=ll){
            print ll";"min;
            ll=l;
            min=2000000000}
        if (min>$2){
            min=$2;}}
        END {
            print ll";"min;}' |
    tail -n +2
}
# endregion 1.4

# endregion 1 ----------------------------------------------------------------------------

# region 2 ------------------------------- list of projects -------------------------------

# region 2.1 - scientific sample
# shellcheck disable=SC2002
cat data/merged_new_withpercentcolumns_lang_fixed_new.csv | 
awk -F\; '{if ((\
    $5=="Publication-Specific code" || 
    $5=="Scientific Domain-specific code" || 
    $5=="Scientific infrastructure") && (\
    $7=="Astronomy" ||
    $7=="Biology" ||
    $7=="Chemistry" ||
    $7=="Computer Science" ||
    $7=="Data Science" ||
    $7=="Earth Science" ||
    $7=="Engineering" ||
    $7=="Mathematics" ||
    $7=="Medicine" ||
    $7=="Neuroscience" ||
    $7=="Physics" ||
    $7=="Quantum Computing" ||
    $7=="Statistics")) print $2}' | 
~/lookup/lsort 10G -t\; -u |
gzip >data/sP.s; # 18,247
## getting data from mongo
zcat data/sP.s |
P2mon |
gzip >data/sP.json;
## filtered csv
## header
head -1 <data/merged_new_withpercentcolumns_lang_fixed_new.csv | 
cut -d\; -f2 --complement |
sed 's|^|ProjectID;|' >data/sP.csv;
## filter
LC_ALL=C LANG=C join -t\; -1 2 \
    <(~/lookup/lsort 10G -t\; -k2,2 <data/merged_new_withpercentcolumns_lang_fixed_new.csv) \
    <(zcat data/sP.s) >>data/sP.csv;
# endregion 2.1

# region 2.2 - non-sientific sample
## creating bins
zcat data/sP.json |
jq -r '"\(.ProjectID);\(.EarliestCommitDate);\(.NumAuthors);\(.NumCommits)"' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/sP2nTnAnC.s;
a=(0 11 26 61 10000000);
c=(0 751 1801 5001 100000000);
t=(300000000 1451649600 1546344000 1750000000);
for i in {1..4}; do
    al=${a[$i]};
    au=${a[$((i+1))]};
    for j in {1..4}; do
        cl=${c[$j]};
        cu=${c[$((j+1))]};
        for k in {1..3}; do
            tl=${t[$k]};
            tu=${t[$((k+1))]};
            zcat data/tmp/sP2nTnAnC.s |
            awk -F\; \
                -v al="$al" -v au="$au" \
                -v cl="$cl" -v cu="$cu" \
                -v tl="$tl" -v tu="$tu" \
                '{if ($3>=al && $3<au && $4>=cl && $4<cu && $2>=tl && $2<tu) print $1}' |
            ~/lookup/lsort 10G -t\; -u |
            gzip >"data/tmp/sP$i$j$k.s";
            n1=$(zcat "data/tmp/sP$i$j$k.s" | wc -l);
            # shellcheck disable=SC2016
            echo "$al;$au;$cl;$cu;$tl;$tu;$n1" |
            python3 -uc ' 
import sys
from pymongo import MongoClient
from bson.json_util import dumps
import random

client = MongoClient("mongodb://da1.eecs.utk.edu/")
db = client["WoC"]
coll = db["P_metadata.V"]

input = sys.stdin.read().splitlines()
limits=input[0].split(";");

c=coll.find({
    "NumAuthors" : { "$gte": int(limits[0]), "$lt": int(limits[1])}, 
    "NumCommits" : { "$gte": int(limits[2]), "$lt": int(limits[3])},
    "EarliestCommitDate" : { "$gte": int(limits[4]), "$lt": int(limits[5])}
    },
    {"ProjectID" : 1},
    no_cursor_timeout=True)
res=[];
for r in c:
    res.append(dumps(r))
c.close()

count=int(limits[6])*3
for p in random.choices(res,k=count):
    print(p)
                ' 2>"data/tmp/pyErr.$i$j$k" | 
            gzip >"data/tmp/bin$i$j$k.json";
            zcat "data/tmp/bin$i$j$k.json" |
            jq -r '.ProjectID' |
            ~/lookup/lsort 10G -t\; -u |
            LC_ALL=C LANG=C join -t\; -v1 \
                - \
                <(zcat "data/tmp/sP$i$j$k.s") |
            shuf -n $((n1*2));
        done;
    done;
done |
~/lookup/lsort 10G -t\; -u |
gzip >data/oP.s; # 36,494
## getting data from mongo
zcat data/oP.s |
P2mon |
gzip >data/oP.json;
# endregion 2.2

# endregion 2 -------------------------------------------------------------------

# region 3 ---------------------------------- dependency ----------------------------------

## defined packages
zcat data/{s,o}P.s | 
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP.s;
for i in {0..127..4}; do
    LC_ALL=C LANG=C join -t\; \
        <(zcat /da?_data/basemaps/gz/c2PtAbflDefFullV"$i".s |
            cut -d\; -f2,7,8 |
            ~/lookup/lsort 50G -t\; -k1,1) \
        <(zcat data/tmp/aP.s) |
    ~/lookup/lsort 50G -t\; -u |
    gzip >"data/tmp/aP2lDef.$i";
done;
zcat data/tmp/aP2lDef.{0..127} |
awk -F\; '{print $1";"$2"@:@"$3}' |
awk -F"@:@" '{if ($2!="") print}' |
~/lookup/lsort 50G -t\; -u |
gzip >data/aP2lDef.s;
## nDef
zcat data/aP2lDef.s |
cut -d\; -f1 |
uniq -c |
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2nDef.s;
## downstream projects
## too slow on da, ran on isaac
zcat data/aP2lDef.s |
cut -d\; -f2 |
~/lookup/lsort 50G -t\; -u |
gzip >data/definedPackages.s;
for i in {0..127..4}; do
    LC_ALL=C LANG=C join -t\; -o 1.2 1.3 1.4 1.5 \
        <(zcat /da?_data/basemaps/gz/c2PtAbflPkgFullV"$i".s |
            awk -F\; '{OFS=";";for (i=8;i<=NF;i++) print $7"@:@"$i,$2,strftime("%Y-%m",$3),$7,$i}' |
            ~/lookup/lsort 100G -t\; -k1,1) \
        <(zcat data/definedPackages.s | ~/lookup/lsort 50G -t\; -k1,1) |
    ~/lookup/lsort 100G -t\; -u |
    gzip >"data/tmp/dP2tlDef.$i";
done;
## join with aP
for i in {0..127..4}; do
    LC_ALL=C LANG=C join -t\; -1 2 \
        <(zcat data/aP2lDef.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat "data/tmp/dP2tlDef.$i" |
            awk -F\; '{OFS=";"; print $3"@:@"$4,$2,$1}' | 
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/lDef2aPtdP.$i";
done;
## total, not monthly
for i in {0..127}; do
    zcat "data/tmp/dP2tlDef.$i" |
    awk -F\; '{OFS=";"; print $3"@:@"$4,$1}' | 
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/lDef2dP.$i";
done;
zcat data/tmp/lDef2dP.{0..127} |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/lDef2dP.s;
## join with aP
## too large, need to break down
zcat data/tmp/lDef2dP.s | 
split -a2 -d -l 50000000 --filter='gzip > $FILE' - data/tmp/split/lDef2dP_ ;
for i in {00..66}; do
    LC_ALL=C LANG=C join -t\; -1 2 -o 1.1 2.2 \
        <(zcat data/aP2lDef.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat data/tmp/split/lDef2dP_$i |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    awk -F\; '{if($1!=$2) print}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/split/aP2dP.$i;
done;
zcat data/tmp/split/aP2dP.{00..66} |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2dP.s;
# ndP-d
zcat data/tmp/aP2dP.s |
cut -d\; -f1 |
uniq -c |
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2ndP-d.s;

## used packages
for i in {0..127..4}; do
    LC_ALL=C LANG=C join -t\; -1 2 \
        <(zcat /da?_data/basemaps/gz/c2PtAbflPkgFullV"$i".s |
            ~/lookup/lsort 100G -t\; -k2,2) \
        <(zcat data/tmp/aP.s) |
    gzip >"data/tmp/aP2ctAbflPkg.$i";
done;
for i in {0..127}; do
    zcat "data/tmp/aP2ctAbflPkg.$i" |
    awk -F\; '{OFS=";";for (i=8;i<=NF;i++) print $1,strftime("%Y-%m",$3),$7,$i}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP2tlPkg.$i";
done;
## total - not monthly
for i in {0..127}; do
    zcat "data/tmp/aP2tlPkg.$i" |
    cut -d\; -f1,3,4 |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP2lPkg.$i";
done;
zcat data/tmp/aP2lPkg.{0..127} |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/aP2lPkg.s;
zcat data/aP2lPkg.s | 
cut -d\; -f1 | 
uniq -c | 
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2nPkg.s; # 38,323
## upstream projects
for i in {0..127}; do
    zcat "data/tmp/aP2ctAbflPkg.$i" |
    awk -F\; '{for (i=8;i<=NF;i++) print $7"@:@"$i}' |
    ~/lookup/lsort 50G -t\; -u;
done |
awk -F"@:@" '{if ($2!="") print}' |
~/lookup/lsort 100G -t\; -u |
gzip >data/usedPackages.s;
for i in {0..127..4}; do
    LC_ALL=C LANG=C join -t\; \
        <(zcat /da?_data/basemaps/gz/c2PtAbflDefFullV"$i".s |
            awk -F\; '{print $7"@:@"$8";"$2}' |
            ~/lookup/lsort 100G -t\; -k1,1) \
        <(zcat data/usedPackages.s) |
    ~/lookup/lsort 50G -t\; -u |
    gzip >"data/tmp/lPkg2uP.$i";
done;
zcat data/tmp/lPkg2uP.{0..127} |
~/lookup/lsort 100G -t\; -u |
gzip >data/lPkg2uP.s;
## join with aP
## too large - need to break down!
zcat data/aP2lPkg.s |
awk -F\; '{print $2"@:@"$3";"$1}' |
awk -F@ '{f="data/tmp/split/lPkg2aP_"$1; print | " gzip >"f}';
zcat data/lPkg2uP.s |
awk -F@ '{f="data/tmp/split/lPkg2uP_"$1; print | " gzip >"f}';
ll=$(ls data/tmp/split/ | 
    sed 's|.*_||' | 
    sort | 
    uniq -c | 
    awk '{if ($1==2) print $2}' |
    grep -v JS);
for l in $ll; do
    LC_ALL=C LANG=C join -t\; -o 1.2 2.2 \
        <(zcat data/tmp/split/lPkg2aP_$l |
            sed 's|.*@:@||' |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
        <(zcat data/tmp/split/lPkg2uP_$l |
            sed 's|.*@:@||' |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    awk -F\; '{if($1!=$2) print}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/split/aP2uP_$l.s;
done;
## splitting JS into smaller parts
zcat data/tmp/split/lPkg2uP_JS | 
sed 's|.*@:@||' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
split -d -l 1000000 --filter='gzip > $FILE' - data/tmp/split/lPkg2uP_JS_ ;
for i in {00..20}; do
    LC_ALL=C LANG=C join -t\; -o 1.2 2.2 \
        <(zcat data/tmp/split/lPkg2aP_JS |
            sed 's|.*@:@||' |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
        <(zcat data/tmp/split/lPkg2uP_JS_$i |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    awk -F\; '{if($1!=$2) print}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/split/aP2uP_JS.$i;
done;
zcat data/tmp/split/aP2uP_* |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2uP.s;
# nuP-d
zcat data/tmp/aP2uP.s |
cut -d\; -f1 |
uniq -c |
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2nuP-d.s;

## min/max Latest commit date up/downstream
## uniq upstream
zcat data/lPkg2uP.s |
cut -d\; -f2 |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/uP-d.s;
## getting latest commit date
zcat data/tmp/uP-d.s |
P2lcd |
gzip >data/tmp/uP-d2lcd.s;
## uniq dP
zcat data/tmp/lDef2dP.s |
cut -d\; -f2 |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/dP-d.s;
## getting latest commit date
zcat data/tmp/dP-d.s |
P2lcd |
gzip >data/tmp/dP-d2lcd.s;
# join with aP
for b in {u,d}; do
    LC_ALL=C LANG=C join -t\; -1 2 -o 1.1 2.2 \
        <(zcat data/tmp/aP2"$b"P.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat data/tmp/"$b"P-d2lcd.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/aP2lcd"$b"P-d.s;
done;
## min upstream
zcat data/tmp/aP2lcduP-d.s |
minlcd |
gzip >data/tmp/aP2mlcduP-d.s;
## max downstream
zcat data/tmp/aP2lcddP-d.s |
maxlcd |
gzip >data/tmp/aP2mlcddP-d.s;
# endregion 3 --------------------------------------------------------------

# region 4 ---------------------------------- copy reuse ----------------------------------

for i in {0..127..4}; do
    ## dowstream projects
    LC_ALL=C LANG=C join -t\; \
        <(zcat /da?_data/basemaps/gz/Ptb2PtFullV"$i".s |
            ~/lookup/lsort 100G -t\; -k1,1) \
        <(zcat data/tmp/aP.s | ~/lookup/lsort 100G -t\; -k1,1) |
    ~/lookup/lsort 100G -t\; -u |
    gzip >"data/tmp/aPtb2dPt.$i";
    zcat "data/tmp/aPtb2dPt.$i" |
    awk -F\; '{
        OFS=";";
        print $1,strftime("%Y-%m",$5),$4,$3;}'|
    ~/lookup/lsort 100G -t\; -u |
    cut -d\; -f1-3 |
    uniq -c |
    awk '{print $2";"$1}' |
    ~/lookup/lsort 100G -t\; -u |
    gzip >"data/tmp/aP2tdPnb.$i";
    ## upstream projects
    LC_ALL=C LANG=C join -t\; -1 4 -o 1.4 1.5 1.3 1.1 1.2 \
        <(zcat /da?_data/basemaps/gz/Ptb2PtFullV"$i".s |
            ~/lookup/lsort 100G -t\; -k4,4) \
        <(zcat data/tmp/aP.s | ~/lookup/lsort 100G -t\; -k1,1) |
    ~/lookup/lsort 100G -t\; -u |
    gzip >"data/tmp/aPtb2uPt.$i";
    zcat "data/tmp/aPtb2uPt.$i" |
        awk -F\; '{
        OFS=";";
        print $1,strftime("%Y-%m",$2),$4,$3;}'|
    ~/lookup/lsort 100G -t\; -u |
    cut -d\; -f1-3 |
    uniq -c |
    awk '{print $2";"$1}' |
    ~/lookup/lsort 100G -t\; -u |
    gzip >"data/tmp/aP2tuPnb.$i";
done;
## merge
for b in {d,u}; do
    zcat data/tmp/aP2t"$b"Pnb.{0..127} |
    LC_ALL=C LANG=C sort -T ./tmp -t\; |
    awk -F\; '{OFS=";"; print $1,$2,$3"@"$4}' |
    awk -F@ '
        BEGIN {
            ll="";
            s=0;}
        {l=$1;
        if (ll!=l){
            print ll";"s;
            ll=l;
            s=0;}
        s+=$2;}
        END {
            print ll";"s;}' |
    tail -n +2 |
    gzip >data/tmp/aP2t"$b"Pnb.s;
    ## sanity check
    n1=$(zcat data/tmp/aP2t"$b"Pnb.{0..127} |
        cut -d\; -f1-3 |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
        wc -l);
    n2=$(zcat data/tmp/aP2t"$b"Pnb.s | wc -l);
    echo "n1: $n1 n2: $n2 diff: $((n1-n2))"
    n3=$(zcat data/tmp/aP2t"$b"Pnb.{0..127} |
        awk -F\; '{s+=$4} END {print s}');
    n4=$(zcat data/tmp/aP2t"$b"Pnb.s |
        awk -F\; '{s+=$4} END {print s}');
    echo "n3: $n3 n4: $n4 diff: $((n3-n4))";
    ## second merge
    zcat data/tmp/aP2t"$b"Pnb.s |
    awk -F\; '
        BEGIN {
            ll="";
            s1=0;
            s2=0;}
        {l=$1";"$2;
        if (ll!=l){
            print ll";"s1";"s2;
            ll=l;
            s1=0;
            s2=0;}
        s1+=1;
        s2+=$4;}
        END {
            print ll";"s1";"s2;}' |
    tail -n +2 |
    gzip >data/aP2tn"$b"Pnb.s;
    ## sanity check
    n1=$(zcat data/tmp/aP2t"$b"Pnb.s |
        cut -d\; -f1,2 |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
        wc -l);
    n2=$(zcat data/aP2tn"$b"Pnb.s | wc -l);
    echo "n1: $n1 n2: $n2 diff: $((n1-n2))";
    n3=$(zcat data/tmp/aP2t"$b"Pnb.s |
        cut -d\; -f1-3 |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
        wc -l);
    n4=$(zcat data/aP2tn"$b"Pnb.s |
        awk -F\; '{s+=$3} END {print s}');
    echo "n3: $n3 n4: $n4 diff: $((n3-n4))";
    n5=$(zcat data/tmp/aP2t"$b"Pnb.s |
        awk -F\; '{s+=$4} END {print s}');
    n6=$(zcat data/aP2tn"$b"Pnb.s |
        awk -F\; '{s+=$4} END {print s}');
    echo "n5: $n5 n6: $n6 diff: $((n5-n6))";
done;
## final reuse merge
zcat data/aP2tn{d,u}Pnb.s |
cut -d\; -f1,2 |
sed 's|;|@|' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u | 
LC_ALL=C LANG=C join -t\; -a1 -o 1.1 2.2 2.3 \
    - \
    <(zcat data/aP2tnuPnb.s |
        awk -F\; '{print $1"@"$2";"$3";"$4}' |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
LC_ALL=C LANG=C join -t\; -a1 -o 1.1 1.2 1.3 2.2 2.3 \
    - \
    <(zcat data/aP2tndPnb.s |
        awk -F\; '{print $1"@"$2";"$3";"$4}' |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
awk -F\; '{OFS=";"; 
    for (i=2;i<=5;i++){
        if ($i==""){
            $i=0}} 
    print $1,$2,$3,$4,$5}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/aPt2nuPbndPb.s; # 1,365,473
## totals -  not monthly
for b in {d,u}; do
    for i in {0..127}; do
        zcat data/tmp/aPtb2"$b"Pt."$i" |
        cut -d\; -f1,3,4 |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -u;
    done |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/aP2b"$b"P.s;
    zcat data/tmp/aP2b"$b"P.s |
    cut -d\; -f1,2 |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    cut -d\; -f1 |
    uniq -c |
    awk '{print $2";"$1}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/aP2n"$b"b.s;
    zcat data/tmp/aP2b"$b"P.s |
    cut -d\; -f1,3 |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    cut -d\; -f1 |
    uniq -c |
    awk '{print $2";"$1}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/aP2n"$b"P.s;
done;
## min(LatestCommitDate) over upstream; max(LatestCommitDate) over downstream 
for b in {d,u}; do
    zcat data/tmp/aP2b"$b"P.s |
    cut -d\; -f3 |
    ~/lookup/lsort 300G -t\; -u |
    gzip >data/tmp/"$b"P.s;
done;
zcat data/tmp/{d,u}P.s |
P2lcd |
gzip >data/tmp/duP2lcd.s;
for b in {d,u}; do
    LC_ALL=C LANG=C join -t\; -1 2 -o 1.1 2.2 \
        <(zcat data/tmp/aP2b"$b"P.s |
            cut -d\; -f1,3 |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat data/tmp/duP2lcd.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >data/tmp/aP2lcd"$b"P.s;
done;
## min lcd upstream
zcat data/tmp/aP2lcduP.s |
minlcd |
gzip >data/tmp/aP2mlcduP.s;
## max lcd dowstream
zcat data/tmp/aP2lcddP.s |
maxlcd |
gzip >data/tmp/aP2mlcddP.s;
# endregion 4 --------------------------------------------------------------

# region 5 ---------------------------- final table - monthly ----------------------------

## extracting json data
## single values
zcat data/{s,o}P.json |
jq -r '"\(.ProjectID);\(.EarliestCommitDate);\(.LatestCommitDate);\(.NumActiveMon);\(.NumAuthors);\(.NumCore);\(.Gender.male);\(.Gender.female);\(.CommunitySize);\(.NumForks);\(.NumCommits);\(.NumFiles);\(.NumBlobs);\(.NumStars)"' | 
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all.s;
## multiple values
zcat data/{s,o}P.json |
jq -r '.ProjectID as $p | 
    .MonNcmt | keys[] as $k | 
    "\($p);\($k);\(.[$k])"' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2monNcmt.s; # 1,691,452
zcat data/{s,o}P.json |
jq -r '.ProjectID as $p | 
    .MonNauth | keys[] as $k | 
    "\($p);\($k);\(.[$k])"' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2monNauth.s; # 1,691,452
zcat data/{s,o}P.json |
jq -r '.ProjectID as $p | 
    .FileInfo | try keys[] as $k | 
    "\($p);\($k);\(.[$k])"' |
awk -F\; '
    BEGIN {
        ll="";
        m=0;
        lm="";}
    {l=$1;
    if (l!=ll){
        print ll";"lm;
        ll=l;
        m=0;
        lm="";}
    if ($3>m && $2!="other"){
        m=$3;
        lm=$2;}}
    END {
        print ll";"lm;}' |
tail -n +2 |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2l.s; # 54,719
zcat data/{s,o}P.json |
jq -r '.ProjectID as $p | 
    .Core | keys[] as $k | 
    "\($p);\($k);\(.[$k])"' |
awk -F\; '
    BEGIN {
        ll="";
        edu=0;
        gov=0;}
    {l=$1;
    if (l!=ll){
        print ll";"edu";"gov;
        ll=l;
        edu=0;
        gov=0;}
    if ($2 ~ /\.edu>$/){
        edu=1;}
    if ($2 ~ /\.gov>$/){
        gov=1;}}
    END {
        print ll";"edu";"gov;}' |
tail -n +2 |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2EduGov.s; # 54,741
## merging json data
## language
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
    <(zcat data/tmp/aP2l.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
awk -F\; '{if (NF==14) {print $0";"null} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all2.s;
## edu & gov
LC_ALL=C LANG=C join -t\; \
    <(zcat data/tmp/aP2all2.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
    <(zcat data/tmp/aP2EduGov.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all3.s; 
## monthly commit
LC_ALL=C LANG=C join -t\; \
    <(zcat data/tmp/aP2monNcmt.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
    <(zcat data/tmp/aP2all3.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all4.s; 
## monthly author
LC_ALL=C LANG=C join -t\; \
    <(zcat data/tmp/aP2monNauth.s | 
        awk -F\; '{print $1"@"$2";"$3}' |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
    <(zcat data/tmp/aP2all4.s | 
        awk -F\; '{v=""; for (i=3;i<=NF;i++){v=v";"$i;} print $1"@"$2 v}' |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all5.s; 
## 1.ProjectID;2.month;3.MonNauth;4.MonNcmt;5.EarliestCommitDate;6.LatestCommitDate;7.NumActiveMon;8.NumAuthors;9.NumCore;10.Gender.male;11.Gender.female
## 12.CommunitySize;13.NumForks;14.NumCommits;15.NumFiles;16.NumBlobs;17.NumStars;18.language;19.edu;20.gov;
## sanity check 1: sum(MonNcmt) vs NumCommits
zcat data/tmp/aP2all5.s |
sed 's|@|;|' |
awk -F\; '
    BEGIN {
        ll="";
        s=0;}
    {l=$1;
    if(l!=ll){
        print ll";"s";"ts;
        ll=l;
        s=0;}
    s+=$4;
    ts=$14;}
    END {
        print ll";"s";"ts;}' |
tail -n +2 |
awk -F\; '{if ($2<$3) print ($2/$3)*100}';
## 38,950 sum(MonNcmt)=NumCommits
## 15,791 sum(MonNcmt)<NumCommits - range: (0.199886% - 99.9998%) - avg: 28.2492%
## sanity check 2: count(month) vs NumActiveMon
zcat data/tmp/aP2all5.s |
sed 's|@|;|' |
awk -F\; '
    BEGIN {
        ll="";
        s=0;}
    {l=$1;
    if(l!=ll){
        print ll";"s";"ts;
        ll=l;
        s=0;}
    s+=1;
    ts=$7;}
    END {
        print ll";"s";"ts;}' |
tail -n +2 |
awk -F\; '{if ($2!=$3) print }'; # ok!
## join copy reuse with all data
LC_ALL=C LANG=C join -t\; -a1 -a2 \
    <(zcat data/aPt2nuPbndPb.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
    <(zcat data/tmp/aP2all5.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) | 
awk -F\; '
    {if (NF==23 || NF==5){
        print $0}
    else {
        v="";
        for (i=2;i<=NF;i++){
            v=v";"$i;
        }
        print $1";0;0;0;0"v}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all6.s;
zcat data/tmp/aP2all6.s |
awk -F\; '{if (NF==23) print}' |
sed 's|@|;|' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all7-1.s; # 1,691,452
zcat data/tmp/aP2all6.s |
awk -F\; '{if (NF!=23) print}' |
sed 's|@|;|' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all7-2.s; # 393,008
LC_ALL=C LANG=C join -t\; \
    <(zcat data/tmp/aP2all7-2.s | LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
    <(zcat data/tmp/aP2all5.s | 
        sed 's|@|;|' |
        cut -d\; -f2-4 --complement | 
        awk -F\; '{v=""; for (i=2;i<=NF;i++){v=v";"$i;}print $1";0;0"v}' |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
        LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) | 
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all7-3.s;
## add scientific var
LC_ALL=C LANG=C join -t\; \
    <(LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1 \
        <(zcat data/sP.s | sed 's|$|;1|') \
        <(zcat data/oP.s | sed 's|$|;0|')) \
    <(zcat data/tmp/aP2all7-1.s data/tmp/aP2all7-3.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all8.s; # 2,084,460
## 1.ProjectID;2.isSci;3.month;4.nuP;5.nuPb;6.ndP;7.ndPb;8.MonNauth;9.MonNcmt;10.EarliestCommitDate;11.LatestCommitDate;12.NumActiveMon;13.NumAuthors;
## 14.NumCore;15.Gender.male;16.Gender.female;17.CommunitySize;18.NumForks;19.NumCommits;20.NumFiles;21.NumBlobs;22.NumStars;23.language;24.edu;25.gov
echo "1.ProjectID;2.isSci;3.month;4.nuP;5.nuPb;6.ndP;7.ndPb;8.MonNauth;9.MonNcmt;10.EarliestCommitDate;11.LatestCommitDate;12.NumActiveMon;13.NumAuthors;14.NumCore;15.Gender.male;16.Gender.female;17.CommunitySize;18.NumForks;19.NumCommits;20.NumFiles;21.NumBlobs;22.NumStars;23.language;24.edu;25.gov" \
>data/aP.csv;
zcat data/tmp/aP2all8.s |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u >>data/aP.csv;
# endregion 5 --------------------------------------------------------------

# region 6 ----------------------------- final table - totals -----------------------------

## scientific var
LC_ALL=C LANG=C join -t\; \
    <(LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1 \
        <(zcat data/sP.s | sed 's|$|;1|') \
        <(zcat data/oP.s | sed 's|$|;0|')) \
    <(zcat data/tmp/aP2all3.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all9.s;
## nuP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all9.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2nuP.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==18){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all10.s;
## nub
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all10.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2nub.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==19){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all11.s;
## ndP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all11.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2ndP.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==20){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all12.s;
## ndb
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all12.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2ndb.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==21){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all13.s;
## nPkg
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all13.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2nPkg.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==22){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all14.s;
## remove nulls and empty language field
zcat data/tmp/aP2all14.s |
awk -F\; '{OFS=";";
    for (i=8;i<=15;i++) {
        if ($i=="null"){
            $i=0;}}
    if ($16==""){
        $16="other";}
    print}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all15.s;
## LayerNum;LayerName;Field;mentionsPaperOrFunding
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all15.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(tail -n +2 <data/sP.csv |
        cut -d\; -f1,4,5,7,25 |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==23){
    print $0";nonSci;nonSci;nonSci;nonSci"} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all16.s;
## mlcduP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all16.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2mlcduP.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==27){print $0";null"} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all17.s;
## sanity check
zcat data/tmp/aP2buP.s | 
grep -f <(zcat data/tmp/aP2all17.s | 
    grep ";null$" | 
    awk -F\; '{if ($19>0) print}' | 
    cut -d\; -f1 | 
    sed 's|^|^|;s|$|;|') | 
    cut -d\; -f3 | 
    sort -u >tmp/test;
zcat data/tmp/duP2lcd.s | 
grep -f <(sed 's|^|^|;s|$|;|' <tmp/test) | 
awk -F\; '{if ($2<1704110400 && $2>788961600) print}' |
wc -l # should be 0
## mlcddP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all17.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2mlcddP.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==28){print $0";null"} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all18.s;
## sanity check
zcat data/tmp/aP2bdP.s | 
grep -f <(zcat data/tmp/aP2all18.s | 
    grep ";null$" | 
    awk -F\; '{if ($21>0) print}' | 
    cut -d\; -f1 | 
    sed 's|^|^|;s|$|;|') | 
    cut -d\; -f3 | 
    sort -u >tmp/test;
zcat data/tmp/duP2lcd.s | 
grep -f <(sed 's|^|^|;s|$|;|' <tmp/test) | 
awk -F\; '{if ($2<1704110400 && $2>788961600) print}' |
wc -l # should be 0
## remove nPkg
zcat data/tmp/aP2all18.s | 
cut -d\; -f23 --complement |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all19.s;
## nuP-d
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all19.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2nuP-d.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==28){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all20.s;
## nPkg
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all20.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2nPkg.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==29){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all21.s;
## ndP-d
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all21.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2ndP-d.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==30){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all22.s;
## nDef
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all22.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2nDef.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==31){print $0";"0} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all23.s;
## d-mlcduP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all23.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2mlcduP-d.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==32){print $0";null"} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all24.s;
## d-mlcddP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP2all24.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
    <(zcat data/tmp/aP2mlcddP-d.s |
        LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) |
awk -F\; '{if (NF==33){print $0";null"} else {print $0}}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP2all25.s;

## final csv
echo "ProjectID;isSci;EarliestCommitDate;LatestCommitDate;NumActiveMon;NumAuthors;NumCore;male;female;CommunitySize;NumForks;NumCommits;NumFiles;NumBlobs;NumStars;language;edu;gov;c-nuP;c-nub;c-ndP;c-ndb;LayerNum;LayerName;Field;mentionsPaperOrFunding;c-mlcduP;c-mlcddP;d-nuP;d-nPkg;d-ndP;d-nDef;d-mlcduP;d-mlcddP" \
>data/aP-t.csv;
zcat data/tmp/aP2all25.s |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u >>data/aP-t.csv;
# endregion 6 ----------------------------------------------------------------------------

# region 7 --------------------------- non-sci sample revision ---------------------------

# region 7.1 - non-sientific sample
## creating bins
a=(3 11 26 61 10000000);
c=(301 751 1801 5001 100000000);
t=(300000000 1451649600 1546344000 1750000000);
for i in {1..4}; do
    al=${a[$i]};
    au=${a[$((i+1))]};
    for j in {1..4}; do
        cl=${c[$j]};
        cu=${c[$((j+1))]};
        for k in {1..3}; do
            tl=${t[$k]};
            tu=${t[$((k+1))]};
            zcat data/tmp/sP2nTnAnC.s |
            awk -F\; \
                -v al="$al" -v au="$au" \
                -v cl="$cl" -v cu="$cu" \
                -v tl="$tl" -v tu="$tu" \
                '{if ($3>=al && $3<au && $4>=cl && $4<cu && $2>=tl && $2<tu) print $1}' |
            ~/lookup/lsort 10G -t\; -u |
            gzip >"data/tmp/sP$i$j$k.s";
            n1=$(zcat "data/tmp/sP$i$j$k.s" | wc -l);
            # shellcheck disable=SC2016
            echo "$al;$au;$cl;$cu;$tl;$tu;$n1" |
            python3 -uc ' 
import sys
from pymongo import MongoClient
from bson.json_util import dumps
import random

client = MongoClient("mongodb://da1.eecs.utk.edu/")
db = client["WoC"]
coll = db["P_metadata.V"]

input = sys.stdin.read().splitlines()
limits=input[0].split(";");

c=coll.find({
    "NumAuthors" : { "$gte": int(limits[0]), "$lt": int(limits[1])}, 
    "NumCommits" : { "$gte": int(limits[2]), "$lt": int(limits[3])},
    "EarliestCommitDate" : { "$gte": int(limits[4]), "$lt": int(limits[5])},
    "NumFiles": { "$gt": 5 },
    "NumActiveMon": { "$gt": 6 },
    "LatestCommitDate": { "$gt": 1542572838 }
    },
    {"ProjectID" : 1},
    no_cursor_timeout=True)
res=[];
for r in c:
    res.append(dumps(r))
c.close()

count=int(limits[6])*3
for p in random.choices(res,k=count):
    print(p)
                ' 2>"data/tmp/pyErr.$i$j$k" | 
            gzip >"data/tmp/bin$i$j$k.json";
            zcat "data/tmp/bin$i$j$k.json" |
            jq -r '.ProjectID' |
            ~/lookup/lsort 10G -t\; -u |
            LC_ALL=C LANG=C join -t\; -v1 \
                - \
                <(zcat "data/tmp/sP$i$j$k.s") |
            shuf -n $((n1*2));
        done;
    done;
done |
~/lookup/lsort 10G -t\; -u |
gzip >data/oP2.s; # 36,494
## getting data from mongo
zcat data/oP2.s |
P2mon |
gzip >data/oP2.json;
## sanity check
for v in {NumAuthors,NumCommits,NumFiles,NumActiveMon,LatestCommitDate}; do
    echo "$v";
    for f in {sP,oP,oP2}; do
        min=$(zcat "data/$f.json" |
            jq -r ."$v" | 
            sort -n | head -1);
        max=$(zcat "data/$f.json" |
            jq -r ."$v" | 
            sort -nr | head -1);
        echo "$f - min: $min - max: $max";
    done;
done;
# endregion 7.1

# region 7.2 - dependency
# region 7.2.1 defined packages
zcat data/{sP,oP2}.s | 
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP2.s;
dir="/nfs/home/audris/work/c2fb";
for i in {0..127}; do
    LC_ALL=C LANG=C join -t\; \
        <(zcat "$dir/c2PtAbflDefFullV$i.s" |
            cut -d\; -f2,7,8 |
            LC_ALL=C LANG=C sort -T ./tmp/ -t\; -k1,1) \
        <(zcat data/tmp/aP2.s) |
    LC_ALL=C LANG=C sort -T ./tmp/ -t\; -u |
    gzip >"data/tmp/aP22lDef.$i";
done;
zcat data/tmp/aP22lDef.{0..127} |
awk -F\; '{print $1";"$2"@:@"$3}' |
awk -F"@:@" '{if ($2!="") print}' |
~/lookup/lsort 50G -t\; -u |
gzip >data/aP22lDef.s;
rm data/tmp/aP22lDef.{0..127};
## nDef
zcat data/aP22lDef.s |
cut -d\; -f1 |
uniq -c |
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP22nDef.s;
# endregion 7.2.1

# region 7.2.2 downstream projects
zcat data/aP22lDef.s |
cut -d\; -f2 |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/definedPackages2.s;
for i in {0..127}; do
    LC_ALL=C LANG=C join -t\; \
        <(zcat "$dir/c2PtAbflPkgFullV$i.s" |
            awk -F\; '{OFS=";";for (i=8;i<=NF;i++) print $7"@:@"$i,$2}' |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
        <(zcat data/definedPackages2.s | 
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/lDef2dP2.$i";
done;
## join with aP
for i in {0..127}; do
    LC_ALL=C LANG=C join -t\; -1 2 -o 1.1 2.2 \
        <(zcat data/aP22lDef.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat "data/tmp/lDef2dP2.$i" | 
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22dP.$i";
done;
./rSort.sh data/tmp/aP22dP.{0..127} |
awk -F\; '{if ($2!=$1) print}' |
gzip >data/tmp/aP22dP.s;
# ndP-d
zcat data/tmp/aP22dP.s |
cut -d\; -f1 |
uniq -c |
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP22ndP-d.s;
# endregion 7.2.2

# region 7.2.3 used packages
for i in {0..127}; do
    LC_ALL=C LANG=C join -t\; -1 2 \
        <(zcat "$dir/c2PtAbflPkgFullV$i.s" |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat data/tmp/aP2.s) |
    awk -F\; '{OFS=";";for (i=8;i<=NF;i++) print $1,$7"@:@"$i}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22lPkg.$i";
done;
zcat data/tmp/aP22lPkg.{0..127} |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/aP22lPkg.s;
rm data/tmp/aP22lPkg.{0..127};
# nPkg
zcat data/aP22lPkg.s | 
cut -d\; -f1 | 
uniq -c | 
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP22nPkg.s;
# endregion 7.2.3

# region 7.2.4 upstream projects
zcat data/aP22lPkg.s |
cut -d\; -f2 |
awk -F"@:@" '{if ($2!="") print}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/usedPackages2.s;
for i in {0..127}; do
    LC_ALL=C LANG=C join -t\; \
        <(zcat "$dir/c2PtAbflDefFullV$i.s" |
            awk -F\; '{print $7"@:@"$8";"$2}' |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
        <(zcat data/usedPackages2.s) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/lPkg22uP.$i";
done;
for i in {0..127}; do
    LC_ALL=C LANG=C join -t\; -1 2 -o 1.1 2.2 \
        <(zcat data/aP22lPkg.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat "data/tmp/lPkg22uP.$i" |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    awk -F\; '{if($1!=$2) print}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22uP.$i";
done;
zcat data/tmp/aP22uP.{0..127} |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP22uP.s;
rm data/tmp/aP22uP.{0..127};
# nuP-d
zcat data/tmp/aP22uP.s |
cut -d\; -f1 |
uniq -c |
awk '{print $2";"$1}' |
LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
gzip >data/tmp/aP22nuP-d.s;
# endregion 7.2.4

# region 7.2.5 min/max Latest commit date up/downstream
## uniq upstream/downstream
for g in {u,d}; do
    zcat "data/tmp/aP22${g}P.s" |
    cut -d\; -f2 |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/${g}P2-d.s";
done;
## getting latest commit date (on da)
zcat data/tmp/{u,d}P2-d.s |
~/lookup/lsort 300G -u |
P2lcd |
gzip >data/tmp/udP2-d2lcd.s;

# join with aP
for g in {u,d}; do
    LC_ALL=C LANG=C join -t\; -1 2 -o 1.1 2.2 \
        <(zcat "data/tmp/aP22${g}P.s" |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat data/tmp/udP2-d2lcd.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22lcd${g}P-d.s";
done;
## min upstream
zcat data/tmp/aP22lcduP-d.s |
minlcd |
gzip >data/tmp/aP22mlcduP-d.s;
## max downstream
zcat data/tmp/aP22lcddP-d.s |
maxlcd |
gzip >data/tmp/aP22mlcddP-d.s;
# endregion 7.2.5

# endregion 7.2 

# region 7.3 copy reuse

# region 7.3.1 downstream/upstream
for i in {0..127}; do
    ## dowstream projects
    LC_ALL=C LANG=C join -t\; -o 1.1 1.4 1.3 \
        <(zcat "../reuse-msr/data/Ptb2PtFullV$i.s" |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) \
        <(zcat data/tmp/aP2.s | 
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22dPb.$i";
    zcat "data/tmp/aP22dPb.$i" |
    cut -d\; -f1-2 |
    uniq -c |
    awk '{print $2";"$1}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22dPnb.$i";
    ## upstream projects
    LC_ALL=C LANG=C join -t\; -1 4 -o 1.4 1.1 1.3 \
        <(zcat "../reuse-msr/data/Ptb2PtFullV$i.s" |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k4,4) \
        <(zcat data/tmp/aP2.s | 
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22uPb.$i";
    zcat "data/tmp/aP22uPb.$i" |
    cut -d\; -f1-2 |
    uniq -c |
    awk '{print $2";"$1}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22uPnb.$i";
done;
# endregion 7.3.1

# region 7.3.2 merge 
for g in {u,d}; do
    zcat "data/tmp/aP22${g}Pnb".{0..127} |
    LC_ALL=C LANG=C sort -T ./tmp -t\; |
    awk -F\; '{OFS=";"; print $1,$2"@"$3}' |
    awk -F@ '
        BEGIN {
            ll="";
            s=0;
        }
        {
            l=$1;
            if (ll!=l){
                print ll";"s;
                ll=l;
                s=0;
            }
            s+=$2;
        }
        END {
            print ll";"s;
        }
    ' |
    tail -n +2 |
    gzip >"data/tmp/aP22${g}Pnb.s";
    rm "data/tmp/aP22${g}Pnb".{0..127};
    ## second merge
    zcat "data/tmp/aP22${g}Pnb.s" |
    awk -F\; '
        BEGIN {
            ll="";
            s1=0;
            s2=0;
        }
        {
            l=$1;
            if (ll!=l){
                print ll";"s1";"s2;
                ll=l;
                s1=0;
                s2=0;
            }
            s1+=1;
            s2+=$3;
        }
        END {
            print ll";"s1";"s2;
        }
    ' |
    tail -n +2 |
    gzip >"data/tmp/aP22n${g}Pnb.s";
    # nb
    zcat "data/tmp/aP22${g}Pb".{0..127} |
    cut -d\; -f1,3 |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    cut -d\; -f1 |
    uniq -c |
    awk '{print $2";"$1}' |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22n${g}b.s";
done;
# endregion 7.3.2

# region 7.3.3 min/max Latest commit date up/downstream
for g in {u,d}; do
    zcat "data/tmp/aP22${g}Pnb.s" |
    cut -d\; -f2 |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/${g}P2.s";
done;
# lastest commit date (on da)
zcat data/tmp/{u,d}P2.s |
~/lookup/lsort 300G -u |
P2lcd |
gzip >data/tmp/udP22lcd.s;

# join with aP
for g in {u,d}; do
    LC_ALL=C LANG=C join -t\; -1 2 -o 1.1 2.2 \
        <(zcat "data/tmp/aP22${g}Pnb.s" |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k2,2) \
        <(zcat data/tmp/udP22lcd.s |
            LC_ALL=C LANG=C sort -T ./tmp -t\; -k1,1) |
    LC_ALL=C LANG=C sort -T ./tmp -t\; -u |
    gzip >"data/tmp/aP22lcd${g}P.s";
done;
## min lcd upstream
zcat data/tmp/aP22lcduP.s |
minlcd |
gzip >data/tmp/aP22mlcduP.s;
## max lcd dowstream
zcat data/tmp/aP22lcddP.s |
maxlcd |
gzip >data/tmp/aP22mlcddP.s;
# endregion 7.3.3

# endregion 7.3

# region 7.4 final table
# extracting json data
zcat data/{sP,oP2}.json |
jq -r '"\(.ProjectID);\(.EarliestCommitDate);\(.LatestCommitDate);\(.NumActiveMon);\(.NumAuthors);\(.NumCore);\(.Gender.male);\(.Gender.female);\(.CommunitySize);\(.NumForks);\(.NumCommits);\(.NumFiles);\(.NumBlobs);\(.NumStars)"' | 
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all.s;
## remove nulls 
zcat data/tmp/aP22all.s |
awk -F\; '{OFS=";";
    for (i=7;i<=NF;i++) {
        if ($i=="null"){
            $i=0;}}
    print}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all1.s;

## aP22l
zcat data/{sP,oP2}.json |
jq -r '.ProjectID as $p | 
    .FileInfo | try keys[] as $k | 
    "\($p);\($k);\(.[$k])"' |
awk -F\; '
    BEGIN {
        ll="";
        m=0;
        lm="";}
    {l=$1;
    if (l!=ll){
        print ll";"lm;
        ll=l;
        m=0;
        lm="";}
    if ($3>m && $2!="other"){
        m=$3;
        lm=$2;}}
    END {
        print ll";"lm;}' |
tail -n +2 |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22l.s;
# aP22EduGov
zcat data/{sP,oP2}.json |
jq -r '.ProjectID as $p | 
    .Core | keys[] as $k | 
    "\($p);\($k);\(.[$k])"' |
awk -F\; '
    BEGIN {
        ll="";
        edu=0;
        gov=0;}
    {l=$1;
    if (l!=ll){
        print ll";"edu";"gov;
        ll=l;
        edu=0;
        gov=0;}
    if ($2 ~ /\.edu>$/){
        edu=1;}
    if ($2 ~ /\.gov>$/){
        gov=1;}}
    END {
        print ll";"edu";"gov;}' |
tail -n +2 |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22EduGov.s;
# include other gov and edu emails
zcat data/{sP,oP2}.json |
jq -r '.ProjectID as $p | 
    .Core | keys[] as $k | 
    "\($p);\($k);\(.[$k])"' |
awk -F\; '
    BEGIN {
        ll="";
        edu=0;
        gov=0;}
    {l=$1;
    if (l!=ll){
        print ll";"edu";"gov;
        ll=l;
        edu=0;
        gov=0;}
    if ($2 ~ /\.edu(\.[a-zA-Z]{2,})?>/){
        edu=1;}
    if ($2 ~ /\.gov(\.[a-zA-Z]{2,})?>/){
        gov=1;}}
    END {
        print ll";"edu";"gov;}' |
tail -n +2 |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22EduGov2.s;

# merging data
## language
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all1.s | ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22l.s | ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{OFS=";";if ($15=="") {$15="other"}; print}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all2.s;
## edu & gov
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all2.s | ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22EduGov.s | ~/lookup/lsort 10G -t\; -k1,1) |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all3.s; 
## scientific var
LC_ALL=C LANG=C join -t\; \
    <(~/lookup/lsort 10G -t\; -k1,1 \
        <(zcat data/sP.s | sed 's|$|;1|') \
        <(zcat data/oP2.s | sed 's|$|;0|')) \
    <(zcat data/tmp/aP22all3.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all4.s;
## nuP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all4.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22nuPnb.s |
        cut -d\; -f1,2 |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==18){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all5.s;
## nub
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all5.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22nub.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==19){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all6.s;
## mlcduP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all6.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22mlcduP.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==20){print $0";null"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all7.s;
## ndP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all7.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22ndPnb.s |
        cut -d\; -f1,2 |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==21){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all8.s;
## ndb
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all8.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22ndb.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==22){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all9.s;
## mlcddP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all9.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22mlcddP.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==23){print $0";null"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all10.s;
## nuP-d
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all10.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22nuP-d.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==24){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all11.s;
## nPkg
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all11.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22nPkg.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==25){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all12.s;
## d-mlcduP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all12.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22mlcduP-d.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==26){print $0";null"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all13.s;
## ndP-d
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all13.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22ndP-d.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==27){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all14.s;
## nDef
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all14.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22nDef.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==28){print $0";0"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all15.s;
## d-mlcddP
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all15.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22mlcddP-d.s |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==29){print $0";null"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all16.s;
## LayerNum;LayerName;Field;mentionsPaperOrFunding
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all16.s |
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(tail -n +2 <data/sP.csv |
        cut -d\; -f1,4,5,7,25 |
        ~/lookup/lsort 10G -t\; -k1,1) |
awk -F\; '{if (NF==30){
    print $0";nonSci;nonSci;nonSci;nonSci"} else {print $0}}' |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all17.s;
## gov2
LC_ALL=C LANG=C join -t\; -a1 \
    <(zcat data/tmp/aP22all17.s | ~/lookup/lsort 10G -t\; -k1,1) \
    <(zcat data/tmp/aP22EduGov2.s | ~/lookup/lsort 10G -t\; -k1,1) |
~/lookup/lsort 10G -t\; -u |
gzip >data/tmp/aP22all18.s; 

## final csv
echo "ProjectID;isSci;EarliestCommitDate;LatestCommitDate;NumActiveMon;NumAuthors;NumCore;male;female;CommunitySize;NumForks;NumCommits;NumFiles;NumBlobs;NumStars;language;edu;gov;c-nuP;c-nub;c-mlcduP;c-ndP;c-ndb;c-mlcddP;d-nuP;d-nPkg;d-mlcduP;d-ndP;d-nDef;d-mlcddP;LayerNum;LayerName;Field;mentionsPaperOrFunding;edu2;gov2" \
>data/aP2-t.csv;
zcat data/tmp/aP22all18.s |
~/lookup/lsort 10G -t\; -u >>data/aP2-t.csv;

## sanity check
LC_ALL=C LANG=C join -t\; \
    <(tail -n +2 <data/aP-t.csv | 
        cut -d\; -f1 | 
        ~/lookup/lsort 10G -t\; -k1,1) \
    <(tail -n +2 <data/aP2-t.csv | 
        cut -d\; -f1 | 
        ~/lookup/lsort 10G -t\; -k1,1) >commonP;
# 
head -1 <data/aP-t.csv |
awk -F\; '{for (i=0; i<=NF; i++) print $i}' |
while read -r f; do
    head -1 <data/aP2-t.csv |
    awk -F\; -v f="$f" '{ for (i=1;i<=NF;i++) {if ($i==f) print "$"i}}'
done |
awk '{printf "%s,", $0} END {print ""}';
# 
awk -F\; '{OFS=";"; print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$22,$23,$31,$32,$33,$34,$21,$24,$25,$26,$28,$29,$27,$30}' <data/aP2-t.csv |
~/lookup/lsort 10G -t\; -k1,1 |
LC_ALL=C LANG=C join -t\; \
    commonP \
    - |
gzip >new;
#
~/lookup/lsort 10G -t\; -k1,1 <data/aP-t.csv |
LC_ALL=C LANG=C join -t\; \
    commonP \
    - |
gzip >old;
#
for i in {1..35}; do 
    n=$(diff \
            <(zcat old | cut -d\; -f "$i") \
            <(zcat new | cut -d\; -f "$i") | 
        wc -l); 
    if (( n > 0 )); then 
        echo "$i"; 
    fi; 
done |
while read -r n; do
    f=$(head -1 <data/aP-t.csv |
        cut -d\; -f "$n");
    echo "$n;$f";
done


# endregion 7.4

# endregion 7
