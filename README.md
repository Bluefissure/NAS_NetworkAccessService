# NAS_NetworkAccessService

Network access service lab of Computer Network Design in SDU 2016

##Intro:

* Implemented via iptables

* Only tested in Ubuntu 16.04 

* If you have any problems, feel free to raise an issue or just push it to this project.


##Require:

* Hardware:

    * Ubuntu has two network adapters, one for external network, the other for inner network


* Software:

    * dhcp
    * apache
    * iptables
    
    
* The shell `nas.sh` will automatically download software needed, please do not install in advance.

##Usage:


* Enter the shell command below:
    
    `wget https://raw.githubusercontent.com/Bluefissure/NAS_NetworkAccessService/master/nas.sh && chmod +x nas.sh && sudo ./nas.sh`

* You can also clone this project to your directory and run nas.sh 

* Modify the authinfo in `/etc/nasuser.list`(store without encypt now) to update userinfo

* Update `/usr/lib/cgi-bin/checkin.cgi` if you need to modify authorization logic

##Author:

* Bluefissure(ZYP), LMY
