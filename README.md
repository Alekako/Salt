Scan Network for find salt-minion on the servers

Change the next lines for your customization: 14, 32, 36, 44, 65

Description

The script scans the networks searching all the servers responding on port 22 it could be servers like Hypervisors, ILOs... without Saltstack (because their function didn't need it), these excluded IPs (servers) are filtered with a file (CheckSaltMinion_noCheckHosts.txt).
On the other hand the script can be modified deleting this exclusion and only search the salt-minion agent on the servers where the user Rundeck has access.
 
Also the script performs a query to salt-master for search all the salt-minion agents, here includes Amazon servers and others on different rank of IPs.
 
All the results are customized on different files (included on mail):
"date".serversOK."NumberServers"  --> Servers scanned with salt-minion agent started
"date".serversNOK."NumberServers" --> Servers scanned without salt-minion agent installed/started
"date".SaltMaster."NumberServers" --> Servers with salt-minion agent started
"date".Amazon."NumberServers"     --> Amazon servers with salt-minion agent started
"date".ExcludedOK                 --> Servers with salt-minion started according salt-master but didn't scanned or other cause which does not match
