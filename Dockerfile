FROM alexagency/centos6-gnome
MAINTAINER Alex

USER root

RUN yum -y update && \
    yum -y install xorg-x11-server-utils which prelink git wget tar bzip2 meld \
        firefox*i686 libXtst-devel.i686 gtk2.i686 gtk2-engines.i686 gtk2-devel.i686 && \
    yum clean all && rm -rf /tmp/* && \
    touch /var/lib/dbus/machine-id && dbus-uuidgen > /var/lib/dbus/machine-id

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
Name=Visual VM\n\
Exec=/usr/java/latest/bin/jvisualvm\n\
Icon=gnome-panel-fish\n\
Categories=Application;Development;Java\n\
Type=Application\n\
Terminal=false"\
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
    cp /usr/share/applications/sublime3.desktop \
    /home/user/Desktop/sublime3.desktop && \
    chown user:user /home/user/Desktop/sublime3.desktop && \
    sed -i 's\gedit.desktop\gedit.desktop;sublime3.desktop\g' \
    /usr/share/applications/defaults.list

# Eclipse Luna x86
ENV ECLIPSE_URL http://ftp-stud.fht-esslingen.de/pub/Mirrors/eclipse/technology/epp/downloads\
/release/mars/1/eclipse-jee-mars-1-linux-gtk.tar.gz
RUN wget $ECLIPSE_URL && \
    tar -zxvf `echo "${ECLIPSE_URL##*/}"` -C /usr/ && \
    ln -s /usr/eclipse/eclipse /usr/bin/eclipse && \
    rm -f `echo "${ECLIPSE_URL##*/}"`

# Configure profile
RUN echo "xhost +" >> /home/user/.bashrc && \
    echo "alias install='sudo yum install'" >> /home/user/.bashrc && \
    echo "alias docker='sudo docker'" >> /home/user/.bashrc && \
    echo -e '\
alias dockerX11run="docker run -ti --rm \
-e DISPLAY=`hostname --ip-address`$DISPLAY" '\
>> /home/user/.bashrc && \
    echo -e '\n\
X64=`hostname`-x64 \n\
X64_RUNNING=$(docker inspect -f {{.State.Running}} $X64 2> /dev/null) \n\
if [ "$X64_RUNNING" == "true" ]; then \n\
    alias workstation-x64="docker exec -ti $X64" \n\
else \n\
    alias workstation-x64="dockerX11run \
--hostname $X64 \
--name $X64 \
--link `hostname`:$X64 \
-v /shared:/home/user/Public \
alexagency/centos6-workstation-x64" \n\
fi \n '\
>> /home/user/.bashrc && \
    echo -e '\n\
CENTOS7_X86=`hostname`-centos7-x86 \n\
CENTOS7_X86_RUNNING=$(docker inspect -f {{.State.Running}} $CENTOS7_X86 2> /dev/null) \n\
if [ "$CENTOS7_X86_RUNNING" == "true" ]; then \n\
    alias centos7-x86="docker exec -ti $CENTOS7_X86" \n\
else \n\
    alias centos7-x86="dockerX11run \
--hostname $CENTOS7_X86 \
--name $CENTOS7_X86 \
--link `hostname`:$CENTOS7_X86 \
-v /shared:/home/user/Public \
alexagency/centos7-jdk-x86" \n\
fi \n '\
>> /home/user/.bashrc && \
    shopt -s expand_aliases

# Startup script
RUN echo "#!/bin/sh" > /etc/init.d/startup && \
    echo "chown user:user /home/user/Public &" >> /etc/init.d/startup && \
    chmod +x /etc/init.d/startup && \
    echo -e "\
[program:startup] \n\
command=/etc/init.d/startup restart \n\
stderr_logfile=/var/log/supervisor/startup-error.log \n\
stdout_logfile=/var/log/supervisor/startup.log "\ 
> /etc/supervisord.d/startup.conf

# Terminal x64
RUN echo -e "\
[Desktop Entry]\n\
Name=Terminal x64\n\
Exec=sh -c 'source /home/user/.bashrc;eval workstation-x64 bash'\n\
Icon=utilities-terminal\n\
Type=Application\n\
Terminal=true\n\
Categories=GNOME;GTK;Utility;TerminalEmulator;System;"\
>> /usr/share/applications/terminal-x64.desktop

# Terminal Centos7
RUN echo -e "\
[Desktop Entry]\n\
Name=Terminal Centos7\n\
Exec=sh -c 'source /home/user/.bashrc;eval centos7-x86 bash'\n\
Icon=utilities-terminal\n\
Type=Application\n\
Terminal=true\n\
Categories=GNOME;GTK;Utility;TerminalEmulator;System;"\
>> /usr/share/applications/terminal-centos7.desktop

# Firefox x86
RUN echo -e "\
[Desktop Entry]\n\
Name=Firefox\n\
Exec=firefox %u\n\
Icon=firefox\n\
Terminal=false\n\
Type=Application\n\
Categories=Network;WebBrowser;"\
>> /usr/share/applications/firefox.desktop && \
    cp /usr/share/applications/firefox.desktop \
    /home/user/Desktop/firefox.desktop && \
    chown user:user /home/user/Desktop/firefox.desktop

# Firefox x64
RUN echo -e "\
[Desktop Entry]\n\
Name=Firefox x64\n\
Exec=sh -c 'source /home/user/.bashrc;eval workstation-x64 firefox'\n\
Icon=firefox\n\
Terminal=true\n\
Type=Application\n\
Categories=Network;WebBrowser;"\
>> /usr/share/applications/firefox-x64.desktop

# Firefox x86 Centos7 
RUN echo -e "\
[Desktop Entry]\n\
Name=Firefox x86 Centos7\n\
Exec=sh -c 'source /home/user/.bashrc;eval centos7-x86 firefox'\n\
Icon=firefox\n\
Terminal=true\n\
Type=Application\n\
Categories=Network;WebBrowser;"\
>> /usr/share/applications/firefox-x86-centos7.desktop

# Eclipse x86
RUN echo -e "\
[Desktop Entry]\n\
Name=Eclipse\n\
Exec=eclipse\n\
Icon=/usr/eclipse/icon.xpm\n\
Categories=Application;Development;Java;IDE\n\
Type=Application\n\
Terminal=false"\
>> /usr/share/applications/eclipse.desktop && \
    cp /usr/share/applications/eclipse.desktop \
    /home/user/Desktop/eclipse.desktop && \
    chown user:user /home/user/Desktop/eclipse.desktop

# Eclipse x64
RUN echo -e "\
[Desktop Entry]\n\
Name=Eclipse x64\n\
Exec=sh -c 'source /home/user/.bashrc;eval workstation-x64 eclipse'\n\
Icon=/usr/eclipse/icon.xpm\n\
Categories=Application;Development;Java;IDE\n\
Type=Application\n\
Terminal=true"\
>> /usr/share/applications/eclipse-x64.desktop

# Eclipse x86 Centos7
RUN echo -e "\
[Desktop Entry]\n\
Name=Eclipse x86 Centos7\n\
Exec=sh -c 'source /home/user/.bashrc;eval centos7-x86 eclipse'\n\
Icon=/usr/eclipse/icon.xpm\n\
Categories=Application;Development;Java;IDE\n\
Type=Application\n\
Terminal=true"\
>> /usr/share/applications/eclipse-x86-centos7.desktop

# Default user
USER user

# Persist data volume
VOLUME ["/home/user/Public"]
