FROM gcc:latest

RUN useradd icecc
RUN echo "alias ll='ls -al'" > /root/.bashrc
WORKDIR /home/icecc
RUN cp -p /usr/share/zoneinfo/Asia/Seoul /etc/localtime
#ENV ProxyMode=`ping -c 1 -w 1 updateproxy.neople.co.kr | grep % | cut -f3 -d"," | cut -f2 -d" " | cut -c1-1 `

RUN if [ "`ping -c 1 -w 1 updateproxy.neople.co.kr | grep % | cut -f3 -d"," | cut -f2 -d" " | cut -c1-1`" = "0" ];then \
    echo 'Acquire::http::proxy "http://updateproxy.neople.co.kr:9999/";' > /etc/apt/apt.conf.d/80proxy;\
    git config --global http.proxy http://updateproxy.neople.co.kr:9999;\
    git config --global https.proxy http://updateproxy.neople.co.kr:9999;\
    git config --global url."https://".insteadOf git://;\
    git config --global url."http://".insteadOf git://; fi

RUN apt-get update -y --force-yes
RUN apt-get install -y libcap-ng-dev liblzo2-dev git docbook2x vim locales zstd libzstd-dev libarchive-dev cron logrotate net-tools --force-yes
RUN git clone https://github.com/icecc/icecream.git
WORKDIR icecream
RUN for ports in 8765 8766 8767 8768 8769 10245 10246 10247; do         find ./ -type f -name *.cpp -exec sed -i s/${ports}/`expr ${ports} + 10000`/g {} \;;         find ./ -type f -name *.xml -exec sed -i s/${ports}/`expr ${ports} + 10000`/g {} \;;         find ./ -type f -name *.md -exec sed -i s/${ports}/`expr ${ports} + 10000`/g {} \;;         find ./ -type f -name *.h -exec sed -i s/${ports}/`expr ${ports} + 10000`/g {} \;;         find ./ -type f -name *.scheduler -exec sed -i s/${ports}/`expr ${ports} + 10000`/g {} \;;         find ./ -type f -name *.icecc  -exec sed -i s/${ports}/`expr ${ports} + 10000`/g {} \;; done
#Enter a icecream tag name if you want a specific icecream version
#Tags Url : https://github.com/icecc/icecream/tags <--
#RUN git checkout 1.1rc2
RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install
ENV PATH "/home/icecc/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
RUN touch /var/log/iceccd.log /var/log/icecc-scheduler.log
RUN chown icecc:icecc /var/log/iceccd.log /var/log/icecc-scheduler.log
RUN chown icecc:icecc /var/log/icecc-scheduler.log
#CMD iceccd -d -s $ICECREAM_SCHEDULER_HOST -l /var/log/icecc.log && tail -f /var/log/icecc.log
ADD ./Enable-iceccd-scheduler.sh /root/Enable-iceccd-scheduler.sh
ADD ./iceccd /etc/logrotate.d/iceccd
ADD ./icecc-scheduler /etc/logrotate.d/icecc-scheduler
RUN chmod 755 /root/*.sh
CMD /root/Enable-iceccd-scheduler.sh
EXPOSE 20245/tcp 18765/tcp 18766/tcp 18765/udp
