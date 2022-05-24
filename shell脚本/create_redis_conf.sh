#!/bin/bash

echo '6480.conf 6481.conf 7479.conf 7480.conf 7481.conf 6779.conf 6780.conf 6781.conf 7779.conf 7780.conf 7781.conf' | xargs -n 1 cp 6479.conf

sed -i 's/6479/6480/g' ./6480.conf &&\
sed -i 's/6479/6481/g' ./6481.conf &&\
sed -i 's/6479/7479/g' ./7479.conf &&\
sed -i 's/6479/7480/g' ./7480.conf &&\
sed -i 's/6479/7481/g' ./7481.conf &&\
sed -i 's/6479/6779/g' ./6779.conf &&\
sed -i 's/6479/6780/g' ./6780.conf &&\
sed -i 's/6479/6781/g' ./6781.conf &&\
sed -i 's/6479/7779/g' ./7779.conf &&\
sed -i 's/6479/7780/g' ./7780.conf &&\
sed -i 's/6479/7781/g' ./7781.conf
