FROM alexagency/centos6-gnome
MAINTAINER Alex

RUN yum -y update && \
    yum -y install xorg-x11-server-utils which prelink git wget tar bzip2 meld firefox*i686 \
        glibc.i686 libgcc.i686 gtk2*.i686 libXtst*.i686 alsa-lib-1.*.i686 \
        dbus-glib-0.*.i686 libXt-1.*.i686 gtk2-engines gtk2-devel && \
    yum clean all && rm -rf /tmp/*

# JDK x86
ENV JDK_URL http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-i586.rpm
RUN wget -c --no-cookies  --no-check-certificate  --header \
"Cookie: oraclelicense=accept-securebackup-cookie" $JDK_URL -O jdk.rpm && \
    rpm -i jdk.rpm && rm -fv jdk.rpm
# Firefox x86 Java plugin
RUN alternatives --install /usr/lib/mozilla/plugins/libjavaplugin.so libjavaplugin.so \
    /usr/java/latest/jre/lib/i386/libnpjp2.so 200000
# Visual VM
RUN echo -e "\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Visual VM\n\
Comment=Visual VM\n\
Exec=/usr/java/latest/bin/jvisualvm\n\
Icon=gnome-panel-fish\n\
Categories=Application;Development;Java\n\
Version=1.0\n\
Type=Application\n\
Terminal=0"\
>> /usr/share/applications/jvisualvm.desktop

# Sublime Text 3
ENV SUBLIME_URL http://c758482.r82.cf2.rackcdn.com/sublime_text_3_build_3083_x64.tar.bz2
RUN wget $SUBLIME_URL && \
    tar -vxjf `echo "${SUBLIME_URL##*/}"` -C /usr && \
    ln -s /usr/sublime_text_3/sublime_text /usr/bin/sublime3 && \
    rm -f `echo "${SUBLIME_URL##*/}"` && \
echo -e "\
[Desktop Entry]\n\
Name=Sublime 3\n\
Exec=sublime3\n\
Terminal=false\n\
Icon=/usr/sublime_text_3/Icon/48x48/sublime-text.png\n\
Type=Application\n\
Categories=TextEditor;IDE;Development\n\
X-Ayatana-Desktop-Shortcuts=NewWindow\n\
[NewWindow Shortcut Group]\n\
Name=New Window\n\
Exec=sublime -n\n\
TargetEnvironment=Unity"\
>> /usr/share/applications/sublime3.desktop && \
    mkdir /root/.config && \
    touch /root/.config/sublime-text-3 && \
    chown -R root:root /root/.config/sublime-text-3 && \
    sed -i 's@gedit.desktop@gedit.desktop;sublime3.desktop@g' /usr/share/applications/defaults.list

# Eclipse Luna x86
ENV ECLIPSE_URL http://ftp-stud.fht-esslingen.de/pub/Mirrors/eclipse/technology/epp/downloads\
/release/mars/1/eclipse-jee-mars-1-linux-gtk.tar.gz
RUN wget $ECLIPSE_URL && \
    tar -zxvf `echo "${ECLIPSE_URL##*/}"` -C /usr/ && \
    ln -s /usr/eclipse/eclipse /usr/bin/eclipse && \
    rm -f `echo "${ECLIPSE_URL##*/}"` && \
    sed -i s@-vmargs@-vm\\n/usr/java/latest/jre/bin/java\\n-vmargs@g /usr/eclipse/eclipse.ini

# Configure profile
RUN echo "xhost +" >> /home/user/.bashrc && \
    echo "alias install='sudo yum install'" >> /home/user/.bashrc && \
    echo "alias docker='sudo docker'" >> /home/user/.bashrc && \
    echo -e '\
alias dockerX11run="docker run -ti --rm \
--add-host=localhost:`hostname --ip-address` \
-e DISPLAY=`hostname --ip-address`$DISPLAY" '\
>> /home/user/.bashrc && \
    echo -e '\n\
X64_HOSTMANE=`hostname`-x64 \n\
X64_RUNNING=$(docker inspect -f {{.State.Running}} $X64_HOSTMANE 2> /dev/null) \n\
if [ "$X64_RUNNING" == "true" ]; then \n\
    alias workstation-x64="docker exec -ti $X64_HOSTMANE" \n\
else \n\
    alias workstation-x64="dockerX11run \
--hostname $X64_HOSTMANE \
--name $X64_HOSTMANE \
--link `hostname`:$X64_HOSTMANE \
-v /shared/Downloads:/home/user/Downloads \
alexagency/centos6-workstation-x64" \n\
fi \n '\
>> /home/user/.bashrc && \
    shopt -s expand_aliases

# Firefox x64
RUN echo -e '\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Firefox x64\n\
Exec=sh -c "source /home/user/.bashrc;eval workstation-x64 firefox"\n\
Icon=gnome-panel-fish\n\
Terminal=true\n\
Type=Application\n\
Categories=Network;WebBrowser;'\
>> /usr/share/applications/firefox-x64.desktop

# Eclipse x64
RUN echo -e '\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Eclipse x64\n\
Comment=Eclipse\n\
Exec=sh -c "source /home/user/.bashrc;eval workstation-x64 eclipse"\n\
Icon=/usr/eclipse/icon.xpm\n\
Categories=Application;Development;Java;IDE\n\
Version=1.0\n\
Type=Application\n\
Terminal=true'\
>> /usr/share/applications/eclipse-x64.desktop

# Visual VM x64
RUN echo -e '\
[Desktop Entry]\n\
Encoding=UTF-8\n\
Name=Visual VM x64\n\
Comment=Visual VM\n\
Exec=sh -c "source /home/user/.bashrc;eval /usr/java/latest/bin/jvisualvm"\n\
Icon=gnome-panel-fish\n\
Categories=Application;Development;Java\n\
Version=1.0\n\
Type=Application\n\
Terminal=true'\
>> /usr/share/applications/jvisualvm-x64.desktop
