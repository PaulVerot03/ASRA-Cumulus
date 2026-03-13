Commande sur tous les switch:
net add bridge bridge ports swp1,swp2,swp3
net commit


Pour forcer le vielle version stp(tous les switch):
sudo mstpctl setforcevers bridge stp

Pour voir les ports:
net show bridge spanning-tree

TEST Ping :
ping 192.168.0.2

On coupe le lien sur switch 1:
sudo ip link set swp2 down

On observe le ping et les séquences icmp 

Pour rebrancher:
sudo ip link set swp2 up

Pour passer en RSTP:
sudo mstpctl setforcevers bridge rstp

Test Ping:
ping 192.168.0.2

On coupe le lien sur switch 1:
sudo ip link set swp2 down

On observe le pinn et les séquences icmp

Pour rebrancher:
sudo ip link set swp2 up
