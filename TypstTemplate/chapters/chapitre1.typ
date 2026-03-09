#import "../classic-evry-report/template/setup/macros.typ": *

= Partage Réseau NFS


```yaml
---
- name: machine1
 hosts: debian1
 tasks:
   - name: vérif paquet
     apt:
       name: nfs-common ifenslave tcpdump
       state: present
       update_cache: yes
       force_apt_get: yes
       autoclean: yes
       autoremove: yes
   - name: set ip
     copy: 
dest: /etc/network/interfaces.d 
content: | 
  auto ens33 
  iface ens33 inet static 
    address 192.168.20.3 
    gateway 192.168.20.1
```

```yaml
---
- name: machine2
 hosts: debian2
 tasks:
   - name: vérif paquet
     apt:
       name: nfs-common ifenslave tcpdump
       state: present
       update_cache: yes
       force_apt_get: yes
       autoclean: yes
       autoremove: yes
   - name: set ip
     copy: 
dest: /etc/network/interfaces.d 
content: | 
  auto ens33 
  iface ens33 inet static 
    address 192.168.30.3 
    gateway 192.168.30.1
```