#!/bin/bash
wget -O splunk.tgz https://download.splunk.com/products/splunk/releases/9.1.2/linux/splunk-9.1.2-a7f645ddaf91-Linux-x86_64.tgz
tar -xvzf splunk.tgz -C /opt
useradd splunk
chown -R splunk:splunk /opt/splunk
/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt
/opt/splunk/bin/splunk enable boot-start
