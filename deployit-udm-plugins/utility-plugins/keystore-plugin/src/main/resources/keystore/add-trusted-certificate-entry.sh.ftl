<#if deployed.certificate??>
echo "Querying whether the certificate ${deployed.name} is installed on host"
${deployed.container.jvmPath}/bin/keytool -list -keystore ${deployed.container.keystore} -alias ${deployed.alias} -storepass ${deployed.container.passphrase} &> /dev/null
res=$?
if [ $res == 0 ] ; then
	echo "Certificate is already installed"
	exit 1000
fi
echo "Adding certificate ${deployed.name} to ${deployed.container.keystore} under alias ${deployed.alias}"

${deployed.container.jvmPath}/bin/keytool -importcert -alias ${deployed.alias} -keystore ${deployed.container.keystore} -storepass ${deployed.container.passphrase} -file certificate.pem -noprompt
<#else>
echo "Empty certificate for ${deployed.name}, the keystore will not be modified"
</#if>