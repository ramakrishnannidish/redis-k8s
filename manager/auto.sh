
aws eks list-clusters


aws eks update-kubeconfig --name $CLUSTER1_NAME

kubectl get nodes -o json | jq -r '.items[] | select(.spec.taints == null) | .metadata.name' >CLUSTER1_NODES
CLUSTER1_NODE1_NAME=$(sed -n 1p  CLUSTER1_NODES)
CLUSTER1_NODE2_NAME=$(sed -n 2p  CLUSTER1_NODES)
CLUSTER1_NODE3_NAME=$(sed -n 3p  CLUSTER1_NODES)




echo "INFO: ELECTED NODES ARE $CLUSTER1_NODE1_NAME  $CLUSTER1_NODE2_NAME  $CLUSTER1_NODE3_NAME"

# exit
#remove exist lbl
kubectl label nodes $CLUSTER1_NODE1_NAME $CLUSTER1_NODE2_NAME $CLUSTER1_NODE3_NAME redis- 

kubectl label no $CLUSTER1_NODE1_NAME redis=cluster1.node1.$CLUSTER_ID
kubectl get no --selector redis=cluster1.node1.$CLUSTER_ID -o wide --no-headers=true 
sleep 1
kubectl label nodes $CLUSTER1_NODE2_NAME redis=cluster1.node2.$CLUSTER_ID
kubectl get no --selector redis=cluster1.node2.$CLUSTER_ID -o wide --no-headers=true 
sleep 1
kubectl label nodes $CLUSTER1_NODE3_NAME redis=cluster1.node3.$CLUSTER_ID
kubectl get no --selector redis=cluster1.node3.$CLUSTER_ID -o wide --no-headers=true 


CLUSTER1_NODE1_IP=$(kubectl get no --selector redis=cluster1.node1.$CLUSTER_ID -o wide --no-headers=true|awk '{print $6}')
CLUSTER1_NODE2_IP=$(kubectl get no --selector redis=cluster1.node2.$CLUSTER_ID -o wide --no-headers=true|awk '{print $6}')
CLUSTER1_NODE3_IP=$(kubectl get no --selector redis=cluster1.node3.$CLUSTER_ID -o wide --no-headers=true|awk '{print $6}')

#end cluster1 config 
aws eks update-kubeconfig --name $CLUSTER2_NAME
kubectl get nodes -o json | jq -r '.items[] | select(.spec.taints == null) | .metadata.name' >CLUSTER2_NODES
CLUSTER2_NODE1_NAME=$(sed -n 1p  CLUSTER2_NODES)
CLUSTER2_NODE2_NAME=$(sed -n 2p  CLUSTER2_NODES)
CLUSTER2_NODE3_NAME=$(sed -n 3p  CLUSTER2_NODES)

echo "INFO: ELECTED NODES ARE $CLUSTER2_NODE1_NAME  $CLUSTER2_NODE2_NAME  $CLUSTER2_NODE3_NAME"
kubectl label nodes $CLUSTER2_NODE1_NAME $CLUSTER2_NODE2_NAME $CLUSTER2_NODE3_NAME redis- 

kubectl label no $CLUSTER2_NODE1_NAME redis=cluster2.node1.$CLUSTER_ID
kubectl get no --selector redis=cluster2.node1.$CLUSTER_ID -o wide --no-headers=true 
sleep 1
kubectl label nodes $CLUSTER2_NODE2_NAME redis=cluster2.node2.$CLUSTER_ID
kubectl get no --selector redis=cluster2.node2.$CLUSTER_ID -o wide --no-headers=true 
sleep 1
kubectl label nodes $CLUSTER2_NODE3_NAME redis=cluster2.node3.$CLUSTER_ID
kubectl get no --selector redis=cluster2.node3.$CLUSTER_ID -o wide --no-headers=true 

CLUSTER2_NODE1_IP=$(kubectl get no --selector redis=cluster2.node1.$CLUSTER_ID -o wide --no-headers=true|awk '{print $6}')
CLUSTER2_NODE2_IP=$(kubectl get no --selector redis=cluster2.node2.$CLUSTER_ID -o wide --no-headers=true|awk '{print $6}')
CLUSTER2_NODE3_IP=$(kubectl get no --selector redis=cluster2.node3.$CLUSTER_ID -o wide --no-headers=true|awk '{print $6}')


