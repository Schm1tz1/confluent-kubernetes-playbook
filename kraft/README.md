# CFK Deployment with KRaft
(Original source: Nadine Capelle)

Notes:
- Everything is working fine, I have sent a deployment file for a 'large' cluster (3 kraft / 3 brokers)
- This is leveraging the ldap helm deployment in the examples. Let me know if you need some help to deploy it
- Yes definitely working. The only thing you need to be aware of is the set the default replication factor and min insync replica in the kraftcontroller

