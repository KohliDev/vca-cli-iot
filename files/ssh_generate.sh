#!/bin/bash
if ! sudo apt-get install -y ssh; then
	echo 'apt-get failed.'
	exit 1 fi if ! jq --version; then
	if ! sudo apt-get install -y jq; then
		echo 'apt-get failed.'
		exit 1
	fi fi if ! test -d ~/.ssh; then
	mkdir -p ~/.ssh fi if ! test -e ~/.ssh/id_rsa.pub; then
	ssh-keygen -N '' -t rsa -f ~/.ssh/id_rsa > /dev/null fi
#create the transfer script.
cat > ./transfer_script.sh << EOL
#!/bin/bash
if [ x\$1=x"precustomization" ]; then mkdir -p /root/.ssh << EOL echo -n "echo '" >> ./transfer_script.sh cat ~/.ssh/id_rsa.pub | tr -d '\n' >> ./transfer_script.sh
#remove the extra line sed -i.bak '$ d' ./transfer_script.sh
echo "' >> /root/.ssh/authorized_keys" >> ./transfer_script.sh cat >> ./transfer_script.sh << EOL
#chown ubuntu.ubuntu /root/.ssh chown ubuntu.ubuntu /root/.ssh/authorized_keys
chmod go-rwx /root/.ssh chmod go-rwx /root/.ssh/authorized_keys fi << EOL