REDIS_NODES="$CLUSTER1_NODE1_IP $CLUSTER1_NODE2_IP $CLUSTER1_NODE3_IP $CLUSTER2_NODE1_IP $CLUSTER2_NODE2_IP $CLUSTER2_NODE3_IP"
echo $REDIS_NODES
aws eks update-kubeconfig --name $CLUSTER1_NAME
cat cluster1/redis-cluster1.yaml|sed "s/<NODESIP>/$REDIS_NODES/g" |sed "s/<CLUSTER_ID>/$CLUSTER_ID/g"| sed "s/<REDIS_PASSWORD>/$CLUSTER_PASS/g"|kubectl apply -f -
kubectl apply -f cluster1/service.yaml
sleep 10
LB_CLUSTER1_REDIS1=$(kubectl get svc redis-1-cluster1 --no-headers=true|awk '{print $4}')
LB_CLUSTER1_REDIS2=$(kubectl get svc redis-2-cluster1 --no-headers=true|awk '{print $4}')
LB_CLUSTER1_REDIS3=$(kubectl get svc redis-3-cluster1 --no-headers=true|awk '{print $4}')
echo addr: $LB_CLUSTER1_REDIS1 $LB_CLUSTER1_REDIS2 $LB_CLUSTER1_REDIS3
aws eks update-kubeconfig --name $CLUSTER2_NAME
cat cluster2/redis-cluster2.yaml|sed "s/<NODESIP>/$REDIS_NODES/g" |sed "s/<CLUSTER_ID>/$CLUSTER_ID/g"| sed "s/<REDIS_PASSWORD>/$CLUSTER_PASS/g"|kubectl apply -f -
kubectl apply -f cluster2/service.yaml
sleep 10
LB_CLUSTER2_REDIS1=$(kubectl get svc redis-1-cluster2 --no-headers=true|awk '{print $4}')
LB_CLUSTER2_REDIS2=$(kubectl get svc redis-2-cluster2 --no-headers=true|awk '{print $4}')
LB_CLUSTER2_REDIS3=$(kubectl get svc redis-3-cluster2 --no-headers=true|awk '{print $4}')
echo addr: $LB_CLUSTER1_REDIS1 $LB_CLUSTER1_REDIS2 $LB_CLUSTER1_REDIS3
function update_dns(){
    #cluster1
    DNS_C1_R1="redis1.cluster1.${CLUSTER_ID}"
    echo "UPDATEING DNS RECORD redis1.cluster1.${CLUSTER_ID}.404ops.in"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
       -H "Authorization: Bearer $CF_API_KEY" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"CNAME\",\"name\":\"$DNS_C1_R1\",\"content\":\"$LB_CLUSTER1_REDIS1\",\"ttl\":120,\"proxied\":false}"

    DNS_C1_R2="redis2.cluster1.${CLUSTER_ID}"
    echo "UPDATEING DNS RECORD redis2.cluster1.${CLUSTER_ID}.404ops.in"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
       -H "Authorization: Bearer $CF_API_KEY" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"CNAME\",\"name\":\"$DNS_C1_R2\",\"content\":\"$LB_CLUSTER1_REDIS2\",\"ttl\":120,\"proxied\":false}"

    DNS_C1_R3="redis3.cluster1.${CLUSTER_ID}"
    echo "UPDATEING DNS RECORD redis3.cluster1.${CLUSTER_ID}.404ops.in"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
       -H "Authorization: Bearer $CF_API_KEY" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"CNAME\",\"name\":\"$DNS_C1_R3\",\"content\":\"$LB_CLUSTER1_REDIS3\",\"ttl\":120,\"proxied\":false}"

#cluster2
    DNS_C2_R1="redis1.cluster2.${CLUSTER_ID}"
    echo "UPDATEING DNS RECORD redis1.cluster2.${CLUSTER_ID}.404ops.in"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
       -H "Authorization: Bearer $CF_API_KEY" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"CNAME\",\"name\":\"$DNS_C2_R1\",\"content\":\"$LB_CLUSTER2_REDIS1\",\"ttl\":120,\"proxied\":false}"

    DNS_C2_R2="redis2.cluster2.${CLUSTER_ID}"
    echo "UPDATEING DNS RECORD redis2.cluster2.${CLUSTER_ID}.404ops.in"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
       -H "Authorization: Bearer $CF_API_KEY" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"CNAME\",\"name\":\"$DNS_C2_R2\",\"content\":\"$LB_CLUSTER2_REDIS2\",\"ttl\":120,\"proxied\":false}"

    DNS_C2_R3="redis3.cluster2.${CLUSTER_ID}"
    echo "UPDATEING DNS RECORD redis3.cluster2.${CLUSTER_ID}.404ops.in"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
       -H "Authorization: Bearer $CF_API_KEY" \
       -H "Content-Type: application/json" \
       --data "{\"type\":\"CNAME\",\"name\":\"$DNS_C2_R3\",\"content\":\"$LB_CLUSTER2_REDIS3\",\"ttl\":120,\"proxied\":false}"
}
update_dns

aws ec2 authorize-security-group-ingress \
    --group-id $(aws eks describe-cluster --name $CLUSTER1_NAME |jq -r ".cluster.resourcesVpcConfig.clusterSecurityGroupId") \
    --protocol tcp \
    --port 0-65535 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-id $(aws eks describe-cluster --name $CLUSTER2_NAME |jq -r ".cluster.resourcesVpcConfig.clusterSecurityGroupId") \
    --protocol tcp \
    --port 0-65535 \
    --cidr 0.0.0.0/0

# redis-cli --cluster create $(echo $REDIS_NODES |awk '{print $1 ":6379"}') $(echo $REDIS_NODES |awk '{print $2 ":6379"}') $(echo $REDIS_NODES |awk '{print $3 ":6379"}') $(echo $REDIS_NODES |awk '{print $4 ":6379"}') $(echo $REDIS_NODES |awk '{print $5 ":6379"}') $(echo $REDIS_NODES |awk '{print $6 ":6379"}') -a "$REDIS_PASSWORD"